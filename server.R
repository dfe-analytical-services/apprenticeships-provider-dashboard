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
  # Navigation ================================================================
  # Footer links --------------------------------------------------------------
  observeEvent(input$dashboard, nav_select("pages", "dashboard"))
  observeEvent(input$footnotes, nav_select("pages", "footnotes"))
  observeEvent(input$support, nav_select("pages", "support"))
  observeEvent(input$accessibility, nav_select("pages", "accessibility"))
  observeEvent(input$cookies, nav_select("pages", "cookies"))

  # Main content left navigation ----------------------------------------------
  observeEvent(input$provider_breakdowns, nav_select("left_nav", "provider_breakdowns"))
  observeEvent(input$local_authority_district, nav_select("left_nav", "local_authority_district"))
  observeEvent(input$subjects_and_standards, nav_select("left_nav", "subjects_and_standards"))
  observeEvent(input$learner_characteristics, nav_select("left_nav", "learner_characteristics"))
  observeEvent(input$national_provider_summary, nav_select("left_nav", "national_provider_summary"))
  observeEvent(input$user_guide, nav_select("left_nav", "user_guide"))

  # Back links to main dashboard ----------------------------------------------
  observeEvent(input$footnotes_to_dashboard, nav_select("pages", "dashboard"))
  observeEvent(input$support_to_dashboard, nav_select("pages", "dashboard"))
  observeEvent(input$cookies_to_dashboard, nav_select("pages", "dashboard"))
  observeEvent(input$accessibility_to_dashboard, nav_select("pages", "dashboard"))

  # Provider summary selections ===============================================
  # updateSelectizeInput(
  #   session,
  #   inputId = "provider",
  #   choices = provider_choices,
  #   selected = NULL,
  #   server = TRUE
  #   )

  # Provider summary table ====================================================
  nps_reactive_table <- reactive({
    nps_parquet %>%
      filter(`Academic Year` == input$year) %>%
      filter(`Learner characteristic` == input$characteristic) %>%
      # filter(`Provider name` == input$provider) %>%
      collect()
  })

  output$nps_table <- renderReactable({
    reactable(
      nps_reactive_table(),
      highlight = TRUE,
      borderless = TRUE,
      showSortIcon = FALSE,
      style = list(fontSize = "16px")
    )
  })

  # Provider summary download =================================================
  output$download_data <- downloadHandler(
    filename = function() {
      paste0(input$year, "-", input$characteristic, "-national_provider_summary.csv")
    },
    content = function(file) {
      write.csv(nps_reactive_table(), file, row.names = FALSE)
    }
  )

  # Stop app when tab closes ==================================================
  session$onSessionEnded(function() {
    stopApp()
  })
}
