# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script where we provide code to read in the data file(s).
#
# We create functions in this script then reuse elsewhere in the code explicitly
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
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create options lists for use in the dropdowns ===============================
data_choices <- function(data, column) {
  data %>%
    distinct(!!sym(column)) %>% # adding the !!sym() to convert string to column name
    collect() %>%
    pull()
}

# Load data ===================================================================
# Note that all of these that read a parquet file do a 'lazy read'
# you will need to use `%>% collect()` to pull the final table into memory

## Provider breakdowns --------------------------------------------------------
read_prov_breakdowns <- function(file_path) {
  arrow::read_parquet(file_path)
}

## LAD ------------------------------------------------------------------------
read_lad <- function(file_path) {
  arrow::read_parquet(file_path) %>%
    select(year, provider_name, learner_home_lad, delivery_lad, starts, achievements, enrolments)
}

read_lad_map <- function(file_path) {
  readRDS(file_path)
}

## Subjects and standards -----------------------------------------------------
read_sas <- function(file_path) {
  arrow::read_parquet(file_path)
}

## Demographics / characteristics summary -------------------------------------
read_chars <- function(file_path) {
  arrow::read_parquet(file_path)
}

## National provider summary --------------------------------------------------
read_nps <- function(file_path) {
  arrow::read_parquet(file_path) %>%
    select(-c(`order_ref`, `order_detailed`)) # unused columns
}
