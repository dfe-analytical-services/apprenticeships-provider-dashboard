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
# Dependencies ----------------------------------------------------------------
library(data.table)
library(arrow)
library(dplyr)
library(tidyr)
library(sf)
library(sfarrow)

# Read in files saved from SQL scripts ----------------------------------------
national_provider_summary <- data.table::fread("data/national_provider_summary.csv")
apps_demographics <- data.table::fread("data/apprenticeships_demographics.csv")
apps_data <- data.table::fread("data/apprenticeships_data.csv")

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

# Write out parquet versions --------------------------------------------------
arrow::write_dataset(national_provider_summary, "data/",
  format = "parquet",
  basename_template = "national_provider_summary_{i}.parquet"
)

arrow::write_dataset(apps_chars, "data/",
  format = "parquet",
  basename_template = "apprenticeships_demographics_{i}.parquet"
)

arrow::write_dataset(apps_data, "data/",
  format = "parquet",
  basename_template = "apprenticeships_data_{i}.parquet"
)

arrow::write_dataset(lad_map_data, "data/",
  format = "parquet",
  basename_template = "lad_map_data_{i}.parquet"
)
