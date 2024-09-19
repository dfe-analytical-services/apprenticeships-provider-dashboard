# Start an app running ========================================================
app <- AppDriver$new(
  name = "nps",
  expect_values_screenshot_args = FALSE
)

# Navigate to page we're testing
app$click("national_provider_summary")

app$wait_for_idle(200)

# Run tests ===================================================================
test_that("NPS: Page loads", {
  # Test the table renders
  app$wait_for_value(output = "nps-nps_table")
  app$wait_for_idle(50)
  expect_gt(check_reactable_rows("nps-nps_table", app), 0)

  # Test the download works
  app$set_inputs(provider_table_tabs = "Download data")
  app$wait_for_idle(50)
  download_info <- app$get_download("nps-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "allproviders-allyears-allcharacteristics-provider_summary.csv")

  # Go back to main tab
  app$set_inputs(provider_table_tabs = "Table")
})

test_that("NPS: Can change all the dropdowns", {
  app$set_inputs(
    `nps-provider` = "DARLINGTON COLLEGE",
    `nps-year` = "2021/22",
    `nps-characteristic` = "Sex - Male"
  )

  # Test the table renders
  app$wait_for_value(output = "nps-nps_table")
  expect_gt(check_reactable_rows("nps-nps_table", app), 0)

  # Test the download works
  app$set_inputs(provider_table_tabs = "Download data")
  app$wait_for_idle(50)
  download_info <- app$get_download("nps-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "darlingtoncollege-2021_22-sex-male-provider_summary.csv")

  # Go back to main tab
  app$set_inputs(provider_table_tabs = "Table")
})

test_that("File type radio button changes to XLSX download", {
  # Go to download tab
  app$set_inputs(provider_table_tabs = "Download data")

  # Change to XLSX download and test it works
  app$set_inputs(`nps-file_type` = "XLSX (Up to 1.75 MB)")
  app$wait_for_idle(50)
  download_info <- app$get_download("nps-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "darlingtoncollege-2021_22-sex-male-provider_summary.xlsx")
})
