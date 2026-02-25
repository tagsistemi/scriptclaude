-- Script per aumentare la dimensione del campo Description nella tabella MA_PurchaseOrdDetails
-- Database: VEDMaster
-- Data: 12/09/2025

-- Prima recuperiamo informazioni sulla colonna per vedere il tipo di dato esatto e la nullability
DECLARE @DATA_TYPE NVARCHAR(128);
DECLARE @IS_NULLABLE NVARCHAR(3);

SELECT 
    @DATA_TYPE = DATA_TYPE,
    @IS_NULLABLE = IS_NULLABLE
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'MA_PurchaseOrdDetails' 
    AND COLUMN_NAME = 'Description';

-- Mostra le informazioni correnti
PRINT 'Tipo di dato attuale: ' + @DATA_TYPE;
PRINT 'Nullability: ' + @IS_NULLABLE;

-- Costruisce ed esegue l'ALTER TABLE con i parametri corretti
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = 'ALTER TABLE VEDMaster.dbo.MA_PurchaseOrdDetails ALTER COLUMN [Description] ' 
    + @DATA_TYPE + '(280) ' 
    + CASE WHEN @IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END + ';';

PRINT 'Esecuzione query: ' + @SQL;

-- Esegue l'ALTER TABLE
EXEC sp_executesql @SQL;

PRINT 'Modifica applicata con successo.';

-- Verifica finale
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM VEDMaster.INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'MA_PurchaseOrdDetails' 
    AND COLUMN_NAME = 'Description';
