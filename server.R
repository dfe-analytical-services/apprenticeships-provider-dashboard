# -----------------------------------------------------------------------------
# This is the server file.
#
# Use it to create interactive elements like tables, charts and text for your
# app.
#
# Anything you create in the server file won't appear in your app until you call
# it in the UI file. This server script gives examples of plots and value boxes
#
# There are many other elements you can add in too, and you can play around with
# their reactivity. The "outputs" section of the shiny cheatsheet has a few
# examples of render calls you can use:
# https://shiny.rstudio.com/images/shiny-cheatsheet.pdf
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# -----------------------------------------------------------------------------
server <- function(input, output, session) {
  # Page navigation ------------------------------------------------------------
  observeEvent(input$dashboard, {
    nav_select("pages", "dashboard")
  })

  observeEvent(input$accessibility, {
    nav_select("pages", "accessibility")
  })

  observeEvent(input$cookies, {
    nav_select("pages", "cookies")
  })

  # Main content left navigation ----------------------------------------------
  observeEvent(input$example_panel, {
    nav_select("left_nav", "example_panel")
  })

  observeEvent(input$user_guide, {
    nav_select("left_nav", "user_guide")
  })

  observeEvent(input$footnotes, {
    nav_select("left_nav", "footnotes")
  })

  observeEvent(input$support, {
    nav_select("left_nav", "support")
  })

  # Back links to main dashboard ----------------------------------------------
  observeEvent(input$cookies_to_dashboard, {
    nav_select("pages", "dashboard")
  })

  observeEvent(input$accessibility_to_dashboard, {
    nav_select("pages", "dashboard")
  })

  # Stop app ------------------------------------------------------------------
  session$onSessionEnded(function() {
    stopApp()
  })
}
