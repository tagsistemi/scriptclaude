UPDATE d
SET d.SaleDocId = c.SaleOrdId
FROM VEDMaster.dbo.gpx_saledocram d
INNER JOIN gpxnet.dbo.gpx_saledocram a ON d.IdRam = a.IdRam
INNER JOIN gpxnet.dbo.MA_SaleOrd b ON a.SaleDocId = b.SaleOrdId 
INNER JOIN VEDMaster.dbo.MA_SaleOrd c ON c.InternalOrdNo = b.InternalOrdNo