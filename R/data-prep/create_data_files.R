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
