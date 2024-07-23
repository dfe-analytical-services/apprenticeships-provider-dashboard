/***********
Demographics Data for Apprenticeships Interactive Tool
Updated by:      Alison Cooper - to include provider name rather than learner lad
Quarter:         Q3 (August to April) 2024
Snapshot:        10  
Approx run time: 1-2 mins
***********/

--Update
--Demographic info fields sex, age group  ethnicity_major and lldd.
--MT 27/02/2024

DECLARE @CurrentSnapshot INT
DECLARE @CurrentYear INT

SET @CurrentSnapshot =  10 -- **UPDATE** for each quarter
SET @CurrentYear = 202324 -- **UPDATE** for each academic year

--Select latest IFA routes data
IF OBJECT_ID('tempdb..#Routes_IFA') IS NOT NULL DROP TABLE #Routes_IFA
SELECT 
[std_fwk_name] as std_fwk_name_routes,
[std_lars_code]
INTO  #Routes_IFA
FROM  [MA_FEDU_S_DATADEV].[REF].[Routes_IFA] 
WHERE [Snapshot]= @CurrentSnapshot AND [academic_year]= @CurrentYear


--Select and define fields and join on routes data
IF OBJECT_ID('tempdb..#APPS') IS NOT NULL DROP TABLE #APPS
SELECT 
CASE WHEN [year]= @CurrentYear THEN
CASE WHEN @CurrentSnapshot=4   THEN CONCAT([year],' (Q1 Aug to Oct)')
	 WHEN @CurrentSnapshot=6   THEN CONCAT([year],' (Q2 Aug to Jan)')
	 WHEN @CurrentSnapshot=10  THEN CONCAT([year],' (Q3 Aug to Apr)')
	 ELSE [year] END ELSE [year] END AS [year],

age_summary as age_group,
sex,
ethnicity_major,
lldd,
name as provider_name,
starts_sr as [starts],
achievements_sr as [achievements],
CASE WHEN [year]=@CurrentYear AND @CurrentSnapshot=4  THEN [enrols_Q1]
	 WHEN [year]=@CurrentYear AND @CurrentSnapshot=6  THEN [enrols_Q1to2]
     WHEN [year]=@CurrentYear AND @CurrentSnapshot=10 THEN [enrols_Q1to3]
	 ELSE [enrols_Q1to4] END AS [enrolments]
INTO #APPS 
FROM [MA_FEDU_S_DATADEV].[MST].[vw_Apprenticeship_Start_Ach_IL_EES] a
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
coalesce(age_group,'Total') as age_group,
coalesce(sex,'Total') as sex,
coalesce(ethnicity_major,'Total') as ethnicity_major,
coalesce(lldd,'Total') as lldd,
coalesce(provider_name,'Total') as provider_name,
round(sum(starts), -1) as starts,
round(sum(achievements), -1) as achievements
FROM #APPS 
group by 
[year],
cube(
age_group,
sex,
ethnicity_major,
lldd,
provider_name);
