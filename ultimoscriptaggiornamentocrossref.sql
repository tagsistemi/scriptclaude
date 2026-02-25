update d 
set d.OriginDocID = c.IM_JobId 
from (select 
a.*,
b.IM_JobId as oldjobId,
c.IM_JobId as newJobId
from furmanetclone.dbo.MM4_MappaJobsCodes a
inner join MA_Jobs b on b.Job = a.vecchiocodice
inner join MA_Jobs c on c.Job = a.nuovocodice
inner join MA_CrossReferences d on d.OriginDocID = b.IM_JobId) a
inner join MA_Jobs b on b.Job = a.vecchiocodice
inner join MA_Jobs c on c.Job = a.nuovocodice
inner join MA_CrossReferences d on d.OriginDocID = b.IM_JobId

update d 
set d.OriginDocID = c.IM_JobId 
from (select 
a.*,
b.IM_JobId as oldjobId,
c.IM_JobId as newJobId
from vedbondifeclone.dbo.MM4_MappaJobsCodes a
inner join MA_Jobs b on b.Job = a.vecchiocodice
inner join MA_Jobs c on c.Job = a.nuovocodice
inner join MA_CrossReferences d on d.OriginDocID = b.IM_JobId) a
inner join MA_Jobs b on b.Job = a.vecchiocodice
inner join MA_Jobs c on c.Job = a.nuovocodice
inner join MA_CrossReferences d on d.OriginDocID = b.IM_JobId