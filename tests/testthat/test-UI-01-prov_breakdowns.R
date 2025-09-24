# Start an app running ========================================================
app <- AppDriver$new(
  name = "provider_breakdowns",
  expect_values_screenshot_args = FALSE,
  load_timeout = 120 * 1000, # set to 30seconds, default is 15
)

# Navigate to page we're testing
app$click("provider_breakdowns")

app$wait_for_idle(200)

# Then run tests against it ===================================================
test_that("Prov breakdowns page loads", {
  # Test the tables render with at least one row of data
  app$wait_for_value(output = "prov_breakdowns-delivery_region")
  expect_gt(check_reactable_rows("prov_breakdowns-delivery_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-home_region")
  expect_gt(check_reactable_rows("prov_breakdowns-home_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-prov_selection")
  expect_gt(check_reactable_rows("prov_breakdowns-prov_selection", app), 0)
})

test_that("Make a provider selection", {
  # Select top provider
  app$set_inputs(`prov_breakdowns-prov_selection__reactable__selected` = 1, allow_no_input_binding_ = TRUE)

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "prov_breakdowns-delivery_region")
  expect_gt(check_reactable_rows("prov_breakdowns-delivery_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-home_region")
  expect_gt(check_reactable_rows("prov_breakdowns-home_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-prov_selection")
  expect_gt(check_reactable_rows("prov_breakdowns-prov_selection", app), 0)
})

test_that("Make a delivery region selection", {
  # Select second region row
  app$set_inputs(`prov_breakdowns-delivery_region__reactable__selected` = 2, allow_no_input_binding_ = TRUE)

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "prov_breakdowns-delivery_region")
  expect_gt(check_reactable_rows("prov_breakdowns-delivery_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-home_region")
  expect_gt(check_reactable_rows("prov_breakdowns-home_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-prov_selection")
  expect_gt(check_reactable_rows("prov_breakdowns-prov_selection", app), 0)
})

test_that("Make a learner home region selection", {
  # Select fifth region row
  app$set_inputs(`prov_breakdowns-learner_home_region__reactable__selected` = 5, allow_no_input_binding_ = TRUE)

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "prov_breakdowns-delivery_region")
  expect_gt(check_reactable_rows("prov_breakdowns-delivery_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-home_region")
  expect_gt(check_reactable_rows("prov_breakdowns-home_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-prov_selection")
  expect_gt(check_reactable_rows("prov_breakdowns-prov_selection", app), 0)
})

test_that("Can download data", {
  app$set_inputs(provider_breakdown_tabs = "Download data")
  app$wait_for_idle(50)
  download_info <- app$get_download("prov_breakdowns-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "2023_24(q3augtoapr)-alllevels-allagegroups-provider_breakdowns.csv")
})

test_that("Can change all dropdowms and tables still render", {
  app$set_inputs(`prov_breakdowns-measure` = "enrolments")
  app$set_inputs(`prov_breakdowns-prov_type` = "Private Sector Public Funded")
  app$set_inputs(`prov_breakdowns-year` = "2022/23")
  app$set_inputs(`prov_breakdowns-level` = "Higher Apprenticeship")
  app$set_inputs(`prov_breakdowns-age` = "Under 19")

  app$set_inputs(provider_breakdown_tabs = "Regions")
  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "prov_breakdowns-delivery_region")
  expect_gt(check_reactable_rows("prov_breakdowns-delivery_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-home_region")
  expect_gt(check_reactable_rows("prov_breakdowns-home_region", app), 0)

  app$wait_for_value(output = "prov_breakdowns-prov_selection")
  expect_gt(check_reactable_rows("prov_breakdowns-prov_selection", app), 0)
})

test_that("Can download data after changing dropdowns", {
  app$set_inputs(provider_breakdown_tabs = "Download data")
  app$wait_for_idle(50)
  download_info <- app$get_download("prov_breakdowns-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "2022_23-higherapprenticeship-under19-provider_breakdowns.csv")
})

test_that("File type radio button changes to XLSX download", {
  # Go to download tab
  app$set_inputs(provider_breakdown_tabs = "Download data")

  # Change to XLSX download and test it works
  app$set_inputs(`prov_breakdowns-file_type` = "XLSX (Up to X MB)")
  app$wait_for_idle(50)
  download_info <- app$get_download("prov_breakdowns-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "2022_23-higherapprenticeship-under19-provider_breakdowns.xlsx")
})
