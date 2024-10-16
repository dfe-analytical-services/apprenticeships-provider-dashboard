# Start an app running ========================================================
app <- AppDriver$new(
  name = "basic_load_nav",
  expect_values_screenshot_args = FALSE,
  load_timeout = 30 * 1000, # set to 30seconds, default is 15
)

# Test that the app will start up without error and the app title is as expected
test_that("App loads and title of app appears as expected", {
  # This matches the title as set in the global.R script
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})

# Title updates when changing tabs ============================================
test_that("Tab titles load when switching", {
  app$click("local_authority_district")
  app$wait_for_idle(1000) # This can be particularly slow sometimes
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - local authority district")

  app$click("subjects_and_standards")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - subjects and standards")

  app$click("learner_characteristics")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - learner characteristics")

  app$click("national_provider_summary")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - national provider summary")

  app$click("user_guide")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - user guide")

  app$click("provider_breakdowns")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})

# Footer links and backlinks work =============================================
test_that("Footer link and back links work", {
  app$click("footnotes")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - footnotes")

  app$click("footnotes_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("support")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - support")

  app$click("support_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("accessibility_statement")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - accessibility statement")

  app$click("accessibility_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("cookies")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - cookies")

  app$click("cookies_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})

# Check no console errors have occurred =======================================
test_that("There are no errors in the whole app", {
  # This is giving false positives in GitHub actions so commenting out for now - expect_null(app$get_html(".shiny-output-error"))
  expect_null(app$get_html(".shiny-output-error-validation"))
})
