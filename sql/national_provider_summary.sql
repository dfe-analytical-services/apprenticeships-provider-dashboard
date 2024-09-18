--National Provider Summary for Apprenticeships and Education & Training and community learning
--Years: 2021/22 to 202324
--Snapshot: Q3 2023/24
--          Q4 2021/22 to 2022/23

--Declare and set year and snapshot
DECLARE @CurrentSnapshot INT
DECLARE @CurrentYear INT
SET @CurrentYear = 202324  -- **UPDATE** for each academic year
SET @CurrentSnapshot = 10  -- **UPDATE** for each quarter

--Select required fields for latest 3 years
IF OBJECT_ID('tempdb..#PARTICIPATION') IS NOT NULL DROP TABLE #PARTICIPATION
SELECT

CASE WHEN [year]= @CurrentYear THEN
CASE WHEN @CurrentSnapshot=4   THEN CONCAT([year],' (Q1 Aug to Oct)')
	 WHEN @CurrentSnapshot=6   THEN CONCAT([year],' (Q2 Aug to Jan)')
	 WHEN @CurrentSnapshot=10  THEN CONCAT([year],' (Q3 Aug to Apr)')
	 ELSE [year] END ELSE [year] END AS [year],

provider_name,
cast (UKPRN as varchar) as UKPRN,
sex,
lldd,
learner_home_depriv,
minority_ethnic,
fes_total,
apps_total,
cl_total,
eandt_total
INTO #PARTICIPATION
FROM [MA_FEDU_S_DATADEV].[MST].[tDM_Learner_table_EES]
WHERE
([Snapshot]=14 AND [year] IN (@CurrentYear-202, @CurrentYear-101)) --final data for previous 2 years
OR
([Snapshot]=@CurrentSnapshot AND [year]= @CurrentYear) --latest data for latest year


--Calculate figures and format year* 
--*ie place a / (solidus) after the first 4 characters, so that year appears as, for example, 2022/23 rather than 202223

--National totals
IF OBJECT_ID('tempdb..#NATIONAL') IS NOT NULL DROP TABLE #NATIONAL
SELECT
1 as order_ref,
substring([year],1,4) + '/' + substring([year],5,22) as [year],
'TOTAL (ALL PROVIDERS)' as provider_name,
'' as ukprn,
'Total' as category,
isnull(sum(apps_total),0) as apps,
isnull(sum(eandt_total),0)as et,
isnull(sum(cl_total),0) as cl
INTO #NATIONAL
FROM #PARTICIPATION
GROUP BY [year]

IF OBJECT_ID('tempdb..#NATIONAL_SEX') IS NOT NULL DROP TABLE #NATIONAL_SEX
SELECT
1 as order_ref,
substring([year],1,4) + '/' + substring([year],5,22) as [year],
'TOTAL (ALL PROVIDERS)' as provider_name,
'' as ukprn,
case when sex = 'Female' then 'Sex - Female' when sex = 'Male' then 'Sex - Male' end as category,
isnull(sum(apps_total),0) as apps,
isnull(sum(eandt_total),0)as et,
isnull(sum(cl_total),0) as cl
INTO #NATIONAL_SEX
FROM #PARTICIPATION
GROUP BY [year], sex



IF OBJECT_ID('tempdb..#NATIONAL_LLDD') IS NOT NULL DROP TABLE #NATIONAL_LLDD
SELECT
1 as order_ref,
substring([year],1,4) + '/' + substring([year],5,22) as [year],
'TOTAL (ALL PROVIDERS)' as provider_name,
'' as ukprn,
lldd as  category,
isnull(sum(apps_total),0) as apps,
isnull(sum(eandt_total),0)as et,
isnull(sum(cl_total),0) as cl
INTO #NATIONAL_LLDD
FROM #PARTICIPATION
GROUP BY [year], lldd

IF OBJECT_ID('tempdb..#NATIONAL_DEP') IS NOT NULL DROP TABLE #NATIONAL_DEP
SELECT
1 as order_ref,
substring([year],1,4) + '/' + substring([year],5,22) as [year],
'TOTAL (ALL PROVIDERS)' as provider_name,
'' as ukprn,
case when learner_home_depriv = 'Unknown' then 'IMD - unknown' 
     when learner_home_depriv = 'One (most deprived)' then 'IMD - One (most deprived)' 
	 when learner_home_depriv = 'Two' then 'IMD - Two'
	 when learner_home_depriv = 'Three' then 'IMD - Three'
	 when learner_home_depriv = 'Four' then 'IMD - Four'
	 when learner_home_depriv = 'Five (least deprived)' then 'IMD - Five (least deprived)'
     else  learner_home_depriv end as category,
isnull(sum(apps_total),0) as apps,
isnull(sum(eandt_total),0)as et,
isnull(sum(cl_total),0) as cl
INTO #NATIONAL_DEP
FROM #PARTICIPATION
GROUP BY [year], learner_home_depriv


IF OBJECT_ID('tempdb..#NATIONAL_ETH') IS NOT NULL DROP TABLE #NATIONAL_ETH
SELECT
1 as order_ref,
substring([year],1,4) + '/' + substring([year],5,22) as [year],
'TOTAL (ALL PROVIDERS)' as provider_name,
'' as ukprn,
case when minority_ethnic = 'White' then 'Ethnicity - White' when minority_ethnic = 'Unknown' then 'Ethnicity - unknown' else minority_ethnic end as category,
isnull(sum(apps_total),0) as apps,
isnull(sum(eandt_total),0)as et,
isnull(sum(cl_total),0) as cl
INTO #NATIONAL_ETH
FROM #PARTICIPATION
GROUP BY [year], minority_ethnic


--Join national data together into one table
IF OBJECT_ID('tempdb..#NATIONAL_TIDY') IS NOT NULL DROP TABLE #NATIONAL_TIDY
select *
into #NATIONAL_TIDY
from #NATIONAL
union all
select *
from #NATIONAL_SEX
union all
select *
from #NATIONAL_LLDD
union all
select *
from #NATIONAL_DEP
union all
select *
from #NATIONAL_ETH


--define detailed ordering for national data
IF OBJECT_ID('tempdb..#NATIONAL_TIDY_ORDER') IS NOT NULL DROP TABLE #NATIONAL_TIDY_ORDER
SELECT
order_ref,
case when provider_name =  'TOTAL (ALL PROVIDERS)' and ukprn = '' and category = 'Total' then 1
	 when category = 'Sex - Female' then 2
	 when category = 'Sex - Male' then 3
	 when category = 'LLDD - yes' then 4
	 when category = 'LLDD - no' then 5
	 when category = 'LLDD - unknown' then 6
	 when category = 'IMD - One (most deprived)' then 7
	 when category = 'IMD - Two' then 8
	 when category = 'IMD - Three' then 9
	 when category = 'IMD - Four' then 10
	 when category = 'IMD - Five (least deprived)' then 11
	 when category = 'IMD - unknown' then 12
	 when category = 'Ethnicity - White' then 13
	 when category = 'Ethnic minorities (excluding white minorities)' then 14
	 when category = 'Ethnicity - unknown' then 15
end as order_detailed,
[year],
provider_name,
ukprn,
category,
apps,
et,
cl
into #NATIONAL_TIDY_ORDER
FROM #NATIONAL_TIDY
ORDER BY [year], provider_name


--Provider level
IF OBJECT_ID('tempdb..#PROVIDER') IS NOT NULL DROP TABLE #PROVIDER
SELECT
substring([year],1,4) + '/' + substring([year],5,22) as [year],
provider_name,
UKPRN,
--apps
isnull(sum(apps_total),0) as apps,
isnull(sum(case when sex = 'Female' then apps_total end),0) as apps_female,
isnull(sum(case when sex = 'Male' then apps_total end),0) as apps_male,
isnull(sum(case when lldd = 'LLDD - yes' then apps_total end),0) as apps_lldd_yes,
isnull(sum(case when lldd = 'LLDD - no' then apps_total end),0) as apps_lldd_no,
isnull(sum(case when lldd = 'LLDD - unknown' then apps_total end),0) as apps_lldd_unknown,
isnull(sum(case when learner_home_depriv = 'One (most deprived)' then apps_total end),0) as apps_dep_1,
isnull(sum(case when learner_home_depriv = 'Two' then apps_total end),0) as apps_dep_2,
isnull(sum(case when learner_home_depriv = 'Three' then apps_total end),0) as apps_dep_3,
isnull(sum(case when learner_home_depriv = 'Four' then apps_total end),0) as apps_dep_4,
isnull(sum(case when learner_home_depriv = 'Five (least deprived)' then apps_total end),0) as apps_dep_5,
isnull(sum(case when learner_home_depriv = 'Unknown' then apps_total end),0) as apps_dep_u,
isnull(sum(case when minority_ethnic = 'White' then apps_total end),0) as apps_white,
isnull(sum(case when minority_ethnic = 'Ethnic minorities (excluding white minorities)' then apps_total end),0) as apps_ethnic_minorities,
isnull(sum(case when minority_ethnic = 'Ethnicity - unknown' then apps_total end),0) as apps_ethnic_u,
--et
isnull(sum(eandt_total),0) as et,
isnull(sum(case when sex = 'Female' then eandt_total end),0) as et_female,
isnull(sum(case when sex = 'Male' then eandt_total end),0) as et_male,
isnull(sum(case when lldd = 'LLDD - yes' then eandt_total end),0) as et_lldd_yes,
isnull(sum(case when lldd = 'LLDD - no' then eandt_total end),0) as et_lldd_no,
isnull(sum(case when lldd = 'LLDD - unknown' then eandt_total end),0) as et_lldd_unknown,
isnull(sum(case when learner_home_depriv = 'One (most deprived)' then eandt_total end),0) as et_dep_1,
isnull(sum(case when learner_home_depriv = 'Two' then eandt_total end),0) as et_dep_2,
isnull(sum(case when learner_home_depriv = 'Three' then eandt_total end),0) as et_dep_3,
isnull(sum(case when learner_home_depriv = 'Four' then eandt_total end),0) as et_dep_4,
isnull(sum(case when learner_home_depriv = 'Five (least deprived)' then eandt_total end),0) as et_dep_5,
isnull(sum(case when learner_home_depriv = 'Unknown' then eandt_total end),0) as et_dep_u,
isnull(sum(case when minority_ethnic = 'White' then eandt_total end),0) as et_white,
isnull(sum(case when minority_ethnic = 'Ethnic minorities (excluding white minorities)' then eandt_total end),0) as et_ethnic_minorities,
isnull(sum(case when minority_ethnic = 'Ethnicity unknown' then eandt_total end),0) as et_ethnic_u,
--cl
isnull(sum(cl_total),0) as cl,
isnull(sum(case when sex = 'Female' then cl_total end),0) as cl_female,
isnull(sum(case when sex = 'Male' then cl_total end),0) as cl_male,
isnull(sum(case when lldd = 'LLDD - yes' then cl_total end),0) as cl_lldd_yes,
isnull(sum(case when lldd = 'LLDD - no' then cl_total end),0) as cl_lldd_no,
isnull(sum(case when lldd = 'LLDD - unknown' then cl_total end),0) as cl_lldd_unknown,
isnull(sum(case when learner_home_depriv = 'One (most deprived)' then cl_total end),0) as cl_dep_1,
isnull(sum(case when learner_home_depriv = 'Two' then cl_total end),0) as cl_dep_2,
isnull(sum(case when learner_home_depriv = 'Three' then cl_total end),0) as cl_dep_3,
isnull(sum(case when learner_home_depriv = 'Four' then cl_total end),0) as cl_dep_4,
isnull(sum(case when learner_home_depriv = 'Five (least deprived)' then cl_total end),0) as cl_dep_5,
isnull(sum(case when learner_home_depriv = 'Unknown' then cl_total end),0) as cl_dep_u,
isnull(sum(case when minority_ethnic = 'White' then cl_total end),0) as cl_white,
isnull(sum(case when minority_ethnic = 'Ethnic minorities (excluding white minorities)' then cl_total end),0) as cl_ethnic_minorities,
isnull(sum(case when minority_ethnic = 'Ethnicity unknown' then cl_total end),0) as cl_ethnic_u
INTO #PROVIDER
FROM #PARTICIPATION
GROUP BY [year], UKPRN, provider_name 
ORDER BY [year] desc, UKPRN, provider_name


--Put provider level data into a tidy format.
IF OBJECT_ID('tempdb..#PROVIDER_TIDY') IS NOT NULL DROP TABLE #PROVIDER_TIDY
select
[year], provider_name, UKPRN, 'Total' as category, apps as apps, et as et, cl as cl
into #PROVIDER_TIDY
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'Sex - Female' as category, apps_female as apps, et_female as et, cl_female as cl
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'Sex - Male' as category, apps_male, et_male, cl_male
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'LLDD - yes' as category, apps_lldd_yes, et_lldd_yes, cl_lldd_yes
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'LLDD - no' as category, apps_lldd_no, et_lldd_no, cl_lldd_no
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'LLDD - unknown' as category, apps_lldd_unknown, et_lldd_unknown, cl_lldd_unknown
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - One (most deprived)' as category, apps_dep_1, et_dep_1, cl_dep_1
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - Two' as category, apps_dep_2, et_dep_2, cl_dep_2
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - Three' as category, apps_dep_3, et_dep_3, cl_dep_3
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - Four' as category, apps_dep_4, et_dep_4, cl_dep_4
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - Five (least deprived)' as category, apps_dep_5, et_dep_5, cl_dep_5
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'IMD - unknown' as category, apps_dep_u, et_dep_u, cl_dep_u
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'Ethnicity - White' as category, apps_white, et_white, cl_white
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'Ethnic minorities (excluding white minorities)' as category_type, apps_ethnic_minorities, et_ethnic_minorities, cl_ethnic_minorities
from #PROVIDER
union all
select [year], provider_name, UKPRN, 'Ethnicity - unknown' as category, apps_ethnic_u, et_ethnic_u, cl_ethnic_u
from #PROVIDER


--Define order of category_type field and general order for provider data
IF OBJECT_ID('tempdb..#PROVIDER_TIDY_ORDER') IS NOT NULL DROP TABLE #PROVIDER_TIDY_ORDER
SELECT
2 as order_ref,
case when provider_name <> 'TOTAL (ALL PROVIDERS)' and ukprn <> '' and category = 'Total' then 1
	 when category = 'Sex - Female' then 2
	 when category = 'Sex - Male' then 3
	 when category = 'LLDD - yes' then 4
	 when category = 'LLDD - no' then 5
	 when category = 'LLDD - unknown' then 6
	 when category = 'IMD - One (most deprived)' then 7
	 when category = 'IMD - Two' then 8
	 when category = 'IMD - Three' then 9
	 when category = 'IMD - Four' then 10
	 when category = 'IMD - Five (least deprived)' then 11
	 when category = 'IMD - unknown' then 12
	 when category = 'Ethnicity - White' then 13
	 when category = 'Ethnic minorities (excluding white minorities)' then 14
	 when category = 'Ethnicity - unknown' then 15
end as order_detailed,
[year],
provider_name,
ukprn,
category,
apps,
et,
cl
into #PROVIDER_TIDY_ORDER
FROM #PROVIDER_TIDY
ORDER BY [year], provider_name

--Join national and provider level data together into one table
IF OBJECT_ID('tempdb..#ALL_TIDY') IS NOT NULL DROP TABLE #ALL_TIDY
select *
into #ALL_TIDY
from #NATIONAL_TIDY_ORDER
union all
select *
from #PROVIDER_TIDY_ORDER


--Produce final output
--Rounded and suppressed:
--replace values of 0,1,2,3,4 and 5 with 'low' and round remaining values to nearest 10.
--removing unknown characteristics that are not shown in dashboard
SELECT
order_ref,
order_detailed,
--case when provider_name = 'TOTAL (ALL PROVIDERS)' then 1 else 2 end as provider_order,
[year] as [Academic Year],
provider_name as 'Provider name',
ukprn  As UKPRN,
category as 'Learner characteristic',
case when apps in (0,1,2,3,4) then 'low' else cast(round(apps,-1) as varchar) end as 'Apprenticeships',
case when et   in (0,1,2,3,4) then 'low' else cast(round(et,-1) as varchar) end as 'Education and Training',
case when cl   in (0,1,2,3,4) then 'low' else cast(round(cl,-1) as varchar) end as 'Community Learning'
FROM #ALL_TIDY

where category not in ('IMD - unknown','LLDD - unknown','Ethnicity - unknown') 
ORDER BY order_ref, provider_name, order_detailed, [year] desc



