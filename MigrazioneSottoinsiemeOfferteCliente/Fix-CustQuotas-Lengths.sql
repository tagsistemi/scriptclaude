-- Aumenta la dimensione delle colonne a rischio troncamento in VEDMaster per MA_CustQuotas*
-- Caso dal report: MA_CustQuotasDetail.Description (VEDMaster 128 vs sorgenti 280)
-- Data: 2025-09-12

SET NOCOUNT ON;

DECLARE @TableName sysname = N'MA_CustQuotasDetail';
DECLARE @ColumnName sysname = N'Description';

-- Max lunghezza tra i DB sorgenti
DECLARE @LenSrc INT;
SELECT @LenSrc = MAX(CHARACTER_MAXIMUM_LENGTH)
FROM (
    SELECT CHARACTER_MAXIMUM_LENGTH FROM gpxnetclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
    UNION ALL
    SELECT CHARACTER_MAXIMUM_LENGTH FROM furmanetclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
    UNION ALL
    SELECT CHARACTER_MAXIMUM_LENGTH FROM vedbondifeclone.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName
) S;

-- Info attuali su VEDMaster
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

IF @DataType NOT IN ('varchar','nvarchar','char','nchar')
BEGIN
    PRINT 'Tipo dati non compatibile per modifica lunghezza: ' + COALESCE(@DataType,'?') + '. Nessuna modifica.';
    GOTO Verify;
END

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
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName;
