INSERT INTO VEDMaster.dbo.SaleDocMapping
(DocumentType, NewSaledocId, DocNo, DocumentDate, OldSaleDocId, Customer, SourceDB)
SELECT
    a.DocumentType, a.SaleDocId as NewSaledocId, a.DocNo, a.DocumentDate, g.SaleDocId as OldSaleDocId, a.CustSupp as Customer, 'gpxnetclone' as SourceDB
FROM VEDMaster.dbo.MA_SaleDoc a
INNER JOIN gpxnetclone.dbo.MA_SaleDoc g
    ON g.DocNo = a.DocNo
    AND g.DocumentDate = a.DocumentDate
    AND g.CustSupp = a.CustSupp
WHERE g.DocumentType = 3407874

UNION ALL

SELECT
    a.DocumentType, a.SaleDocId as NewSaledocId, a.DocNo, a.DocumentDate, v.SaleDocId as OldSaleDocId, a.CustSupp as Customer, 'vedbondifeclone' as SourceDB
FROM VEDMaster.dbo.MA_SaleDoc a
INNER JOIN vedbondifeclone.dbo.MA_SaleDoc v
    ON v.DocNo = a.DocNo
    AND v.DocumentDate = a.DocumentDate
    AND v.CustSupp = a.CustSupp
WHERE v.DocumentType = 3407874

UNION ALL

SELECT
    a.DocumentType, a.SaleDocId as NewSaledocId, a.DocNo, a.DocumentDate, f.SaleDocId as OldSaleDocId, a.CustSupp as Customer, 'furmanetclone' as SourceDB
FROM VEDMaster.dbo.MA_SaleDoc a
INNER JOIN furmanetclone.dbo.MA_SaleDoc f
    ON f.DocNo = a.DocNo
    AND f.DocumentDate = a.DocumentDate
    AND f.CustSupp = a.CustSupp
WHERE f.DocumentType = 3407874;

SELECT @@ROWCOUNT AS RecordInseriti;
