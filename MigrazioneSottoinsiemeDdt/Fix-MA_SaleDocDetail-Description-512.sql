-- Aggiorna la lunghezza di VEDMaster.dbo.MA_SaleDocDetail.Description a 512 caratteri
-- Compatibile con SQL Server 2008
-- Data: 2025-09-16

SET NOCOUNT ON;

DECLARE @TableName sysname = N'MA_SaleDocDetail';
DECLARE @ColumnName sysname = N'Description';
DECLARE @TargetLen int = 512;

DECLARE @DataType sysname,
        @IsNullable nvarchar(3),
        @LenDest int,
        @Collation sysname;

SELECT 
    @DataType = DATA_TYPE,
    @IsNullable = IS_NULLABLE,
    @LenDest   = CHARACTER_MAXIMUM_LENGTH,
    @Collation = COLLATION_NAME
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName;

PRINT 'Colonna: ' + @TableName + '.' + @ColumnName;
PRINT 'Destinazione attuale: tipo=' + COALESCE(@DataType,'?')
    + ', len=' + COALESCE(CONVERT(varchar(10),@LenDest),'NULL')
    + ', nullability=' + COALESCE(@IsNullable,'?')
    + ', collation=' + COALESCE(@Collation,'<DB default>');

IF @DataType IS NULL
BEGIN
    RAISERROR('Colonna non trovata in VEDMaster: %s.%s', 16, 1, @TableName, @ColumnName);
    RETURN;
END

IF @DataType NOT IN ('varchar','nvarchar','char','nchar')
BEGIN
    RAISERROR('Tipo dati non supportato per modifica lunghezza: %s', 16, 1, @DataType);
    RETURN;
END

IF (@LenDest = @TargetLen)
BEGIN
    PRINT 'Nessuna modifica: la colonna ha già lunghezza ' + CONVERT(varchar(10), @TargetLen) + '.';
    GOTO Verify;
END

-- Evita riduzioni automatiche (rischio perdita dati)
IF (@LenDest IS NOT NULL AND (@LenDest = -1 OR @LenDest > @TargetLen))
BEGIN
    PRINT 'ATTENZIONE: lunghezza attuale (' + CONVERT(varchar(10),@LenDest) + ') > target (' + CONVERT(varchar(10),@TargetLen) + ').'
        + ' Non si procede alla riduzione automatica.';
    GOTO Verify;
END

-- Aumento/adeguamento lunghezza
DECLARE @Nullability nvarchar(8) = CASE WHEN @IsNullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END;
DECLARE @Sql nvarchar(MAX) = N'ALTER TABLE VEDMaster.dbo.' + QUOTENAME(@TableName)
    + N' ALTER COLUMN ' + QUOTENAME(@ColumnName)
    + N' ' + @DataType + N'(' + CONVERT(nvarchar(10), @TargetLen) + N') '
    + CASE WHEN @Collation IS NOT NULL THEN N'COLLATE ' + @Collation + N' ' ELSE N'' END
    + @Nullability + N';';

PRINT 'Esecuzione: ' + @Sql;
EXEC sp_executesql @Sql;
PRINT 'Modifica applicata.';

Verify:
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLLATION_NAME
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @ColumnName;
