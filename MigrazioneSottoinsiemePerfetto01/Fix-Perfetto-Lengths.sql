/*
Adattamento sicuro delle lunghezze colonne testuali su VEDMaster per il sottoinsieme PERFETTO01.
- Espande solo (mai riduce) le colonne VARCHAR/NVARCHAR in dbo.
- Mantiene collation e nullability attuali.
- Confronta con le colonne omonime nei DB sorgenti: gpxnetclone, furmanetclone, vedbondifeclone.
- Non cambia tipo (se nei sorgenti il tipo differisce, salta la colonna).
- Non porta automaticamente a MAX; se i sorgenti hanno MAX, viene saltato con messaggio.
*/

USE [VEDMaster];
GO

SET NOCOUNT ON;

DECLARE @SourceDBs TABLE(name sysname);
INSERT INTO @SourceDBs(name)
VALUES (N'gpxnetclone'),(N'furmanetclone'),(N'vedbondifeclone');

DECLARE @TargetTables TABLE(name sysname);
INSERT INTO @TargetTables(name)
VALUES
(N'M_JobCorrections'),
(N'IM_JobCorrectionsDetails'),
(N'IM_JobsBalance'),
(N'IM_JobsComponents'),
(N'IM_JobsCostsRevenuesSummary'),
(N'IM_JobsDetails'),
(N'IM_JobsDetailsVCL'),
(N'IM_JobsDocuments'),
(N'IM_JobsItems'),
(N'IM_JobsNumbers'),
(N'IM_JobsSections'),
(N'IM_JobsSummary'),
(N'IM_JobsSummaryByCompType'),
(N'IM_JobsSummaryByCompTypeByWorkingStep'),
(N'IM_JobsTaxSummary'),
(N'IM_JobsWithholdingTax'),
(N'IM_JobsWorkingStep'),
(N'IM_JobsNotes');

IF OBJECT_ID('tempdb..#Cols') IS NOT NULL DROP TABLE #Cols;
CREATE TABLE #Cols(
    TableName sysname,
    ColumnName sysname,
    DataType sysname,
    IsNullable bit,
    CollationName sysname NULL,
    DestCharLen int,       -- in caratteri (non byte). -1 => MAX
    IsNType bit            -- 1 per NVARCHAR, 0 per VARCHAR
);

INSERT INTO #Cols(TableName, ColumnName, DataType, IsNullable, CollationName, DestCharLen, IsNType)
SELECT t.name AS TableName,
       c.name AS ColumnName,
       ty.name AS DataType,
       c.is_nullable,
       c.collation_name,
       CASE WHEN ty.name IN (N'nvarchar', N'nchar') THEN CASE WHEN c.max_length = -1 THEN -1 ELSE c.max_length/2 END
            WHEN ty.name IN (N'varchar', N'char') THEN CASE WHEN c.max_length = -1 THEN -1 ELSE c.max_length END
            ELSE NULL END AS DestCharLen,
       CASE WHEN ty.name IN (N'nvarchar', N'nchar') THEN 1 ELSE 0 END AS IsNType
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'dbo'
  AND t.name IN (SELECT name FROM @TargetTables)
  AND ty.name IN (N'varchar', N'nvarchar')
ORDER BY t.name, c.column_id;

DECLARE @tbl sysname, @col sysname, @dtype sysname, @isNull bit, @coll sysname, @destLen int, @isN bit;
DECLARE @targetLen int, @srcLen int, @srcType sysname, @cmd nvarchar(max);
DECLARE @msg nvarchar(4000), @hasTypeMismatch bit, @allSourcesMax bit;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, ColumnName, DataType, IsNullable, CollationName, DestCharLen, IsNType
    FROM #Cols;

OPEN cur;
FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @destLen IS NULL OR @destLen = -1
    BEGIN
        PRINT N'SKIP (dest MAX o non testuale): ' + @tbl + N'.' + @col;
        FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
        CONTINUE;
    END

    SET @targetLen = @destLen;
    SET @hasTypeMismatch = 0;
    SET @allSourcesMax = 1; -- finché troviamo una sorgente non MAX, diventa 0

    DECLARE src CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM @SourceDBs;
    DECLARE @srcDb sysname;
    OPEN src;
    FETCH NEXT FROM src INTO @srcDb;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @q nvarchar(max) = N'
            SELECT @o_len = CASE WHEN ty.name IN (N''nvarchar'',N''nchar'')
                                  THEN CASE WHEN c.max_length = -1 THEN -1 ELSE c.max_length/2 END
                                  ELSE CASE WHEN c.max_length = -1 THEN -1 ELSE c.max_length END END,
                   @o_type = ty.name
            FROM ' + QUOTENAME(@srcDb) + N'.sys.columns c
            JOIN ' + QUOTENAME(@srcDb) + N'.sys.types ty ON ty.user_type_id = c.user_type_id
            JOIN ' + QUOTENAME(@srcDb) + N'.sys.tables t ON t.object_id = c.object_id
            JOIN ' + QUOTENAME(@srcDb) + N'.sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = N''dbo'' AND t.name = @i_tbl AND c.name = @i_col;';
        -- Nota: uso QUOTENAME(@srcDb) per ottenere [db] e concateno direttamente .sys.xxx

        SET @srcLen = NULL;
        SET @srcType = NULL;
        EXEC sp_executesql @q, N'@i_tbl sysname, @i_col sysname, @o_len int OUTPUT, @o_type sysname OUTPUT',
            @i_tbl=@tbl, @i_col=@col, @o_len=@srcLen OUTPUT, @o_type=@srcType OUTPUT;

        IF @srcLen IS NOT NULL
        BEGIN
            IF @srcLen <> -1 SET @allSourcesMax = 0; -- trovata misura finita
            IF @srcType IS NOT NULL AND @srcType <> @dtype SET @hasTypeMismatch = 1;
            IF @srcType = @dtype AND @srcLen IS NOT NULL AND @srcLen > @targetLen AND @srcLen <> -1
            BEGIN
                SET @targetLen = @srcLen;
            END
        END

        FETCH NEXT FROM src INTO @srcDb;
    END
    CLOSE src; DEALLOCATE src;

    IF @hasTypeMismatch = 1
    BEGIN
        PRINT N'SKIP (tipo diverso tra dest e sorgenti): ' + @tbl + N'.' + @col + N' dest=' + @dtype;
        FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
        CONTINUE;
    END

    IF @targetLen <= @destLen
    BEGIN
        PRINT N'OK (nessuna espansione necessaria): ' + @tbl + N'.' + @col + N' = ' + CAST(@destLen AS nvarchar(20));
        FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
        CONTINUE;
    END

    IF @allSourcesMax = 1
    BEGIN
        PRINT N'SKIP (sorgenti solo MAX, non imposto MAX automaticamente): ' + @tbl + N'.' + @col;
        FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
        CONTINUE;
    END

    -- Limiti massimi SQL Server
    IF (@isN = 1 AND @targetLen > 4000) SET @targetLen = 4000;
    IF (@isN = 0 AND @targetLen > 8000) SET @targetLen = 8000;

    DECLARE @nullSql nvarchar(20) = CASE WHEN @isNull = 1 THEN N' NULL' ELSE N' NOT NULL' END;
    DECLARE @collSql nvarchar(400) = CASE WHEN @coll IS NOT NULL THEN N' COLLATE ' + @coll ELSE N'' END;

    SET @cmd = N'ALTER TABLE dbo.' + QUOTENAME(@tbl) + N' ALTER COLUMN ' + QUOTENAME(@col) + N' ' + UPPER(@dtype) + N'(' + CAST(@targetLen AS nvarchar(10)) + N')' + @collSql + @nullSql + N';';

    BEGIN TRY
        PRINT @cmd;
        EXEC sp_executesql @cmd;
    END TRY
    BEGIN CATCH
        SET @msg = N'ERRORE su ' + @tbl + N'.' + @col + N' -> ' + ERROR_MESSAGE();
        PRINT @msg;
    END CATCH;

    FETCH NEXT FROM cur INTO @tbl, @col, @dtype, @isNull, @coll, @destLen, @isN;
END
CLOSE cur; DEALLOCATE cur;

PRINT N'Completato adattamento lunghezze (solo espansioni).';
GO
