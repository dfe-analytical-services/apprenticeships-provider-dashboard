# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
chars_parquet <- read_chars("data/apprenticeships_demographics_0.parquet") %>%
  # Default for input is to select rows within a column so put into long format
  pivot_longer(
    cols = -c(year, age_group, sex, ethnicity_major, lldd, provider_name),
    names_to = "measure",
    values_to = "count"
  ) %>%
  mutate(measure = firstup(measure))


age_parquet <- chars_parquet %>%
  filter(lldd == "Total" & sex == "Total" & ethnicity_major == "Total" & count > 0)

ethnicity_parquet <- chars_parquet %>%
  filter(lldd == "Total" & sex == "Total" & age_group == "Total" & count > 0)


# Create static lists of options for dropdowns
chars_year_choices <- sort(data_choices(data = chars_parquet, column = "year"),
  decreasing = TRUE
)
chars_measure_choices <- data_choices(data = chars_parquet, column = "measure")
# for providers need to remove total first so can put at the beginning
chars_parquet_no_total <- chars_parquet %>%
  filter(provider_name != "Total")
chars_provider_choices <- sort(data_choices(
  data = chars_parquet_no_total,
  column = "provider_name"
))



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
          choices = NULL,
          selected = "Total",
          options = list(maxOptions = 2000)
        ),
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = c(chars_year_choices),
          selected = "2023/24 (Q3 Aug to Apr)"
        ),
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = c(chars_measure_choices),
          selected = "Starts"
        ),
      )
    ),

    # Main table ==============================================================
    navset_card_tab(
      id = "provider_learner_characteristics",
      ## lldd tab ------------------------------------------------------------
      nav_panel(
        "LLDD",
        plotlyOutput(NS(id, ("lldd_plot")))
      ),
      ## sex tab ------------------------------------------------------------
      nav_panel(
        "Sex",
        plotlyOutput(NS(id, ("sex_plot")))
      ),
      ## Age tab ------------------------------------------------------------
      # this should be a plot where possible or a message where all age groups are suppressed
      nav_panel(
        "Age",
        plotlyOutput(NS(id, ("age_plot")))
      ),
      # Ethnicity tab ------------------------------------------------------------
      nav_panel(
        "Ethnicity",
        plotlyOutput(NS(id, ("ethnicity_plot")))
      ),
      ## Download tab ---------------------------------------------------------
      nav_panel(
        "Download data",
        shinyGovstyle::radio_button_Input(
          inputId = NS(id, "file_type"),
          label = h2("Choose download file format"),
          hint_label = "The XLSX format is designed for use in Microsoft Excel",
          choices = c("CSV (Up to 8.73 MB)", "XLSX (Up to 2.74 MB)"),
          selected = "CSV (Up to 8.73 MB)"
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
      choices = c("Total", chars_provider_choices),
      server = TRUE,
      selected = "Total"
    )

    # Reactive data set =======================================================
    chars_reactive_table <- reactive({
      chars_filtered <- chars_parquet
      chars_filtered <- chars_filtered %>% filter(provider_name == input$provider)
      chars_filtered <- chars_filtered %>% filter(year == input$year)
      chars_filtered <- chars_filtered %>% filter(measure == input$measure)
      # and sort into the right order
      chars_filtered$lldd <- factor(chars_filtered$lldd,
        levels = c("Total", "LLDD - yes", "LLDD - no", "25+", "LLDD - unknown")
      )
      chars_filtered$sex <- factor(chars_filtered$sex,
        levels = c("Total", "Male", "Female", "Unknown")
      )
      chars_filtered$age_group <- factor(chars_filtered$age_group,
        levels = c("Total", "Under 19", "19-24", "25+", "Unknown")
      )
      chars_filtered$ethnicity_major <- factor(chars_filtered$ethnicity_major,
        levels = c(
          "Total",
          "White",
          "Black / African / Caribbean / Black British",
          "Asian / Asian British",
          "Mixed / Multiple ethnic groups",
          "Other ethnic group",
          "Unknown"
        )
      )
      chars_filtered <- chars_filtered[order(
        chars_filtered$lldd,
        chars_filtered$sex,
        chars_filtered$age_group,
        chars_filtered$ethnicity_major
      ), ]

      # Pull the lazy loaded and now filtered data into memory
      chars_filtered %>% collect()
    })


    # age data
    age_reactive_table <- reactive({
      age_filtered <- age_parquet
      age_filtered <- age_filtered %>% filter(provider_name == input$provider)
      age_filtered <- age_filtered %>% filter(year == input$year)
      age_filtered <- age_filtered %>% filter(measure == input$measure)
      # and sort into the right order
      chars_filtered$age_group <- factor(chars_filtered$age_group,
        levels = c("Total", "Under 19", "19-24", "25+", "Unknown")
      )
      age_filtered <- age_filtered[order(
        age_filtered$age_group
      ), ]

      # Pull the lazy loaded and now filtered data into memory
      age_filtered %>% collect()
    })


    # ethnicity data
    ethnicity_reactive_table <- reactive({
      ethnicity_filtered <- ethnicity_parquet
      ethnicity_filtered <- ethnicity_filtered %>% filter(provider_name == input$provider)
      ethnicity_filtered <- ethnicity_filtered %>% filter(year == input$year)
      ethnicity_filtered <- ethnicity_filtered %>% filter(measure == input$measure)
      # and sort into the right order
      ethnicity_filtered$ethnicity_major <- factor(ethnicity_filtered$ethnicity_major,
        levels = c(
          "Total",
          "White",
          "Black / African / Caribbean / Black British",
          "Asian / Asian British",
          "Mixed / Multiple ethnic groups",
          "Other ethnic group",
          "Unknown"
        )
      )
      ethnicity_filtered <- ethnicity_filtered[order(
        ethnicity_filtered$ethnicity_major
      ), ]

      # Pull the lazy loaded and now filtered data into memory
      ethnicity_filtered %>% collect()
    })

    # LLDD ===================================================================
    output$lldd_plot <- renderPlotly({
      lldd <-
        chars_reactive_table() %>%
        filter(((lldd == "LLDD - yes" & count > 0) |
          (lldd == "LLDD - no" & count > 0) |
          (lldd == "LLDD - unknown" & count > 0))) %>%
        plot_ly(
          labels = ~ stringr::str_wrap(lldd, width = 5),
          parents = NA,
          values = ~count,
          type = "treemap",
          hovertemplate = "%{label}<br>Count: %{value}<extra></extra>",
          marker = (list(colors = c("#12436D", "#28A197", "#801650"), sizemode = "area")),
          textfont = list(color = "white", size = 30)

        )
    })
    # Sex ===================================================================
    output$sex_plot <- renderPlotly({
      chars_reactive_table() %>%
        filter((sex == "Male" & count > 0) |
          (sex == "Female" & count > 0)) %>%
        plot_ly(
          labels = ~sex,
          parents = NA,
          values = ~count,
          type = "treemap",
          hovertemplate = "%{label}<br>Count: %{value}<extra></extra>",
          marker = (list(colors = c("#12436D", "#28A197"), sizemode = "area")),
          textfont = list(color = "white", size = 30)
        )
    })
    # Age ===================================================================
    # create the plot
    output$age_plot <- renderPlotly({
      validate(
        need(nrow(age_reactive_table) > 0, "All age groups have low numbers")
      )
      age_reactive_table() %>%
        plot_ly(
          labels = ~ stringr::str_wrap(age_group, width = 5),
          parents = NA,
          values = ~count,
          type = "treemap",
          hovertemplate = "%{label}<br>Count: %{value}<extra></extra>",
          marker = (list(colors = c("#12436D", "#28A197", "#801650"), sizemode = "area")),
          textfont = list(color = "white", size = 30)
        )
    })

    # Ethnicity ===================================================================
    output$ethnicity_plot <- renderPlotly({
      validate(
        need(nrow(ethnicity_reactive_table()) > 0, "All ethnicity groups have low numbers")
      )
      ethnicity_reactive_table() %>%
        plot_ly(
          labels = ~ stringr::str_wrap(ethnicity_major, width = 5),
          parents = NA,
          values = ~count,
          type = "treemap",
          hovertemplate = "%{label}<br>Count: %{value}<extra></extra>",
          marker = (list(colors = c("#12436D", "#28A197", "#801650", "#F46A25", "#3D3D3D", "#A285D1"), sizemode = "area")),
          textfont = list(color = "white", size = 30)
        )
    })
  
      # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$provider, "-", input$year, "-", "-provider_summary")
        extension <- if (input$file_type == "CSV (Up to 8.73 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 8.73 MB)") {
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
