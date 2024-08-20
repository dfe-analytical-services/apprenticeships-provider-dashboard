# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is an example UI test file
# It includes a basic test to check that the app loads without error
#
# We recommend keeping this test
#
# Update it to match the expected title of the app and always make sure it is
# passing before merging any new code in
#
# This should prevent your app from ever failing to start up on the servers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Start an app running ========================================================
app <- AppDriver$new(
  name = "basic_load_nav",
  load_timeout = 45 * 1000,
  timeout = 20 * 1000,
  wait = TRUE,
  expect_values_screenshot_args = FALSE # Turn off as we don't need screenshots
)

# Test that the app will start up without error and the app title is as expected
test_that("App loads and title of app appears as expected", {
  # This matches the title as set in the global.R script
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})

# Title updates when changing tabs ============================================
test_that("Tab titles load when switching", {
  app$click("local_authority_district")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - local authority district")

  app$click("subjects_and_standards")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - subjects and standards")

  app$click("learner_characteristics")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - learner characteristics")

  app$click("national_provider_summary")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - national provider summary")

  app$click("user_guide")
  app$wait_for_idle(50)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - user guide")

  app$click("provider_breakdowns")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})

# Footer links and backlinks work =============================================
test_that("Footer link and back links work", {
  app$click("footnotes")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - footnotes")
  app$click("footnotes_to_dashboard")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("support")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - support")
  app$click("support_to_dashboard")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("accessibility_statement")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - accessibility statement")
  app$click("accessibility_to_dashboard")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  app$click("cookies")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - cookies")
  app$click("cookies_to_dashboard")
  app$wait_for_idle(5)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")
})
