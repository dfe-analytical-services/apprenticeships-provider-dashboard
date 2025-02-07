# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
nps_parquet <- arrow::read_parquet("data/national_provider_summary_0.parquet")

# Create static lists of options for dropdowns
nps_provider_choices <- data_choices(data = nps_parquet, column = "Provider name")
nps_year_choices <- data_choices(data = nps_parquet, column = "Academic Year")
nps_characteristic_choices <- data_choices(data = nps_parquet, column = "Learner characteristic")

# Main module code ============================================================
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
          choices = NULL,
          options = list(maxOptions = 6000)
        ),
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = c("All years", nps_year_choices)
        ),
        selectInput(
          inputId = NS(id, "characteristic"),
          label = "Select learner characteristic",
          choices = c("All characteristics", nps_characteristic_choices)
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
          inputId = NS(id, "file_type"),
          label = h2("Choose download file format"),
          hint_label = paste0(
            "This will download all data related to the providers and options selected.",
            " The XLSX format is designed for use in Microsoft Excel."
          ),
          choices = c("CSV (Up to 5.47 MB)", "XLSX (Up to 1.75 MB)"),
          selected = "CSV (Up to 5.47 MB)"
        ),
        downloadButton(
          NS(id, "download_data"),
          label = "Download data",
          class = "gov-uk-button",
          icon = NULL
        )
      )
    ),
    ## Footer -----------------------------------------------------------------
    div(
      class = "well",
      style = "font-size: 1rem; background: #f7f7f7;",
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
      choices = c("All providers", nps_provider_choices),
      server = TRUE
    )

    # Reactive data set =======================================================
    nps_reactive_table <- reactive({
      nps_filtered <- nps_parquet

      if (input$provider != "All providers") {
        nps_filtered <- nps_filtered %>% filter(`Provider name` == input$provider)
      }
      if (input$year != "All years") {
        nps_filtered <- nps_filtered %>% filter(`Academic Year` == input$year)
      }
      if (input$characteristic != "All characteristics") {
        nps_filtered <- nps_filtered %>% filter(`Learner characteristic` == input$characteristic)
      }

      # Pull the lazy loaded and now filtered data into memory
      nps_filtered %>% collect()
    })

    # Table ===================================================================
    output$nps_table <- renderReactable({
      # Put in message where there are none of the measure
      validate(need(
        nrow(nps_reactive_table()) > 0,
        paste0("No results for this provider in this year.")
      ))
      dfe_reactable(nps_reactive_table())
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$provider, "-", input$year, "-", input$characteristic, "-provider_summary")
        extension <- if (input$file_type == "CSV (Up to 5.47 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 5.47 MB)") {
          data.table::fwrite(nps_reactive_table(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(nps_reactive_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
