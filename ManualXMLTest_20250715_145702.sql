-- Script per test manuale XML
-- Prova a esportare piccoli batch per identificare il problema

-- Test 1: Primi 1000 record
SELECT TOP 1000 * FROM [MA_ItemCustomers] ORDER BY Item, Customer

-- Test 2: Record intorno alla posizione stimata (177821)
WITH OrderedRecords AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY Item, Customer) as RowNum
    FROM [MA_ItemCustomers]
)
SELECT * FROM OrderedRecords 
WHERE RowNum BETWEEN 177721 AND 177921
ORDER BY RowNum

-- Test 3: Cerca pattern sospetti
SELECT * FROM [MA_ItemCustomers]
WHERE CustomerDescription LIKE '%[' + CHAR(0) + '-' + CHAR(31) + ']%'
   OR Notes LIKE '%[' + CHAR(0) + '-' + CHAR(31) + ']%'
