/*
Template fix lunghezze per sottoinsieme Commesse (MA_JobGroups, MA_Jobs, MA_JobsBalances, MA_JobsParameters)
- Adattare le ALTER COLUMN emerse dal report di analisi.
- Mantiene collation e nullability correnti.
- Evita riduzioni pericolose o passaggi da MAX a misura fissa.
*/

USE [VEDMaster];
GO

SET NOCOUNT ON;

-- Esempio: porta MA_Jobs.Description a VARCHAR(280)
-- Verifiche di sicurezza
IF EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.[object_id] = OBJECT_ID('dbo.MA_Jobs')
      AND c.[name] = 'Description'
      AND t.[name] IN ('varchar','nvarchar')
)
BEGIN
    DECLARE @collation sysname = (SELECT collation_name FROM sys.columns WHERE [object_id]=OBJECT_ID('dbo.MA_Jobs') AND [name]='Description');
    DECLARE @isNullable bit = (SELECT is_nullable FROM sys.columns WHERE [object_id]=OBJECT_ID('dbo.MA_Jobs') AND [name]='Description');
    DECLARE @nullSql nvarchar(50) = CASE WHEN @isNullable=1 THEN N' NULL' ELSE N' NOT NULL' END;

    -- Evita riduzioni: consenti solo se la lunghezza attuale <= 280 o è NULL (non testuale)
    DECLARE @currentLen int = (
        SELECT CASE WHEN max_length IN (-1,0) THEN -1 ELSE max_length END
        FROM sys.columns WHERE [object_id]=OBJECT_ID('dbo.MA_Jobs') AND [name]='Description'
    );

    IF (@currentLen IS NULL OR @currentLen <= 280) AND @collation IS NOT NULL
    BEGIN
        DECLARE @sql nvarchar(max) = N'ALTER TABLE dbo.MA_Jobs ALTER COLUMN [Description] VARCHAR(280) COLLATE ' + QUOTENAME(@collation) + @nullSql + N';';
        PRINT @sql;
        EXEC sp_executesql @sql;
    END
    ELSE
    BEGIN
        PRINT 'SKIP: Riduzione potenzialmente pericolosa o collation nulla.';
    END
END
GO
