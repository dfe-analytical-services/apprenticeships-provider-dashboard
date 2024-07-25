# Start an app running ========================================================
app <- AppDriver$new(
  name = "nps",
  load_timeout = 45 * 1000,
  timeout = 20 * 1000,
  expect_values_screenshot_args = FALSE
)

# Test download ===============================================================
app$set_inputs(left_nav = "national_provider_summary")
app$set_inputs(provider_table_tabs = "Download data")

test_that("Default download gives expected name", {
  download_info <- app$get_download("nps-download_data")
  expect_equal(basename(download_info), "allproviders-allyears-allcharacteristics-provider_summary.csv")
})

# File name changes based on inputs -------------------------------------------
test_that("Filename reacts to dropdowns", {
  app$set_inputs(
    `nps-provider` = "DARLINGTON COLLEGE",
    `nps-year` = "2021/22",
    `nps-characteristic` = "Sex - Male"
  )

  download_info <- app$get_download("nps-download_data")
  expect_equal(basename(download_info), "darlingtoncollege-2021_22-sex-male-provider_summary.csv")
})

# Try changing radio option ---------------------------------------------------
test_that("File type radio button changes to XLSX download", {
  app$set_inputs(`nps-file_type` = "XLSX (Up to 1.76 MB)")
  download_info <- app$get_download("nps-download_data")
  expect_equal(basename(download_info), "darlingtoncollege-2021_22-sex-male-provider_summary.xlsx")
})
