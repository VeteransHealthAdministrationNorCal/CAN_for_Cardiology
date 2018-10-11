;WITH
t AS (
  SELECT 
    patient.PatientSSN
	,patient.patientSID
    ,patient.PatientName
    ,StopCode.StopCodeName
    ,can.cMOrt_1y
    ,can.pMort_1y
    ,can.cMort_90d
    ,can.pMort_90d
    ,convert(varchar(10),VisitDateTime,101) as VisitDate
    ,PrimaryStopCodeSID
    ,SecondaryStopCodeSID
  FROM
    lsv.Outpat.Visit as visit
    inner join lsv.dim.StopCode as StopCode 
      on visit.PrimaryStopCodeSID = StopCode.StopCodeSID and  visit.Sta3n = StopCode.Sta3n
    inner join lsv.SPatient.SPatient as patient
      on patient.PatientSID = visit.PatientSID 
    inner join LSV.BISL_Collab.CANScore_Weekly as can
      on can.PatientICN = patient.PatientICN
  where
    visit.Sta3n='612'
    and  StopCode.StopCodeName like '%Cardi%'
    and visit.VisitDateTime >=convert(Datetime2(0),dateadd(dd,-365,getdate()))
    and Patient.PatientLastName not like '%ZZ%'
    and Patient.DeceasedFlag <> 'Y'
  order by
    patient.PatientSSN
),

a as (
  Select distinct
    t.PatientSSN
    ,t.PatientName
    ,t.VisitDate
    ,icd10.ICD10code
    ,t.cMort_1y
    ,t.pMort_1y
    ,t.cMort_90d
    ,t.pMort_90d
  from
    t
    inner join lsv.Outpat.Problemlist as pbl 
      on pbl.PatientSID = t.PatientSID
    inner join lsv.dim.ICD10 as icd10
      on icd10.ICD10SID = pbl.ICD10SID
  where
    icd10.ICD10Code like '%I50%'
)

select
  a.PatientSSN,
  a.pMort_90d,
  a.pMort_1y,a.cMort_1y,
  count(a.PatientSSN) as OutpatientEncounterInYear
from 
  a
group by
  a.PatientSSN, a.pMort_1y, a.pMort_90d, a.cMort_1y
order by
  OutpatientEncounterInYear ASC, a.pMort_90d DESC