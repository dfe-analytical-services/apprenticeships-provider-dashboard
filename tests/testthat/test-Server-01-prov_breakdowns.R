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
test_data <- arrow::read_parquet("../../data/provider_breakdowns_0.parquet")

# Test the server file  =======================================================
shiny::testServer(prov_breakdowns_server, expr = {
  # 1. Check the reactive data is not being pre-filtered at first -------------
  # Give the inputs expected on initial load
  session$setInputs(
    prov_type = "All provider types",
    year = "2021/22",
    level = "All levels",
    age = "All age groups"
  )

  expect_equal(
    filtered_raw_data(),
    test_data %>% filter(year == "2021/22") %>% collect()
  )

  # 2. Check the reactive data is being filtered as expected ------------------
  # Change to a different dropdown selection
  session$setInputs(
    prov_type = "Private Sector Public Funded",
    year = "2022/23",
    level = "Higher Apprenticeship",
    age = "Under 19"
  )

  # 3. Compare the reactive table with a hardcoded filter against the test data
  expect_equal(
    filtered_raw_data(),
    test_data %>%
      filter(
        provider_type == "Private Sector Public Funded",
        year == "2022/23",
        apps_Level == "Higher Apprenticeship",
        age_group == "Under 19"
      ) %>%
      collect()
  )
})
