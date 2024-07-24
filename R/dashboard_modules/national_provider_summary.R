national_provider_summary_ui <- function(id) {
  div(
    # Tab header ================================================================
    h1("National provider summary"),

    # User selection area =====================================================
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectInput(
          inputId = NS(id, "provider"),
          label = "Search for provider",
          choices = provider_choices,
          selectize = TRUE
        ), # Look at swapping this out for a crosstalk filter search
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = year_choices,
          selectize = TRUE
        ),
        selectInput(
          inputId = NS(id, "characteristic"),
          label = "Select learner characteristic",
          choices = characteristic_choices,
          selectize = TRUE
        )
      )
    ),

    # Main table ==============================================================
    suppressWarnings(navset_card_tab( # supress due to bug
      id = "provider_table_tabs",
      ## Table tab ------------------------------------------------------------
      nav_panel(
        "Table",
        reactable::reactableOutput(NS(id, "nps_table"))
      ),
      ## Download tab ---------------------------------------------------------
      nav_panel(
        "Download data",
        shinyGovstyle::radio_button_Input(
          inputId = NS(id, "download_radios"),
          choices = c("CSV (20 MB)", "XSLX (18 MB)", "JSON (30 MB)"),
          label = h2("Choose download file format")
        ),
        # Bit of a hack to force the button not to be full width
        layout_columns(
          col_widths = 3,
          downloadButton(
            NS(id, "download_data"),
            label = "Download data",
            class = "gov-uk-button",
            icon = NULL
          )
        )
      ),
      ## Footer ---------------------------------------------------------------
      card_footer(
        style = "font-size: 16px; background: #f7f7f7;",
        "The Index of Multiple deprivation (IMD) is a measure of relative deprivation. The IMD shown here has been
        split into quintiles, with a value of one indicating the 20% most deprived neighbourhoods and five the 20%
        least deprived. IMD is derived from the learner postcode recorded on the Individualised Learner Record."
      )
    ))
  )
}

national_provider_summary_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Dropdowns ===============================================================
    # updateSelectizeInput(
    #   session,
    #   inputId = "provider",
    #   choices = provider_choices,
    #   selected = NULL,
    #   server = TRUE
    #   )


    # Reactive data set =======================================================
    nps_reactive_table <- reactive({
      nps_parquet %>%
        filter(`Academic Year` == input$year) %>%
        filter(`Learner characteristic` == input$characteristic) %>%
        # filter(`Provider name` == input$provider) %>%
        collect()
    })

    # Table ===================================================================
    output$nps_table <- renderReactable({
      dfe_reactable(nps_reactive_table())
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      filename = function() {
        paste0(input$year, "-", input$characteristic, "-national_provider_summary.csv")
      },
      content = function(file) {
        write.csv(nps_reactive_table(), file, row.names = FALSE)
      }
    )
  })
}
