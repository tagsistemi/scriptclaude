/*
  Allinea le lunghezze colonne su VEDMaster:
  - IM_JobQuotasDetails.Description -> NVARCHAR(256)
  - IM_JobQuotasDetails.ShortDescription -> NVARCHAR(250)
  - IM_WPRDetails.Description -> NVARCHAR(256)
  Il codice mantiene la nullability corrente delle colonne e valida i dati prima della modifica.
  Nota: gestisce vincoli di default dipendenti (drop e recreate) per SQL Server 2008.
*/

SET XACT_ABORT ON;
GO

USE [VEDMaster];
GO

BEGIN TRAN;

-- Pre-check: verifica che i dati rientrino nelle nuove lunghezze richieste
IF EXISTS (SELECT 1 FROM dbo.IM_JobQuotasDetails WHERE LEN(ISNULL(Description, N'')) > 256)
BEGIN
    RAISERROR('IM_JobQuotasDetails.Description contiene valori oltre 256 caratteri. Correggere/troncare prima di eseguire lo script.', 16, 1);
    ROLLBACK TRAN; RETURN;
END

IF EXISTS (SELECT 1 FROM dbo.IM_JobQuotasDetails WHERE LEN(ISNULL(ShortDescription, N'')) > 250)
BEGIN
    RAISERROR('IM_JobQuotasDetails.ShortDescription contiene valori oltre 250 caratteri. Correggere/troncare prima di eseguire lo script.', 16, 1);
    ROLLBACK TRAN; RETURN;
END

IF EXISTS (SELECT 1 FROM dbo.IM_WPRDetails WHERE LEN(ISNULL(Description, N'')) > 256)
BEGIN
    RAISERROR('IM_WPRDetails.Description contiene valori oltre 256 caratteri. Correggere/troncare prima di eseguire lo script.', 16, 1);
    ROLLBACK TRAN; RETURN;
END

-- Helper inline per: drop default constraint -> alter -> recreate default
-- IM_JobQuotasDetails.ShortDescription -> NVARCHAR(250)
DECLARE @tbl sysname, @col sysname, @newType nvarchar(100);
DECLARE @nullable bit, @dfName sysname, @dfDefinition nvarchar(max), @sql nvarchar(max);

SET @tbl = N'dbo.IM_JobQuotasDetails';
SET @col = N'ShortDescription';
SET @newType = N'NVARCHAR(250)';

SELECT @nullable = c.is_nullable,
       @dfName = dc.name,
       @dfDefinition = dc.definition
FROM sys.columns AS c
LEFT JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
WHERE c.object_id = OBJECT_ID(@tbl) AND c.name = @col;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' DROP CONSTRAINT [' + @dfName + N']');

SET @sql = N'ALTER TABLE ' + @tbl + N' ALTER COLUMN [' + @col + N'] ' + @newType + N' ' + CASE WHEN @nullable = 1 THEN N'NULL' ELSE N'NOT NULL' END + N';';
EXEC sp_executesql @sql;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' ADD CONSTRAINT [' + @dfName + N'] DEFAULT ' + @dfDefinition + N' FOR [' + @col + N'];');

-- IM_JobQuotasDetails.Description -> NVARCHAR(256)
SET @tbl = N'dbo.IM_JobQuotasDetails';
SET @col = N'Description';
SET @newType = N'NVARCHAR(256)';

SELECT @nullable = c.is_nullable,
       @dfName = dc.name,
       @dfDefinition = dc.definition
FROM sys.columns AS c
LEFT JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
WHERE c.object_id = OBJECT_ID(@tbl) AND c.name = @col;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' DROP CONSTRAINT [' + @dfName + N']');

SET @sql = N'ALTER TABLE ' + @tbl + N' ALTER COLUMN [' + @col + N'] ' + @newType + N' ' + CASE WHEN @nullable = 1 THEN N'NULL' ELSE N'NOT NULL' END + N';';
EXEC sp_executesql @sql;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' ADD CONSTRAINT [' + @dfName + N'] DEFAULT ' + @dfDefinition + N' FOR [' + @col + N'];');

-- IM_WPRDetails.Description -> NVARCHAR(256)
SET @tbl = N'dbo.IM_WPRDetails';
SET @col = N'Description';
SET @newType = N'NVARCHAR(256)';

SELECT @nullable = c.is_nullable,
       @dfName = dc.name,
       @dfDefinition = dc.definition
FROM sys.columns AS c
LEFT JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
WHERE c.object_id = OBJECT_ID(@tbl) AND c.name = @col;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' DROP CONSTRAINT [' + @dfName + N']');

SET @sql = N'ALTER TABLE ' + @tbl + N' ALTER COLUMN [' + @col + N'] ' + @newType + N' ' + CASE WHEN @nullable = 1 THEN N'NULL' ELSE N'NOT NULL' END + N';';
EXEC sp_executesql @sql;

IF @dfName IS NOT NULL EXEC (N'ALTER TABLE ' + @tbl + N' ADD CONSTRAINT [' + @dfName + N'] DEFAULT ' + @dfDefinition + N' FOR [' + @col + N'];');

COMMIT TRAN;
GO

-- Verifica post-modifica
SELECT 
    'IM_JobQuotasDetails.Description' AS ColumnRef,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes,
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name = 'IM_JobQuotasDetails' AND c.name IN ('Description','ShortDescription')
UNION ALL
SELECT 
    'IM_WPRDetails.Description', t.name, c.name, ty.name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name = 'IM_WPRDetails' AND c.name = 'Description';
GO
