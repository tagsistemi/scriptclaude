--query causali utilizzate
select DISTINCT *
from 
(
select InvRsn, 'furmanetclone' as Db  from furmanetclone.dbo.[MA_InventoryEntries]
union 
select  InvRsn, 'gpxnetclone' as Db from gpxnetclone.dbo.[MA_InventoryEntries]
union 
select InvRsn, 'vedbondifeclone' as Db  from vedbondifeclone.dbo.[MA_InventoryEntries]

) a 
order by a.InvRsn, a.Db 

--query causali utilizzate escluso db vedmaster
select DISTINCT *
from 
(
select 'furmanetclone' as Db, InvRsn from furmanetclone.dbo.[MA_InventoryEntries]
union 
select  'gpxnetclone' as Db,  InvRsn  from gpxnetclone.dbo.[MA_InventoryEntries]
union 
select  'vedbondifeclone' as Db, InvRsn  from vedbondifeclone.dbo.[MA_InventoryEntries]
) a 
order by a.InvRsn, a.Db 


--query causali utilizzate escluso db vedmaster con default
select  *
from 
(
select 'furmanetclone' as Db, InvRsn, b.DefaultReason from furmanetclone.dbo.[MA_InventoryEntries] a inner join furmanetclone.dbo.[MA_InventoryReasons] b on b.Reason = a.InvRsn
union 
select  'gpxnetclone' as Db,  InvRsn, b.DefaultReason  from gpxnetclone.dbo.[MA_InventoryEntries] a inner join gpxnetclone.dbo.[MA_InventoryReasons] b on b.Reason = a.InvRsn
union 
select  'vedbondifeclone' as Db, InvRsn , b.DefaultReason from vedbondifeclone.dbo.[MA_InventoryEntries] a inner join vedbondifeclone.dbo.[MA_InventoryReasons] b on b.Reason = a.InvRsn
) a 
order by a.InvRsn, a.Db 


-- Conteggio dei conflitti per causale (tutte le causali)
SELECT 
    InvRsn,
    COUNT(DISTINCT Db) as NumeroDatabase
FROM 
(
    select 'furmanetclone' as Db, InvRsn from furmanetclone.dbo.[MA_InventoryEntries]
    union 
    select 'gpxnetclone' as Db, InvRsn from gpxnetclone.dbo.[MA_InventoryEntries]
    union 
    select 'vedbondifeclone' as Db, InvRsn from vedbondifeclone.dbo.[MA_InventoryEntries]
) a
GROUP BY InvRsn
ORDER BY COUNT(DISTINCT Db) DESC, InvRsn

--filtra per conflitti > 2
SELECT 
    InvRsn,
    COUNT(DISTINCT Db) as NumeroDatabase
FROM 
(
    select 'furmanetclone' as Db, InvRsn from furmanetclone.dbo.[MA_InventoryEntries]
    union 
    select 'gpxnetclone' as Db, InvRsn from gpxnetclone.dbo.[MA_InventoryEntries]
    union 
    select 'vedbondifeclone' as Db, InvRsn from vedbondifeclone.dbo.[MA_InventoryEntries]
 
) a
GROUP BY InvRsn
HAVING COUNT(DISTINCT Db) > 1
ORDER BY COUNT(DISTINCT Db) DESC, InvRsn

--conflitti escluso vedmaster
SELECT 
    InvRsn,
    COUNT(DISTINCT Db) as NumeroDatabase
FROM 
(
    select 'furmanetclone' as Db, InvRsn from furmanetclone.dbo.[MA_InventoryEntries]
    union 
    select 'gpxnetclone' as Db, InvRsn from gpxnetclone.dbo.[MA_InventoryEntries]
    union 
    select 'vedbondifeclone' as Db, InvRsn from vedbondifeclone.dbo.[MA_InventoryEntries]
   
) a
GROUP BY InvRsn
ORDER BY COUNT(DISTINCT Db) DESC, InvRsn


--query utilizzo causali
select *
from 
(
select 'furmanetclone' as Depo, InvRsn,  StoragePhase1, StoragePhase2 from furmanetclone.dbo.[MA_InventoryEntries]
union 
select  'gpxnetclone' as Depo,  InvRsn, StoragePhase1, StoragePhase2  from gpxnetclone.dbo.[MA_InventoryEntries]
union 
select  'vedbondifeclone' as Depo, InvRsn, StoragePhase1, StoragePhase2  from vedbondifeclone.dbo.[MA_InventoryEntries]

) a order by InvRsn, a.Depo


-- query per depositi utilizzati
select DISTINCT a.Db, a.StoragePhase1
from 
(
select 'furmanetclone' as Db,  StoragePhase1 from furmanetclone.dbo.[MA_InventoryEntries]
union 
select  'gpxnetclone' as Db,  StoragePhase1  from gpxnetclone.dbo.[MA_InventoryEntries]
union 
select  'vedbondifeclone' as Db , StoragePhase1  from vedbondifeclone.dbo.[MA_InventoryEntries]

) a order by a.db , a.StoragePhase1

-- query per depositi utilizzati
select DISTINCT a.Db, a.StoragePhase2
from 
(
select 'furmanetclone' as Db,  StoragePhase2 from furmanetclone.dbo.[MA_InventoryEntries]
union 
select  'gpxnetclone' as Db,  StoragePhase2  from gpxnetclone.dbo.[MA_InventoryEntries]
union 
select  'vedbondifeclone' as Db , StoragePhase2  from vedbondifeclone.dbo.[MA_InventoryEntries]

) a order by a.db , a.StoragePhase2