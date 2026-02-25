-- Aumenta la dimensione delle colonne a rischio troncamento in VEDMaster per MA_SuppQuotas*
-- Questo script calcola automaticamente la lunghezza massima dai DB sorgenti e applica l'ALTER sul VEDMaster.
-- Data: 2025-09-12

SET NOCOUNT ON;

-- Parametri della correzione (attualmente solo la coppia Tabella/Colonna individuata nel report)
DECLARE @TableName sysname = N'MA_SuppQuotasDetail';
DECLARE @ColumnName sysname = N'Description';

-- Recupera la lunghezza massima tra i sorgenti
DECLARE @LenSrc INT;
SELECT @LenSrc = MAX(CHARACTER_MAXIMUM_LENGTH)
FROM (
    SELECT CHARACTER_MAXIMUM_LENGTH FROM gpxnetclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
    UNION ALL
    SELECT CHARACTER_MAXIMUM_LENGTH FROM furmanetclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
    UNION ALL
    SELECT CHARACTER_MAXIMUM_LENGTH FROM vedbondifeclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
) AS S;

-- Recupera info attuali sul VEDMaster
DECLARE @DataType NVARCHAR(128), @IsNullable NVARCHAR(3), @LenDest INT;
SELECT 
    @DataType = DATA_TYPE,
    @IsNullable = IS_NULLABLE,
    @LenDest   = CHARACTER_MAXIMUM_LENGTH
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName;

PRINT 'Colonna: ' + @TableName + '.' + @ColumnName;
PRINT 'Sorgenti: lunghezza max = ' + COALESCE(CONVERT(varchar(10),@LenSrc),'NULL');
PRINT 'Destinazione attuale: tipo=' + COALESCE(@DataType,'?') + ', len=' + COALESCE(CONVERT(varchar(10),@LenDest),'NULL') + ', nullability=' + COALESCE(@IsNullable,'?');

IF @LenSrc IS NULL
BEGIN
    PRINT 'Nessuna informazione di lunghezza trovata nei sorgenti. Nessuna modifica.';
    GOTO Verify;
END

-- Verifica tipo dati compatibile
IF @DataType NOT IN ('varchar','nvarchar','char','nchar')
BEGIN
    PRINT 'Tipo dati non compatibile per modifica lunghezza: ' + COALESCE(@DataType,'?') + '. Nessuna modifica.';
    GOTO Verify;
END

-- Se già abbastanza grande, non fare nulla
IF @LenDest IS NOT NULL AND @LenDest >= @LenSrc AND @LenSrc <> -1
BEGIN
    PRINT 'La colonna ha già una lunghezza >= dei sorgenti. Nessuna modifica necessaria.';
    GOTO Verify;
END

DECLARE @LenForQuery NVARCHAR(10) = CASE WHEN @LenSrc = -1 THEN 'MAX' ELSE CONVERT(NVARCHAR(10), @LenSrc) END;
DECLARE @Nullability NVARCHAR(8) = CASE WHEN @IsNullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END;

DECLARE @Sql NVARCHAR(MAX) = N'ALTER TABLE VEDMaster.dbo.' + QUOTENAME(@TableName) +
    N' ALTER COLUMN ' + QUOTENAME(@ColumnName) + N' ' + @DataType + N'(' + @LenForQuery + N') ' + @Nullability + N';';

PRINT 'Esecuzione: ' + @Sql;
EXEC sp_executesql @Sql;
PRINT 'Modifica applicata.';

Verify:
-- Verifica finale
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName;
