# -----------------------------------------------------------------------------
# This is an example UI test file
# It includes a basic test to check that the app loads without error
#
# We recommend keeping this test
#
# Update it to match the expected title of the app and always make sure it is
# passing before merging any new code in
#
# This should prevent your app from ever failing to start up on the servers
# -----------------------------------------------------------------------------
# Start an app running
app <- AppDriver$new(
  name = "basic_load",
  height = 846,
  width = 1445,
  load_timeout = 45 * 1000,
  timeout = 20 * 1000,
  wait = TRUE,
  expect_values_screenshot_args = FALSE # Turn off as we don't need screenshots
)

# Wait until Shiny is not busy for 5ms so we know any processes are complete
app$wait_for_idle(5)

# Test that the app will start up without error and the app title is as expected
test_that("App loads and title of app appears as expected", {
  # This matches the title as set in the ui.R script
  expect_equal(app$get_text("title")[1], "Apprenticeships provider dashboard")
})
