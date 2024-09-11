# Run checks ==================================================================
# Start an app running
app <- AppDriver$new(
  name = "subjects_and_standards",
  expect_values_screenshot_args = FALSE
)

# Then run tests against it
test_that("SAS: page loads", {
  # Navigate to page we're testing
  app$click("subjects_and_standards")

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Starts for providers across all subject areas"
  )
})

test_that("SAS: a single provider can be selected", {
  app$set_inputs(`sas-provider` = "Nottingham College")

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Starts for providers across all subject areas"
  )
})

test_that("SAS: multiple providers can be selected", {
  app$set_inputs(`sas-provider` = c(
    "Nottingham College", "Tyne Coast College", "Coventry College",
    "The Fernandes And Rosario Consulting Limited"
  ))

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Starts for providers across all subject areas"
  )
})

test_that("SAS: measure change to Enrolments", {
  app$set_inputs(`sas-measure` = "Enrolments")

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Enrolments for providers across all subject areas"
  )
})

test_that("SAS: measure change to Achievements", {
  app$set_inputs(`sas-measure` = "Achievements")

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Achievements for providers across all subject areas"
  )
})

test_that("SAS: year change to 2022/23", {
  app$set_inputs(`sas-year` = "2022/23")

  app$wait_for_idle(50)

  # Test the tables render with at least one row of data
  app$wait_for_value(output = "sas-sas_provider_table")
  expect_gt(check_reactable_rows("sas-sas_provider_table", app), 0)

  app$wait_for_value(output = "sas-sas_subject_area_table")
  expect_gt(check_reactable_rows("sas-sas_subject_area_table", app), 0)

  # Test the chart renders and produces a visual
  app$wait_for_value(output = "sas-subject_area_bar")
  expect_true(check_ggiraph_rendered("sas-subject_area_bar", app))

  # Check table title is what we expect
  expect_equal(
    get_reactive_text("sas-sas_provider_table_title", app),
    "Achievements for providers across all subject areas"
  )
})
