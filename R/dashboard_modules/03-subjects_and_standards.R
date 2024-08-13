# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
sas_parquet <- read_sas("data/apprenticeships_data_0.parquet")

# Create static lists of options for dropdowns
sas_provider_choices <- data_choices(data = sas_parquet, column = "provider_name")
sas_year_choices <- data_choices(data = sas_parquet, column = "year")
sas_measure_choices <- data_choices(data = sas_parquet, column = "measure")

subjects_standards_ui <- function(id) {
  div(
    h1("Subjects and standards"),
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
          choices = c(sas_year_choices)
        ),
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = c(sas_measure_choices)
        )
      )
    ),
    card(
      layout_columns(
        girafeOutput(NS(id, "subject_area_bar"))
      )
    )
  )
}

subject_standards_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Using the server to power to the provider dropdown for increased speed
    updateSelectizeInput(
      session = session,
      inputId = "provider",
      label = "Search for provider",
      choices = c("All providers", sas_provider_choices),
      server = TRUE
    )

    subject_area_data <- reactive({
      if ("All providers" %in% input$provider) {
        provider_data <- sas_parquet %>%
          filter(
            measure == input$measure,
            year == input$year
          )
      } else {
        provider_data <- sas_parquet %>%
          filter(
            provider_name %in% input$provider,
            measure == input$measure,
            year == input$year
          )
      }
      provider_data %>%
        summarise(
          values = sum(values),
          .by = c("ssa_t1_desc")
        ) %>%
        mutate(ssa_t1_desc = str_wrap(ssa_t1_desc, 32))
    })

    output$subject_area_bar <- renderGirafe(
      girafe(
        ggobj =
          subject_area_data() %>%
            ggplot(aes(x = reorder(ssa_t1_desc, values), y = values)) +
            geom_col_interactive(fill = "#2073BC") +
            theme_classic() +
            coord_flip() +
            xlab("Subject area") +
            ylab(input$measure)
      )
    )
  })
}
