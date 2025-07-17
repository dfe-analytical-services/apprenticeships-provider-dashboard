/***********
Data for Apprenticeships Interactive Tool
Updated by:      Jon Holman
Year:            2025
Quarter:         Q3 (August to Apr)
Snapshot:        10  
Approx run time: 2 mins
Rows:			1,370,333
***********/

SET ANSI_PADDING OFF SET NOCOUNT ON;

DECLARE @CurrentSnapshot INT
DECLARE @CurrentYear INT

SET @CurrentSnapshot =  10 -- **UPDATE** for each quarter
SET @CurrentYear = 202425 -- **UPDATE** for each academic year

--Select latest IFA routes data
IF OBJECT_ID('tempdb..#Routes_IFA') IS NOT NULL DROP TABLE #Routes_IFA
SELECT 
[std_fwk_name] as std_fwk_name_routes,
[std_lars_code]
INTO  #Routes_IFA
FROM  MA_FEDU_S_DATA.[REF].[Routes_IFA] 
WHERE [Snapshot]= @CurrentSnapshot AND [academic_year]= @CurrentYear


--Select and define fields, and join on routes data
IF OBJECT_ID('tempdb..#APPS') IS NOT NULL DROP TABLE #APPS
SELECT 
CASE WHEN [year]= @CurrentYear THEN
CASE WHEN @CurrentSnapshot=4   THEN CONCAT([year],' (Aug to Oct)')
	 WHEN @CurrentSnapshot=6   THEN CONCAT([year],' (Aug to Jan)')
	 WHEN @CurrentSnapshot=10  THEN CONCAT([year],' (Aug to Apr)')
	 ELSE [year] END ELSE [year] END AS [year],

age_summary as age_group,
CASE WHEN age_summary = 'Under 19' then 1
     WHEN age_summary = '19-24' then 2
	 WHEN age_summary = '25+' then 3
	 else 4 END as age_group_order,

apps_Level,
CASE WHEN apps_Level = 'Intermediate Apprenticeship' then 1
     WHEN apps_Level = 'Advanced Apprenticeship' then 2
	 WHEN apps_Level = 'Higher Apprenticeship' then 3
	 else 4 END as apps_level_order,
apps_level_detailed,
CASE WHEN std_fwk_flag='Standard' THEN r.std_fwk_name_routes  ELSE std_fwk_name END AS std_fwk_name,
ssa_t1_desc,
ssa_t2_desc,
std_fwk_flag,
provider_type,
--[name] as provider_name,
[name_with_ukprn] as provider_name,
learner_home_region,
CASE WHEN learner_home_region = 'North East' then 1
     WHEN learner_home_region = 'North West' then 2
	 WHEN learner_home_region = 'Yorkshire and The Humber' then 3
	 WHEN learner_home_region = 'East Midlands' then 4
	 WHEN learner_home_region = 'West Midlands' then 5
     WHEN learner_home_region = 'East of England' then 6
	 WHEN learner_home_region = 'London' then 7
	 WHEN learner_home_region = 'South East' then 8
	 WHEN learner_home_region = 'South West' then 9
	 WHEN learner_home_region = 'Outside of England and unknown' then 10
     ELSE 11 END as learner_home_region_order,
learner_home_la,
learner_home_lad,
learner_home_devolved_administration,
CASE WHEN learner_home_devolved_administration = 'Cambridgeshire and Peterborough' then 1
     WHEN learner_home_devolved_administration = 'Greater London Authority' then 2
	 WHEN learner_home_devolved_administration = 'Greater Manchester' then 3
	 WHEN learner_home_devolved_administration = 'Liverpool City Region' then 4
	 WHEN learner_home_devolved_administration = 'North East' then 5
	 WHEN learner_home_devolved_administration = 'North of Tyne' then 6
	 WHEN learner_home_devolved_administration = 'Sheffield City Region' then 7
	 WHEN learner_home_devolved_administration = 'South Yorkshire' then 8
	 WHEN learner_home_devolved_administration = 'Tees Valley' then 9
	 WHEN learner_home_devolved_administration = 'West Midlands' then 10
	 WHEN learner_home_devolved_administration = 'West of England' then 11
	 WHEN learner_home_devolved_administration = 'West Yorkshire' then 12
	 WHEN learner_home_devolved_administration = 'Outside of an English Devolved Area and unknown' then 13
ELSE 14 END as learner_home_devolved_administration_order,
delivery_region,
CASE WHEN delivery_region = 'North East' then 1
     WHEN delivery_region = 'North West' then 2
	 WHEN delivery_region = 'Yorkshire and The Humber' then 3
	 WHEN delivery_region = 'East Midlands' then 4
	 WHEN delivery_region = 'West Midlands' then 5
	 WHEN delivery_region = 'East of England' then 6
	 WHEN delivery_region = 'London' then 7
	 WHEN delivery_region = 'South East' then 8
	 WHEN delivery_region = 'South West' then 9
	 WHEN delivery_region = 'Outside of England and unknown' then 10
     ELSE 11 END as delivery_region_order,
delivery_la,
delivery_lad,
delivery_devolved_administration,
CASE WHEN delivery_devolved_administration = 'Cambridgeshire and Peterborough' then 1
     WHEN delivery_devolved_administration = 'Greater London Authority' then 2
	 WHEN delivery_devolved_administration = 'Greater Manchester' then 3
	 WHEN delivery_devolved_administration = 'Liverpool City Region' then 4
	 WHEN delivery_devolved_administration = 'North East' then 5
	 WHEN delivery_devolved_administration = 'North of Tyne' then 6
	 WHEN delivery_devolved_administration = 'Sheffield City Region' then 7
	 WHEN delivery_devolved_administration = 'South Yorkshire' then 8
	 WHEN delivery_devolved_administration = 'Tees Valley' then 9
	 WHEN delivery_devolved_administration = 'West Midlands' then 10
	 WHEN delivery_devolved_administration = 'West of England' then 11
	 WHEN delivery_devolved_administration = 'West Yorkshire' then 12
	 WHEN delivery_devolved_administration = 'Outside of an English Devolved Area and unknown' then 13
ELSE 14 END as delivery_devolved_administration_order,
starts_sr as [starts],
achievements_sr as [achievements],
CASE WHEN [year]=@CurrentYear AND @CurrentSnapshot=4  THEN [enrols_Q1]
	 WHEN [year]=@CurrentYear AND @CurrentSnapshot=6  THEN [enrols_Q1to2]
     WHEN [year]=@CurrentYear AND @CurrentSnapshot=10 THEN [enrols_Q1to3]
	 ELSE [enrols_Q1to4] END AS [enrolments]
INTO #APPS 
FROM MA_FEDU_S_DATA.[MST].[vw_Apprenticeship_Start_Ach_IL_EES] a
LEFT JOIN #Routes_IFA r
on a.std_fwk_flag = 'Standard' and a.std_fwk_code = r.std_lars_code
WHERE
([Snapshot]=14 AND [year] IN (@CurrentYear-202, @CurrentYear-101))
OR
([Snapshot]=@CurrentSnapshot AND [year]= @CurrentYear)


--Calculate measures and group data, and format year*
--*ie place a /(solidus) after the first 4 characters, so that date appears as, for example, 2022/23 rather than 202223
SELECT 
substring([year],1,4) + '/' + substring([year],5,22) as [year],
age_group,
age_group_order,
apps_Level,
apps_level_order,
apps_level_detailed,
std_fwk_name,
ssa_t1_desc,
ssa_t2_desc,
std_fwk_flag,
provider_type,
provider_name,
learner_home_region,
learner_home_region_order,
learner_home_la,
learner_home_lad,
learner_home_devolved_administration,
learner_home_devolved_administration_order,
delivery_region,
delivery_region_order,
delivery_la,
delivery_lad,
delivery_devolved_administration,
delivery_devolved_administration_order,
sum([starts]) as [starts],
sum([achievements]) as [achievements],
sum([enrolments]) as [enrolments]
FROM #APPS 
group by
[year],
age_group,
age_group_order,
apps_Level,
apps_level_order,
apps_level_detailed,
std_fwk_name,
ssa_t1_desc,
ssa_t2_desc,
std_fwk_flag,
provider_type,
provider_name,
learner_home_region,
learner_home_region_order,
learner_home_la,
learner_home_lad,
learner_home_devolved_administration,
learner_home_devolved_administration_order,
delivery_region,
delivery_region_order,
delivery_la,
delivery_lad,
delivery_devolved_administration,
delivery_devolved_administration_order;
