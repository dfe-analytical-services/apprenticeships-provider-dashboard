/***********
Demographics Data for Apprenticeships Interactive Tool
Updated by:      Alison Cooper - to include provider name rather than learner lad, and now to have 'low' rather than zeros for suppressed values
Quarter:         Q1 (August to October) 2026
Snapshot:        4  
Approx run time: 1-2 mins
Rows:			
***********/

--Update
--Demographic info fields sex, age group  ethnicity_major and lldd.
--MT 27/02/2024

--update 09/12/25 include 4 years - 3 full plus latest

SET ANSI_PADDING OFF SET NOCOUNT ON;

DECLARE @CurrentSnapshot INT
DECLARE @CurrentYear INT

SET @CurrentSnapshot =  4 -- **UPDATE** for each quarter
SET @CurrentYear = 202526 -- **UPDATE** for each academic year

--Select latest IFA routes data
IF OBJECT_ID('tempdb..#Routes_IFA') IS NOT NULL DROP TABLE #Routes_IFA
SELECT 
[std_fwk_name] as std_fwk_name_routes,
[std_lars_code]
INTO  #Routes_IFA
FROM  [MA_FEDU_S_DATA].[REF].[Routes_IFA] 
WHERE [Snapshot]= @CurrentSnapshot AND [academic_year]= @CurrentYear


--Select and define fields and join on routes data
IF OBJECT_ID('tempdb..#APPS') IS NOT NULL DROP TABLE #APPS
SELECT 
CASE WHEN [year]= @CurrentYear THEN
CASE WHEN @CurrentSnapshot=4   THEN CONCAT([year],' (Aug to Oct)')
	 WHEN @CurrentSnapshot=6   THEN CONCAT([year],' (Aug to Jan)')
	 WHEN @CurrentSnapshot=10  THEN CONCAT([year],' (Aug to Apr)')
	 ELSE [year] END ELSE [year] END AS [year],

age_summary as age_group,
sex,
ethnicity_major,
lldd,
--name as provider_name,
[name_with_ukprn] as provider_name,
starts_sr as [starts],
achievements_sr as [achievements],
CASE WHEN [year]=@CurrentYear AND @CurrentSnapshot=4  THEN [enrols_Q1]
	 WHEN [year]=@CurrentYear AND @CurrentSnapshot=6  THEN [enrols_Q1to2]
     WHEN [year]=@CurrentYear AND @CurrentSnapshot=10 THEN [enrols_Q1to3]
	 ELSE [enrols_Q1to4] END AS [enrolments]
INTO #APPS 
FROM [MA_FEDU_S_DATA].[MST].[vw_Apprenticeship_Start_Ach_IL_EES] a
LEFT JOIN #Routes_IFA r
on a.std_fwk_flag = 'Standard' and a.std_fwk_code = r.std_lars_code
WHERE([Snapshot]=14 AND [year] IN (@CurrentYear-303, @CurrentYear-202, @CurrentYear-101)) OR ([Snapshot]=@CurrentSnapshot AND [year]= @CurrentYear)


--Calculate measures and group data, and format year*
--*ie place a /(solidus) after the first 4 characters, so that date appears as, for example, 2022/23 rather than 202223

IF OBJECT_ID('tempdb..#APPS2') IS NOT NULL DROP TABLE #APPS2
SELECT 
substring([year],1,4) + '/' + substring([year],5,22) as [year],
coalesce(age_group,'Total') as age_group,
coalesce(sex,'Total') as sex,
coalesce(ethnicity_major,'Total') as ethnicity_major,
coalesce(case when lldd = 'LLDD - no' then 'No learning difficulty / disability' when lldd = 'LLDD - yes' then 'With learning difficulty / disability' when lldd =  'LLDD - unknown' then 'LLDD - Unknown' end,'Total') as lldd,
coalesce(provider_name,'Total (All providers)') as provider_name,
case when sum(starts) < 5 then 'low' else cast(round(sum(starts), -1) as varchar) end as starts,
case when sum(achievements) < 5 then 'low' else cast(round(sum(achievements), -1) as varchar) end as achievements
into #APPS2
FROM #APPS 
group by [year],cube(age_group,sex,ethnicity_major,lldd,provider_name) 

-- Need to stuff the matrix so that for a provider in a year where there are any starts/achievements
--then need all the categories
--Where they are empty will then be set to low

--Create frame

IF OBJECT_ID('tempdb..#frame') IS NOT NULL DROP TABLE #frame
select 
[year],
provider_name,
age_group,
sex,
ethnicity_major,
lldd
into #frame
from 

(

(Select
distinct provider_name ,
[year]
from #APPS2) as prov

cross join 

(select 'Total' as age_group
union all
select 'Under 19' as age_group
union all
select '19-24' as age_group
union all
select '25+' as age_group) as age

cross join 

(select 'Total' as sex
union all
select 'Male' as sex
union all
select 'Female' as sex) as sex

cross join 

(select 'Total' as ethnicity_major
union all
select 'White' as ethnicity_major
union all
select 'Black / African / Caribbean / Black British' ethnicity_major
union all
select 'Asian / Asian British' as ethnicity_major
union all
select 'Mixed / Multiple ethnic groups' as ethnicity_major
union all
select 'Other ethnic group' as ethnicity_major
union all
select 'Unknown' as ethnicity_major) as eth

cross join 

(select 'Total' as lldd
union all
select 'No learning difficulty / disability' as lldd
union all
select 'With learning difficulty / disability' lldd
union all
select 'LLDD - Unknown' as lldd) as lldd

)

where
(age_group not IN ('Total') and sex = 'Total' and ethnicity_major = 'Total' and lldd = 'Total') or 
(age_group = 'Total' and sex  not IN ('Total') and ethnicity_major = 'Total' and lldd = 'Total') or 
(age_group = 'Total' and sex = 'Total' and ethnicity_major  not IN ('Total') and lldd = 'Total') or 
(age_group = 'Total' and sex = 'Total' and ethnicity_major = 'Total' and lldd  not IN ('Total') ) or 
(age_group = 'Total' and sex = 'Total' and ethnicity_major = 'Total' and lldd  = 'Total'  )   ;

--joins data onto frame
--so values for all 
--ensures there is only one breakdown of the data, so not disclosive

select
frame.*,
coalesce(apps2.starts,'low') AS starts,
coalesce(apps2.achievements,'low') AS achievements
from #frame as frame

left join #apps2 as apps2 on 
frame.[year] COLLATE DATABASE_DEFAULT              = apps2.year COLLATE DATABASE_DEFAULT and  
frame.provider_name COLLATE DATABASE_DEFAULT       = apps2.provider_name COLLATE DATABASE_DEFAULT and
frame.age_group COLLATE DATABASE_DEFAULT           = apps2.age_group COLLATE DATABASE_DEFAULT and 
frame.sex COLLATE DATABASE_DEFAULT                 = apps2.sex COLLATE DATABASE_DEFAULT and 
frame.ethnicity_major COLLATE DATABASE_DEFAULT     = apps2.ethnicity_major COLLATE DATABASE_DEFAULT and 
frame.lldd COLLATE DATABASE_DEFAULT                = apps2.lldd COLLATE DATABASE_DEFAULT


where
(frame.age_group not IN ('Total') and frame.sex = 'Total' and frame.ethnicity_major = 'Total' and frame.lldd = 'Total') or 
(frame.age_group = 'Total' and frame.sex  not IN ('Total') and frame.ethnicity_major = 'Total' and frame.lldd = 'Total') or 
(frame.age_group = 'Total' and frame.sex = 'Total' and frame.ethnicity_major  not IN ('Total') and frame.lldd = 'Total') or 
(frame.age_group = 'Total' and frame.sex = 'Total' and frame.ethnicity_major = 'Total' and frame.lldd  not IN ('Total') ) or 
(frame.age_group = 'Total' and frame.sex = 'Total' and frame.ethnicity_major = 'Total' and frame.lldd  = 'Total'  )

order by
provider_name,
[year] desc,
case frame.lldd when 'Total' then 1 when 'No learning difficulty / disability' then 2 when 'With learning difficulty / disability' then 3 when 'LLDD - Unknown' then 4 end,
case frame.ethnicity_major when 'Total' then 1 when 'White' then 2 when 'Black / African / Caribbean / Black British' then 3 
when 'Asian / Asian British' then 4 when 'Mixed / Multiple ethnic groups' then 5 when 'Other ethnic group' then 6 
when 'Unknown' then 7 end,
case frame.sex when 'Total' then 1 when 'Male' then 2 when 'Female' then 3 end,
case frame.age_group when 'Total' then 1 when 'Under 19' then 2 when '19-24' then 3 when '25+' then 4 end


