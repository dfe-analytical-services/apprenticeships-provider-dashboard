# Start an app running ========================================================
app <- AppDriver$new(
  name = "local_authority_district",
  expect_values_screenshot_args = FALSE
)

# Navigate to page we're testing
app$click("local_authority_district")

app$wait_for_idle(200)

# Then run tests against it ===================================================
test_that("LAD page loads", {
  # Test the provider table renders
  app$wait_for_value(output = "lad-prov_selection_table")
  expect_gt(check_reactable_rows("lad-prov_selection_table", app), 0)

  # Test the maps render something
  app$wait_for_value(output = "lad-delivery_lad_map")
  expect_true(check_plot_rendered("lad-delivery_lad_map", app))

  app$wait_for_value(output = "lad-learner_home_lad_map")
  expect_true(check_plot_rendered("lad-learner_home_lad_map", app))

  # Test the LAD tables render
  app$set_inputs(lad_maps_tabs = "Tables")

  app$wait_for_value(output = "lad-delivery_lad_table")
  expect_gt(check_reactable_rows("lad-delivery_lad_table", app), 0)

  app$wait_for_value(output = "lad-learner_home_lad_table")
  expect_gt(check_reactable_rows("lad-learner_home_lad_table", app), 0)

  # Test we can download data
  app$set_inputs(lad_maps_tabs = "Download data")

  app$wait_for_idle(50)
  download_info <- app$get_download("lad-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "lad-2023_24(q3augtoapr)-starts.csv")

  # Return to maps tab
  app$set_inputs(lad_maps_tabs = "Maps")
})

test_that("Can make a provider selection", {
  # Set inputs
  app$set_inputs(`lad-measure` = "Enrolments")
  app$set_inputs(`lad-year` = "2022/23")
  app$set_inputs(`lad-provider` = "1ST2 ACHIEVE TRAINING LIMITED")

  app$wait_for_idle(50)

  # Test the provider table renders
  app$wait_for_value(output = "lad-prov_selection_table")
  expect_gt(check_reactable_rows("lad-prov_selection_table", app), 0)

  # Test the maps render something
  app$wait_for_value(output = "lad-delivery_lad_map")
  expect_true(check_plot_rendered("lad-delivery_lad_map", app))

  app$wait_for_value(output = "lad-learner_home_lad_map")
  expect_true(check_plot_rendered("lad-learner_home_lad_map", app))

  # Test the LAD tables render
  app$set_inputs(lad_maps_tabs = "Tables")

  app$wait_for_value(output = "lad-delivery_lad_table")
  expect_gt(check_reactable_rows("lad-delivery_lad_table", app), 0)

  app$wait_for_value(output = "lad-learner_home_lad_table")
  expect_gt(check_reactable_rows("lad-learner_home_lad_table", app), 0)

  # Test we can download data
  app$set_inputs(lad_maps_tabs = "Download data")

  app$wait_for_idle(50)
  download_info <- app$get_download("lad-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "lad-2022_23-enrolments.csv")

  # Return to maps tab
  app$set_inputs(lad_maps_tabs = "Maps")
})

test_that("Can make delivery LAD selection", {
  app$set_inputs(`lad-delivery_lad` = "Norwich")

  app$wait_for_idle(50)

  # Check the provider selection has cleared
  expect_equal(
    app$get_values(input = "lad-provider")[[1]][[1]],
    ""
  )

  # Test the provider table renders
  app$wait_for_value(output = "lad-prov_selection_table")
  expect_gt(check_reactable_rows("lad-prov_selection_table", app), 0)

  # Test the maps render something
  app$wait_for_value(output = "lad-delivery_lad_map")
  expect_true(check_plot_rendered("lad-delivery_lad_map", app))

  app$wait_for_value(output = "lad-learner_home_lad_map")
  expect_true(check_plot_rendered("lad-learner_home_lad_map", app))

  # Test the LAD tables render
  app$set_inputs(lad_maps_tabs = "Tables")

  app$wait_for_value(output = "lad-delivery_lad_table")
  expect_gt(check_reactable_rows("lad-delivery_lad_table", app), 0)

  app$wait_for_value(output = "lad-learner_home_lad_table")
  expect_gt(check_reactable_rows("lad-learner_home_lad_table", app), 0)

  # Test we can download data
  app$set_inputs(lad_maps_tabs = "Download data")

  app$wait_for_idle(50)
  download_info <- app$get_download("lad-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "lad-2022_23-enrolments.csv")

  # Return to maps tab
  app$set_inputs(lad_maps_tabs = "Maps")
})

test_that("Can make learner home lad selection", {
  app$set_inputs(`lad-learner_home_lad` = "East Cambridgeshire")

  app$wait_for_idle(50)

  # Check the delivery lad selection has cleared
  expect_equal(
    app$get_values(input = "lad-delivery_lad")[[1]][[1]],
    ""
  )

  # Test the provider table renders
  app$wait_for_value(output = "lad-prov_selection_table")
  expect_gt(check_reactable_rows("lad-prov_selection_table", app), 0)

  # Test the maps render something
  app$wait_for_value(output = "lad-delivery_lad_map")
  expect_true(check_plot_rendered("lad-delivery_lad_map", app))

  app$wait_for_value(output = "lad-learner_home_lad_map")
  expect_true(check_plot_rendered("lad-learner_home_lad_map", app))

  # Test the LAD tables render
  app$set_inputs(lad_maps_tabs = "Tables")

  app$wait_for_value(output = "lad-delivery_lad_table")
  expect_gt(check_reactable_rows("lad-delivery_lad_table", app), 0)

  app$wait_for_value(output = "lad-learner_home_lad_table")
  expect_gt(check_reactable_rows("lad-learner_home_lad_table", app), 0)

  # Test we can download data
  app$set_inputs(lad_maps_tabs = "Download data")

  app$wait_for_idle(50)
  download_info <- app$get_download("lad-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "lad-2022_23-enrolments.csv")
})

test_that("File type radio button changes to XLSX download", {
  # Go to download tab
  app$set_inputs(lad_maps_tabs = "Download data")

  # Change to XLSX download and test it works
  app$set_inputs(`lad-file_type` = "XLSX (Up to 5.92 MB)")
  app$wait_for_idle(50)
  download_info <- app$get_download("lad-download_data")
  app$wait_for_idle(50)
  expect_equal(basename(download_info), "lad-2022_23-enrolments.xlsx")
})
