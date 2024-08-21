# TODO: make clicking the chart filter the table
# TODO: make region tables cross filter
# TODO: tidy up table column names

# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
prov_breakdowns_parquet <- read_prov_breakdowns("data/apprenticeships_data_0.parquet")

# Create static lists of options for dropdowns
apps_measure_choices <- c("achievements", "enrolments", "starts") # TODO: would like to capitalise eventually
apps_prov_type_choices <- data_choices(data = prov_breakdowns_parquet, column = "provider_type")
apps_year_choices <- data_choices(data = prov_breakdowns_parquet, column = "year")
apps_level_choices <- data_choices(data = prov_breakdowns_parquet, column = "apps_Level")
apps_age_choices <- data_choices(data = prov_breakdowns_parquet, column = "age_group")

# Main module code ============================================================

prov_breakdowns_ui <- function(id) {
  div(
    # Tab header ==============================================================
    h1("Provider breakdowns"),
    layout_columns(
      col_widths = c(4, 8),
      ## Table on left you can select providers from --------------------------
      card(reactable::reactableOutput(NS(id, "prov_selection_table"))),
      # User selection area =====================================================
      column(
        width = 12,
        div(
          class = "well",
          # style = "min-height: 100%; height: 100%; overflow-y: visible;",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            selectInput(
              inputId = NS(id, "measure"),
              label = "Select measure",
              choices = apps_measure_choices
            ),
            selectInput(
              inputId = NS(id, "prov_type"),
              label = "Select provider type",
              choices = c("All provider types", apps_prov_type_choices)
            ),
            selectInput(
              inputId = NS(id, "year"),
              label = "Select academic year",
              choices = apps_year_choices
            ),
            selectInput(
              inputId = NS(id, "level"),
              label = "Select level",
              choices = c("All levels", apps_level_choices)
            ),
            selectInput(
              inputId = NS(id, "age"),
              label = "Select age group",
              choices = c("All age groups", apps_age_choices)
            )
          )
        ),
        ## Tabs on right --------------------------------------------------------
        navset_card_tab(
          id = "provider_breakdown_tabs",
          nav_panel(
            "Regions",
            bslib::layout_column_wrap(
              reactable::reactableOutput(NS(id, "delivery_region")),
              reactable::reactableOutput(NS(id, "home_region"))
            )
          ),
          nav_panel(
            "Download data",
            shinyGovstyle::radio_button_Input(
              inputId = NS(id, "file_type"),
              label = h2("Choose download file format"),
              hint_label = paste0(
                "This will download all data related to the providers and options selected.",
                " The XLSX format is designed for use in Microsoft Excel."
              ),
              choices = c("CSV (Up to X MB)", "XLSX (Up to X MB)"),
              selected = "CSV (Up to X MB)"
            ),
            downloadButton(
              NS(id, "download_data"),
              label = "Download data",
              class = "gov-uk-button",
              icon = NULL
            )
          )
        )
      )
    )
  )
}

prov_breakdowns_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Provider selection ======================================================
    # Create the data used for the table on the left you can select providers from
    prov_selection_table <- reactive({
      prov_selection <- prov_breakdowns_parquet %>%
        filter(year == input$year)

      # Only filtering these if needed, by default we want all returned
      if (input$prov_type != "All provider types") {
        prov_selection <- prov_selection %>% filter(provider_type %in% input$prov_type)
      }
      if (input$level != "All levels") {
        prov_selection <- prov_selection %>% filter(apps_Level %in% input$level)
      }
      if (input$age != "All age groups") {
        prov_selection <- prov_selection %>% filter(age_group == input$age)
      }

      prov_selection %>%
        with_groups(
          "provider_name",
          summarise,
          `number` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        rename("Provider name" = provider_name) %>%
        rename_with(~ paste("Number of", input$measure), `number`) %>%
        collect()
    })

    # Create the table itself -------------------------------------------------
    output$prov_selection_table <- renderReactable({
      dfe_reactable(
        prov_selection_table(),
        on_click = "select",
        selection = "multiple",
        row_style = list(cursor = "pointer"),
        searchable = TRUE
      )
    })

    # Get the selections from the provider table ------------------------------
    selected_providers <- reactive({
      selected <- getReactableState("prov_selection_table", "selected")
      if (length(selected) == 0) {
        # Return the full data of all providers if nothing selected from the table
        # use.names = FALSE is used as it is much faster to process and we don't name the items
        return(unlist(prov_selection_table()[, 1], use.names = FALSE))
      }

      # Filter to only the selected providers
      # Convert to a vector of provider names to use for filtering elsewhere
      unlist(prov_selection_table()[selected, 1], use.names = FALSE)
    })

    # Main data ===============================================================
    # Main data set for use in charts / tables / download ---------------------
    prov_breakdown_table <- reactive({
      prov_breakdown <- prov_breakdowns_parquet %>%
        filter(year == input$year)

      # Only filtering these if needed, by default we want all returned
      if (input$prov_type != "All provider types") {
        prov_breakdown <- prov_breakdown %>% filter(provider_type %in% input$prov_type)
      }
      if (input$level != "All levels") {
        prov_breakdown <- prov_breakdown %>% filter(apps_Level %in% input$level)
      }
      if (input$age != "All age groups") {
        prov_breakdown <- prov_breakdown %>% filter(age_group == input$age)
      }
      if (length(getReactableState("prov_selection_table", "selected")) != 0) {
        prov_breakdown <- prov_breakdown %>% filter(provider_name %in% selected_providers())
      }

      prov_breakdown %>% collect()
    })

    # Region tables ===========================================================
    # Delivery regions --------------------------------------------------------
    delivery_region_table <- reactive({
      prov_breakdown_table() %>%
        with_groups(
          "delivery_region",
          summarise,
          `number` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        rename("Delivery region" = delivery_region) %>%
        rename_with(~ paste("Number of", input$measure), `number`)
    })

    output$delivery_region <- renderReactable({
      dfe_reactable(delivery_region_table())
    })

    # Home regions ------------------------------------------------------------
    home_region_table <- reactive({
      prov_breakdown_table() %>%
        with_groups(
          "learner_home_region",
          summarise,
          `number` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        rename("Learner home region" = learner_home_region) %>%
        rename_with(~ paste("Number of", input$measure), `number`)
    })

    output$home_region <- renderReactable({
      dfe_reactable(home_region_table())
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$year, "-", input$level, "-", input$age, "-provider_breakdowns")
        extension <- if (input$file_type == "CSV (Up to X MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to X MB)") {
          data.table::fwrite(prov_breakdown_table(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(prov_breakdown_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
