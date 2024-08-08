library(ggplot2)
library(ggiraph)
library(tidyr)

# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
chars_parquet <- read_chars("data/apprenticeships_demographics_0.parquet")

# Default for input is to select rows within a column so put into long format
chars_parquet <- chars_parquet %>%
  pivot_longer(
    cols = -c(year, age_group, sex, ethnicity_major, lldd, provider_name),
    names_to = "measure",
    values_to = "count"
  )

# divide up data for different characteristics
chars_age <- chars_parquet %>% filter(age_group != "Total")
chars_sex <- chars_parquet %>% filter(sex != "Total")
chars_ethnicity <- chars_parquet %>% filter(ethnicity_major != "Total")
chars_lldd <- chars_parquet %>% filter(lldd != "Total")


# Create static lists of options for dropdowns
chars_provider_choices <- data_choices(data = chars_parquet, column = "provider_name")
chars_year_choices <- data_choices(data = chars_parquet, column = "year")
chars_measure_choices <- data_choices(data = chars_parquet, column = "measure")



# Main module code ============================================================

learner_characteristics_ui <- function(id) {
  div(
    # Tab header ==============================================================
    h1("Learner characteristics"),

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
          choices = c(chars_year_choices)
        ),
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = c(chars_measure_choices)
        ),
      )
    ),

    # Main table ==============================================================
    navset_card_tab(
      id = "provider_learner_characteristics",
      ## age tab ------------------------------------------------------------
      nav_panel(
        "Age",
        reactable::reactableOutput(NS(id, "chars_table")),
        plotOutput("age_plot")
      ),
      ## Download tab ---------------------------------------------------------
      nav_panel(
        "Download data",
        shinyGovstyle::radio_button_Input(
          inputId = NS(id, "file_type"),
          label = h2("Choose download file format"),
          hint_label = "The XLSX format is designed for use in Microsoft Excel",
          choices = c("CSV (Up to 5.22 MB)", "XLSX (Up to 1.76 MB)"),
          selected = "CSV (Up to 5.22 MB)"
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
  )
}

learner_characteristics_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Using the server to power to the provider dropdown for increased speed
    updateSelectizeInput(
      session = session,
      inputId = "provider",
      label = "Search for provider",
      choices = c(chars_provider_choices),
      server = TRUE
    )

    # Reactive data set =======================================================
    chars_reactive_table <- reactive({
      chars_filtered <- chars_age
      chars_filtered <- chars_filtered %>% filter(provider_name == input$provider)
      chars_filtered <- chars_filtered %>% filter(year == input$year)
      chars_filtered <- chars_filtered %>% filter(measure == input$measure)
      # Pull the lazy loaded and now filtered data into memory
      chars_filtered %>% collect()
    })

    # Age ===================================================================
    output$chars_table <- renderReactable({
      dfe_reactable(chars_reactive_table())
    })
    # Render a barplot
    output$age_plot <- renderPlot({
      chars_reactive_table() %>%
        ggplot(aes(x = age_group, y = count)) +
        geom_col(fill = c("#12436D"))
    })
    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$provider, "-", input$year, "-", "-provider_summary")
        extension <- if (input$file_type == "CSV (Up to 5.22 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 5.22 MB)") {
          data.table::fwrite(chars_reactive_table(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(chars_reactive_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
