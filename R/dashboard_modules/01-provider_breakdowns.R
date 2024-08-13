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
    card(
      reactable::reactableOutput(NS(id, "prov_table"))
    )
  )
}

prov_breakdowns_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Reactive data set =======================================================
    # Update based on user choices
    prov_breakdowns_table <- reactive({
      prov_breakdowns_parquet %>%
        filter(year == input$year) %>%
        with_groups(
          "provider_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        collect()
    })

    # Create shared data set that is used by tables and chart together
    # shared_apps_data <- SharedData$new(prov_breakdowns_table)

    # Table ===================================================================
    output$prov_table <- renderReactable({
      dfe_reactable(
        prov_breakdowns_table(),
        onClick = "select",
        selection = "multiple",
        rowStyle = list(cursor = "pointer")
      )
    })

    # Data download ===========================================================
  })
}
