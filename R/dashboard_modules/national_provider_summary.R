nps_ui <- function(id) {
  div(
    # Tab header ==============================================================
    h1("National provider summary"),

    # User selection area =====================================================
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectizeInput(
          inputId = NS(id, "provider"),
          label = NULL,
          choices = NULL
        ),
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = c("All years", year_choices)
        ),
        selectInput(
          inputId = NS(id, "characteristic"),
          label = "Select learner characteristic",
          choices = c("All characteristics", characteristic_choices)
        )
      )
    ),

    # Main table ==============================================================
    navset_card_tab(
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
          choices = c("CSV (Maximum 20 MB)", "XSLX (Maximum 18 MB)"),
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
      )
    ),
    ## Footer ---------------------------------------------------------------
    div(
      class = "well",
      style = "font-size: 16px; background: #f7f7f7;",
      "The Index of Multiple deprivation (IMD) is a measure of relative deprivation. The IMD shown here has been
        split into quintiles, with a value of one indicating the 20% most deprived neighbourhoods and five the 20%
        least deprived. IMD is derived from the learner postcode recorded on the Individualised Learner Record."
    )
  )
}

nps_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Using the server to power to the provider dropdown for increased speed
    updateSelectizeInput(
      session = session,
      inputId = "provider",
      label = "Search for provider",
      choices = c("All providers", provider_choices),
      server = TRUE
    )

    # TODO: do we make all dropdowns server side by default and create our own mini module for dropdowns?

    # Reactive data set =======================================================

    # TODO: more efficient way to filter this, I don't like the 'in everything' style
    nps_reactive_table <- reactive({
      provider_chosen <- if (input$provider == "All providers") {
        provider_choices
      } else {
        input$provider
      }
      year_chosen <- if (input$year == "All years") {
        year_choices
      } else {
        input$year
      }
      characteristic_chosen <- if (input$characteristic == "All characteristics") {
        characteristic_choices
      } else {
        input$characteristic
      }

      nps_parquet %>%
        filter(`Academic Year` %in% year_chosen) %>%
        filter(`Learner characteristic` %in% characteristic_chosen) %>%
        filter(`Provider name` %in% provider_chosen) %>%
        collect()
    })

    # Table ===================================================================
    output$nps_table <- renderReactable({
      dfe_reactable(nps_reactive_table())
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      filename = function() {
        paste0(input$provider, "-", input$year, "-", input$characteristic, "-national_provider_summary.csv")
      },
      content = function(file) {
        write.csv(nps_reactive_table(), file, row.names = FALSE)
      }
    )
  })
}
