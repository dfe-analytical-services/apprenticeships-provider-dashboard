# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script where we provide code to create the data files
#
# IMPORTANT: Data files pushed to GitHub repositories are immediately public.
# You should not be pushing unpublished data to the repository prior to your
# publication date. You should use dummy data or already-published data during
# development of your dashboard.
#
# In order to help prevent unpublished data being accidentally published, the
# template will not let you make a commit if there are unidentified csv, xlsx,
# parquet, tex or pdf files contained in your repository. To make a commit, you
# will need to either add the file to .gitignore or add an entry for the file
# into datafiles_log.csv.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Using this script to create the data files for the app
#
# 1. Run the SQL scripts in the sql/ folder
# 2. Save the outputs as CSV in the data/ folder
# 3. Then run this script to generate parquet format versions of the files
#
# Using parquet format as it's compressed to a smaller size and is faster to load
#
# Could amend the current SQL queries to save the tables in SQL ready to read in using a SQL connection
#
# There are 3 source files, each with a script in sql/ folder
# These are then processed into 5 files that the app uses and reads in, one per 'module'
#
# We've done it this way to mimimise the data the app needs to read and hold in
# memory as some of the files are quite big! Apps data is over 1 million rows
#
# Apprenticeships data is the source for...
# - Provider breakdowns
# - LAD map data
# - Subjects and standards
#
# Apprenticeships demographics is the source for...
# - Learner characteristics
#
# National provider summary is the source for...
# - National provider summary
#
# Dependencies ----------------------------------------------------------------
library(data.table)
library(arrow)
library(dplyr)
library(tidyr)
library(sf)
library(sfarrow)
library(stringr)

# Read in files saved from SQL scripts ----------------------------------------
national_provider_summary <- data.table::fread("data/national_provider_summary.csv") %>%
  select(-c(`order_ref`, `order_detailed`)) # unused columns

apps_demographics <- data.table::fread("data/apprenticeships_demographics.csv")

apps_data <- data.table::fread("data/apprenticeships_data.csv")

# Create Provider breakdowns data ---------------------------------------------
# Making a smaller cut from apps_data so less data is loaded into the app
provider_breakdowns <- apps_data %>%
  group_by(
    year, provider_name, provider_type, apps_Level,
    age_group, delivery_region, learner_home_region
  ) %>%
  summarise(
    starts = sum(starts, na.rm = TRUE),
    enrolments = sum(enrolments, na.rm = TRUE),
    achievements = sum(achievements, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  as.data.frame()

# Create subjects and standards data ------------------------------------------
# Making a smaller cut from apps_data so less processing is done in the app
subjects_and_standards <- apps_data |>
  summarise(
    starts = sum(starts),
    enrolments = sum(enrolments),
    achievements = sum(achievements),
    .by = c(
      "year", "apps_Level", "std_fwk_name", "ssa_t1_desc",
      "ssa_t2_desc", "std_fwk_flag", "provider_type", "provider_name"
    )
  ) |>
  pivot_longer(
    c("starts", "enrolments", "achievements"),
    names_to = "measure",
    values_to = "values"
  ) |>
  mutate(
    provider_name = str_to_title(provider_name),
    measure = str_to_sentence(measure)
  )

# Create LAD map data ---------------------------------------------------------
# Preparing the data now so that less processing is needed in the app
lad_map_data <- apps_data %>%
  group_by(year, provider_name, learner_home_lad, delivery_lad) %>%
  summarise(
    starts = sum(starts, na.rm = TRUE),
    enrolments = sum(enrolments, na.rm = TRUE),
    achievements = sum(achievements, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  as.data.frame()

# Create Region map data ---------------------------------------------------------
# Preparing the data now so that less processing is needed in the app
region_map_data <- apps_data %>%
  group_by(year, provider_name, learner_home_region, delivery_region) %>%
  summarise(
    starts = sum(starts, na.rm = TRUE),
    enrolments = sum(enrolments, na.rm = TRUE),
    achievements = sum(achievements, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  as.data.frame()

# Create demographics/characteristics data ------------------------------------
# Preparing the data now so that less processing is needed in the app

apps_chars <- apps_demographics %>%
  # Default for input is to select rows within a column so put into long format
  pivot_longer(
    cols = -c(year, age_group, sex, ethnicity_major, lldd, provider_name),
    names_to = "measure",
    values_to = "count"
  ) %>%
  mutate(measure = firstup(measure))

# This pivots it longer still and puts in the totals for the table
# Each section is worked out separately

chars_total_lldd <- apps_chars %>%
  filter(lldd == "Total" & sex == "Total" & age_group == "Total" & ethnicity_major == "Total") %>%
  mutate(
    characteristic_type = "Learner with learning difficulties or disabilities (LLDD)",
    characteristic = "Total"
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_lldd <- apps_chars %>%
  filter(lldd != "Total") %>%
  mutate(
    characteristic_type = "Learner with learning difficulties or disabilities (LLDD)",
    characteristic = lldd
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_total_sex <- apps_chars %>%
  filter(lldd == "Total" & sex == "Total" & age_group == "Total" & ethnicity_major == "Total") %>%
  mutate(
    characteristic_type = "Sex",
    characteristic = sex
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_sex <- apps_chars %>%
  filter(sex != "Total") %>%
  mutate(
    characteristic_type = "Sex",
    characteristic = sex
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_total_age <- apps_chars %>%
  filter(lldd == "Total" & sex == "Total" & age_group == "Total" & ethnicity_major == "Total") %>%
  mutate(
    characteristic_type = "Age",
    characteristic = age_group
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_age <- apps_chars %>%
  filter(age_group != "Total") %>%
  mutate(
    characteristic_type = "Age",
    characteristic = age_group
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_total_ethnicity <- apps_chars %>%
  filter(lldd == "Total" & sex == "Total" & age_group == "Total" & ethnicity_major == "Total") %>%
  mutate(
    characteristic_type = "Ethnicity",
    characteristic = ethnicity_major
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

chars_ethnicity <- apps_chars %>%
  filter(ethnicity_major != "Total") %>%
  mutate(
    characteristic_type = "Ethnicity",
    characteristic = ethnicity_major
  ) %>%
  select(year, provider_name, characteristic_type, characteristic, measure, count)

# Put all the bits of file together for the final version
apps_chars <-
  rbind(
    chars_total_age, chars_age,
    chars_total_sex, chars_sex,
    chars_total_lldd, chars_lldd,
    chars_total_ethnicity, chars_ethnicity
  )

# Write out parquet files -----------------------------------------------------
arrow::write_dataset(provider_breakdowns, "data/",
  format = "parquet",
  basename_template = "provider_breakdowns_{i}.parquet"
)

arrow::write_dataset(lad_map_data, "data/",
  format = "parquet",
  basename_template = "lad_map_data_{i}.parquet"
)

arrow::write_dataset(region_map_data, "data/",
                     format = "parquet",
                     basename_template = "region_map_data_{i}.parquet"
)

arrow::write_dataset(subjects_and_standards, "data/",
  format = "parquet",
  basename_template = "subjects_and_standards_{i}.parquet"
)

arrow::write_dataset(apps_chars, "data/",
  format = "parquet",
  basename_template = "apprenticeships_demographics_{i}.parquet"
)

arrow::write_dataset(national_provider_summary, "data/",
  format = "parquet",
  basename_template = "national_provider_summary_{i}.parquet"
)
