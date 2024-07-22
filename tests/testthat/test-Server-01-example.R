# -----------------------------------------------------------------------------
# This is an example integration test file
#
# Integration tests in Shiny allow you to test the server.R reactivity without
# needing to load a full app and interact with the UI.
#
# This makes integration tests faster to run than UI tests and makes them a
# more efficient alternative if you don't need to interact with the UI to test
# what you want to.
#
# These examples show some ways you can make use of integration tests.
#
# Add more scripts and checks as appropriate for your app.
# -----------------------------------------------------------------------------

# Test the server file --------------------------------------------------------
testServer(expr = {
  # Placeholder test for now
  expect_equal(2, 2)
})
