# TODO: add a chart to filter using the onClick from the table
# TODO: make clicking the chart filter the table
# TODO: add region tables
# TODO: make region tables cross filter

# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
prov_breakdowns_parquet <- read_apps("data/apprenticeships_data_0.parquet")

# Create static lists of options for dropdowns
apps_measure_choices <- c("achievements", "enrolments", "starts") # TODO: would like to capitalise eventually
apps_year_choices <- data_choices(data = prov_breakdowns_parquet, column = "year")
apps_level_choices <- data_choices(data = prov_breakdowns_parquet, column = "apps_Level")
apps_age_choices <- data_choices(data = prov_breakdowns_parquet, column = "age_group")

# Main module code ============================================================

prov_breakdowns_ui <- function(id) {
  div(
    # Tab header ==============================================================
    h1("Provider breakdowns"),

    # User selection area =====================================================
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = apps_measure_choices
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
    layout_columns(
      col_widths = c(4, 8),
      ## Table on left you can select providers from --------------------------
      card(reactable::reactableOutput(NS(id, "prov_selection_table"))),
      ## Tabs on right --------------------------------------------------------
      navset_card_tab(
        id = "provider_breakdown_tabs",
        nav_panel(
          "Provider type",
          girafeOutput(NS(id, "provider_types"))
        ),
        nav_panel(
          "Delivery region",
          reactable::reactableOutput(NS(id, "delivery_region"))
        ),
        nav_panel(
          "Test selection",
          textOutput(NS(id, "selected_data"))
        ),
        nav_panel(
          "Download data",
          shinyGovstyle::radio_button_Input(
            inputId = NS(id, "file_type"),
            label = h2("Choose download file format"),
            hint_label = "The XLSX format is designed for use in Microsoft Excel",
            choices = c("CSV (Up to X MB)", "XLSX (Up to X MB)"),
            selected = "CSV (Up to X MB)"
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
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        collect()
    })

    # Create the table itself -------------------------------------------------
    output$prov_selection_table <- renderReactable({
      dfe_reactable(
        prov_selection_table(),
        onClick = "select",
        selection = "multiple",
        rowStyle = list(cursor = "pointer"),
        searchable = TRUE
      )
    })

    # Get the selections from the provider table ------------------------------
    selectedProviders <- reactive({
      selected <- getReactableState("prov_selection_table", "selected")
      if (length(selected) == 0) {
        # Return the full data of all providers if nothing selected from the table
        return(unlist(prov_selection_table()[, 1]))
      }

      # Filter to only the selected providers
      # Convert to a vector of provider names to use for filtering elsewhere
      # use.names = FALSE is used as it is much faster to process and we don't name the items
      unlist(prov_selection_table()[selected, 1])
    })

    # Main data ===============================================================
    # Main dataset for use in charts / tables / download ----------------------
    prov_breakdown_table <- reactive({
      prov_breakdown <- prov_breakdowns_parquet %>%
        filter(year == input$year)

      # Only filtering these if needed, by default we want all returned
      if (input$level != "All levels") {
        prov_breakdown <- prov_breakdown %>% filter(apps_Level %in% input$level)
      }
      if (input$age != "All age groups") {
        prov_breakdown <- prov_breakdown %>% filter(age_group == input$age)
      }
      if (length(getReactableState("prov_selection_table", "selected")) != 0) {
        prov_breakdown <- prov_breakdown %>% filter(provider_name %in% selectedProviders())
      }

      prov_breakdown %>% collect()
    })

    delivery_region_table <- reactive({
      prov_breakdown_table() %>%
        with_groups(
          "delivery_region",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )
    })

    output$delivery_region <- renderReactable({
      dfe_reactable(delivery_region_table())
    })

    output$selected_data <- renderText({
      selectedProviders()
    })

    # Chart of provider types =================================================
    prov_type_chart_data <- reactive({
      prov_breakdown_table() %>%
        with_groups(
          "provider_type",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )
    })

    output$provider_types <- renderGirafe(
      girafe(
        ggobj = prov_type_chart_data() %>%
          ggplot(aes(y = `Number of apprenticeships`, x = provider_type)) +
          geom_col() +
          coord_flip() +
          theme_classic() +
          labs(y = "Number of apprenticeships", x = ""),
        options = list(opts_selection(type = "single"))
      )
    )
    # Data download ===========================================================
  })
}
