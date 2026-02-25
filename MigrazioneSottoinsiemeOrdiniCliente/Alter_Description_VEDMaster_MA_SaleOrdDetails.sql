USE [VEDMaster];
GO

SET NOCOUNT ON;

DECLARE @table sysname = N'MA_SaleOrdDetails';
DECLARE @column sysname = N'Description';
DECLARE @schema sysname;
DECLARE @type sysname;
DECLARE @is_nullable bit;
DECLARE @maxlen_bytes int;
DECLARE @current_len_chars int;
DECLARE @target_len_chars int = 280; -- nuova dimensione desiderata
DECLARE @target_type nvarchar(20);
DECLARE @nullability nvarchar(8);
DECLARE @sql nvarchar(max);

-- Trova colonna e metadati
SELECT
  @schema = s.name,
  @type = ty.name,
  @is_nullable = c.is_nullable,
  @maxlen_bytes = c.max_length
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = @table AND c.name = @column;

IF @schema IS NULL
BEGIN
  RAISERROR('Colonna %s.%s non trovata.',16,1,@table,@column);
  RETURN;
END

-- Calcola lunghezza attuale in caratteri
IF @type IN (N'nvarchar', N'nchar')
  SET @current_len_chars = CASE WHEN @maxlen_bytes = -1 THEN -1 ELSE @maxlen_bytes/2 END;
ELSE
  SET @current_len_chars = @maxlen_bytes;

IF @type NOT IN (N'varchar', N'nvarchar')
BEGIN
  RAISERROR('Tipo colonna non supportato: %s. Previsti varchar/nvarchar.',16,1,@type);
  RETURN;
END

IF @current_len_chars IS NULL
BEGIN
  RAISERROR('Impossibile determinare la lunghezza attuale.',16,1);
  RETURN;
END

-- Se è già abbastanza grande, non fare nulla
IF @current_len_chars >= @target_len_chars OR @current_len_chars = -1
BEGIN
  PRINT 'Nessuna modifica necessaria: lunghezza attuale = ' + CAST(@current_len_chars AS nvarchar(10));
  RETURN;
END

SET @target_type = CASE WHEN @type = N'nvarchar' THEN N'nvarchar' ELSE N'varchar' END;
SET @nullability = CASE WHEN @is_nullable = 1 THEN N'NULL' ELSE N'NOT NULL' END;

SET @sql = N'ALTER TABLE ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) +
           N' ALTER COLUMN ' + QUOTENAME(@column) + N' ' + @target_type + N'(' + CAST(@target_len_chars AS nvarchar(10)) + N') ' + @nullability + N';';

PRINT N'Eseguo: ' + @sql;
BEGIN TRY
  EXEC sp_executesql @sql;
  PRINT N'Colonna modificata con successo a ' + CAST(@target_len_chars AS nvarchar(10));
END TRY
BEGIN CATCH
  DECLARE @msg nvarchar(4000) = ERROR_MESSAGE();
  RAISERROR('Errore durante ALTER COLUMN: %s',16,1,@msg);
END CATCH
