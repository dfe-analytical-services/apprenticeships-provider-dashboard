# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script where we provide code to read in the data file(s).
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

## National provider summary --------------------------------------------------
# Note that this does a 'lazy read', you need to use `%>% collect()` to pull the final table into memory
nps_parquet <- arrow::read_parquet("data/national_provider_summary_0.parquet") %>%
  select(-c(`order_ref`, `order_detailed`))

### Lists of options use in the dropdowns -------------------------------------
nps_provider_choices <- nps_parquet %>%
  distinct(`Provider name`) %>%
  collect() %>%
  pull()

nps_year_choices <- nps_parquet %>%
  distinct(`Academic Year`) %>%
  collect() %>%
  pull()

nps_characteristic_choices <- nps_parquet %>%
  distinct(`Learner characteristic`) %>%
  collect() %>%
  pull()
