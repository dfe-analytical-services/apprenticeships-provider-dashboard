# Start an app running
app <- AppDriver$new(
  name = "example_tab_1",
  height = 846,
  width = 1445,
  load_timeout = 45 * 1000,
  timeout = 20 * 1000,
  wait = TRUE,
  expect_values_screenshot_args = FALSE
)

app$wait_for_idle(5)

# These match what is set in the ui.R file for the different panels
test_that("Tab titles load when switching", {
  expect_equal(app$get_text("h1")[1], "Overall content title for this dashboard page")

  # Something like this app$set_inputs(navPanel = "?")
})
