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
  as.data.frame()


# Write out parquet versions --------------------------------------------------
arrow::write_dataset(national_provider_summary, "data/",
  format = "parquet",
  basename_template = "national_provider_summary_{i}.parquet"
)

arrow::write_dataset(apps_demographics, "data/",
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

################ TO DE;ETE #######################################################

## Create cut down version of apps data ----

# Making a data frame with LAD rows that we can join the boundary polygons on to
# Assuming that LADs are same for learner home and delivery
# Can check using: waldo::compare(distinct(apps_data, year, delivery_lad), distinct(apps_data, year, learner_home_lad))
available_lads <- apps_data %>%
  distinct(year, delivery_lad) %>%
  rename("lad_name" = delivery_lad)

# Aggregate delivery and learner home numbers to LAD level ----
lad_delivery_data <- apps_data %>%
  group_by(year, delivery_lad) %>%
  summarise(
    starts = sum(starts, na.rm = TRUE),
    enrolments = sum(enrolments, na.rm = TRUE),
    achievements = sum(achievements, na.rm = TRUE)
  )

lad_learner_home_data <- apps_data %>%
  group_by(year, learner_home_lad) %>%
  dplyr::summarise(
    starts = sum(starts, na.rm = TRUE),
    enrolments = sum(enrolments, na.rm = TRUE),
    achievements = sum(achievements, na.rm = TRUE)
  )

# Create a data set per year to join the boundary files onto ----
lad_map_data_2024 <- available_lads %>%
  filter(year == "2023/24 (Q3 Aug to Apr)") %>%
  left_join(lad_delivery_data, by = join_by("lad_name" == "delivery_lad", "year" == "year")) %>%
  left_join(
    lad_learner_home_data,
    by = join_by("lad_name" == "learner_home_lad", "year" == "year"),
    suffix = c("_delivery", "_learner") # differentiate the metric cols for delivery and learner home
  ) %>%
  pivot_longer(
    cols = c(
      "starts_delivery", "enrolments_delivery", "achievements_delivery",
      "starts_learner", "enrolments_learner", "achievements_learner"
    ),
    names_to = c(".value", "lad_type"),
    names_sep = "_"
  )

lad_map_data_2023 <- available_lads %>%
  filter(year == "2022/23") %>%
  left_join(lad_delivery_data, by = join_by("lad_name" == "delivery_lad", "year" == "year")) %>%
  left_join(
    lad_learner_home_data,
    by = join_by("lad_name" == "learner_home_lad", "year" == "year"),
    suffix = c("_delivery", "_learner") # differentiate the metric cols for delivery and learner home
  ) %>%
  pivot_longer(
    cols = c(
      "starts_delivery", "enrolments_delivery", "achievements_delivery",
      "starts_learner", "enrolments_learner", "achievements_learner"
    ),
    names_to = c(".value", "lad_type"),
    names_sep = "_"
  )

lad_map_data_2022 <- available_lads %>%
  filter(year == "2021/22") %>%
  left_join(lad_delivery_data, by = join_by("lad_name" == "delivery_lad", "year" == "year")) %>%
  left_join(
    lad_learner_home_data,
    by = join_by("lad_name" == "learner_home_lad", "year" == "year"),
    suffix = c("_delivery", "_learner") # differentiate the metric cols for delivery and learner home
  ) %>%
  pivot_longer(
    cols = c(
      "starts_delivery", "enrolments_delivery", "achievements_delivery",
      "starts_learner", "enrolments_learner", "achievements_learner"
    ),
    names_to = c(".value", "lad_type"),
    names_sep = "_"
  )


## Stack the years back together ----
lad_map_data <- rbind(
  lad_map_data_2022,
  lad_map_data_2023,
  lad_map_data_2024
)

# As this is geospatial data we're saving as RDS to preserve the format
saveRDS(lad_map_data, "data/lad_maps.RDS")
