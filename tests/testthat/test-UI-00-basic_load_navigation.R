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

  print("Page 1")
  print(app$get_html(".shiny-output-error"))
})

# Title updates when changing tabs ============================================
test_that("Tab titles load when switching", {
  app$click("local_authority_district")
  app$wait_for_idle(1000) # This can be particularly slow sometimes
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - local authority district")

  print("Page 2")
  print(app$get_html(".shiny-output-error"))

  app$click("subjects_and_standards")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - subjects and standards")

  print("Page 3")
  print(app$get_html(".shiny-output-error"))

  app$click("learner_characteristics")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - learner characteristics")

  print("Page 4")
  print(app$get_html(".shiny-output-error"))

  app$click("national_provider_summary")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - national provider summary")

  print("Page 5")
  print(app$get_html(".shiny-output-error"))

  app$click("user_guide")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - user guide")

  print("User guide")
  print(app$get_html(".shiny-output-error"))

  app$click("provider_breakdowns")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  print("Back to page 1")
  print(app$get_html(".shiny-output-error"))
})

# Footer links and backlinks work =============================================
test_that("Footer link and back links work", {
  app$click("footnotes")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - footnotes")

  print("Footnotes")
  print(app$get_html(".shiny-output-error"))

  app$click("footnotes_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  print("Back to page 1")
  print(app$get_html(".shiny-output-error"))

  app$click("support")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - support")

  print("Support")
  print(app$get_html(".shiny-output-error"))

  app$click("support_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  print("Back to page 1")
  print(app$get_html(".shiny-output-error"))

  app$click("accessibility_statement")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - accessibility statement")

  print("Accessibility")
  print(app$get_html(".shiny-output-error"))

  app$click("accessibility_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  print("Back to page 1")
  print(app$get_html(".shiny-output-error"))

  app$click("cookies")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - cookies")

  print("Cookies")
  print(app$get_html(".shiny-output-error"))

  app$click("cookies_to_dashboard")
  app$wait_for_idle(1000)
  expect_equal(app$get_text("title"), "Apprenticeships provider dashboard - provider breakdowns")

  print("Back to page 1")
  print(app$get_html(".shiny-output-error"))
})

# Check no console errors have occurred =======================================
test_that("There are no errors in the whole app", {
  expect_null(app$get_html(".shiny-output-error"))
  expect_null(app$get_html(".shiny-output-error-validation"))
})
