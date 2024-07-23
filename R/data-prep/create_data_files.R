# Using this script to test the data files for the app
#
# Ideally would want to amend the current queries to save the tables in SQL ready to read in
#
# Dependencies ----------------------------------------------------------------
library(data.table)
library(arrow)
library(dplyr)

# Read in files saved from SQL scripts ----------------------------------------
national_provider_summary <- data.table::fread("data/national_provider_summary.csv")
apprenticeships_demographics <- data.table::fread("data/apprenticeships_demographics.csv")
apprenticeships_data <- data.table::fread("data/apprenticeships_data.csv")

# Write out parquet versions
arrow::write_dataset(national_provider_summary, "data/",
  format = "parquet",
  basename_template = "national_provider_summary_{i}.parquet"
)

arrow::write_dataset(apprenticeships_demographics, "data/",
  format = "parquet",
  basename_template = "apprenticeships_demographics_{i}.parquet"
)

arrow::write_dataset(apprenticeships_data, "data/",
  format = "parquet",
  basename_template = "apprenticeships_data_{i}.parquet"
)

read_parquet_lazy <- function() {
  national_provider_summary_pqt <- arrow::read_parquet("data/national_provider_summary_0.parquet")
  apprenticeships_demographics_pqt <- arrow::read_parquet("data/apprenticeships_demographics_0.parquet")
  apprenticeships_data_pqt <- arrow::read_parquet("data/apprenticeships_data_0.parquet")
}
