# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is an example integration test file
#
# Integration tests in Shiny allow you to test the server.R reactivity without
# needing to load a full app and interact with the UI.
#
# This makes integration tests faster to run than UI tests and makes them a
# more efficient alternative if you don't need to interact with the UI to test
# what you want to.
#
# These examples show some ways you can make use of integration tests.
#
# Add more scripts and checks as appropriate for your app.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Read in the data to test against
source("../../R/read_data.R")
test_data <- read_nps("../../data/national_provider_summary_0.parquet")

# Test the server file  =======================================================
shiny::testServer(nps_server, expr = {
  # 1. Check the reactive data is not being pre-filtered at first -------------
  # Give the inputs expected on initial load
  session$setInputs(
    provider = "All providers",
    year = "All years",
    characteristic = "All characteristics"
  )

  expect_equal(nps_reactive_table(), test_data %>% collect())

  # 2. Check the reactive data is being filtered as expected ------------------
  # Change to a different dropdown selection
  session$setInputs(
    provider = "DARLINGTON COLLEGE",
    year = "2021/22",
    characteristic = "Sex - Male"
  )

  # 3. Compare the reactive table with a hardcoded filter
  expect_equal(
    nps_reactive_table(),
    test_data %>%
      filter(
        `Provider name` == "DARLINGTON COLLEGE",
        `Academic Year` == "2021/22",
        `Learner characteristic` == "Sex - Male"
      ) %>%
      collect()
  )
})
