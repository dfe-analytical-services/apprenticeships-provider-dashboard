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

# Load data ===================================================================

## LAD ------------------------------------------------------------------------
# Note that this does a 'lazy read', you need to use `%>% collect()` to pull the final table into memory
read_lad <- function(file_path) {
  arrow::read_parquet(file_path)
}

read_lad_map <- function(file_path) {
  readRDS(file_path)
}

## Subjects and standards -----------------------------------------------------
# Note that this does a 'lazy read', you need to use `%>% collect()` to pull the final table into memory
read_sas <- function(file_path) {
  arrow::read_parquet(file_path) %>%
    summarise(
      starts = sum(starts),
      enrolments = sum(enrolments),
      achievements = sum(achievements),
      .by = c(
        "year", "apps_Level", "std_fwk_name", "ssa_t1_desc",
        "ssa_t2_desc", "std_fwk_flag", "provider_type", "provider_name"
      )
    ) %>%
    pivot_longer(
      c("starts", "enrolments", "achievements"),
      names_to = "measure",
      values_to = "values"
    ) %>%
    mutate(
      provider_name = str_to_title(provider_name),
      measure = str_to_sentence(measure)
    )
}

## Demographics / characteristics summary -------------------------------------
# Note that this does a 'lazy read', you need to use `%>% collect()` to pull the final table into memory
read_chars <- function(file_path) {
  arrow::read_parquet(file_path)
}

## National provider summary --------------------------------------------------
# Note that this does a 'lazy read', you need to use `%>% collect()` to pull the final table into memory
read_nps <- function(file_path) {
  arrow::read_parquet(file_path) %>%
    select(-c(`order_ref`, `order_detailed`)) # unused columns
}

# Create options lists for use in the dropdowns ===============================
data_choices <- function(data, column) {
  data %>%
    distinct(!!sym(column)) %>% # adding the !!sym() to convert string to column name
    collect() %>%
    pull()
}
