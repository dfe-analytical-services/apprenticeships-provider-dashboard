# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
chars_parquet <- read_chars("data/apprenticeships_demographics_0.parquet") 

# Create static lists of options for dropdowns
chars_year_choices <- sort(data_choices(data = chars_parquet, column = "year"),
  decreasing = TRUE
)

chars_measure_choices <- data_choices(data = chars_parquet, column = "measure")
# for providers need to remove total first so can put at the beginning
chars_parquet_no_total <- chars_parquet %>%
  filter(provider_name != "Total (All providers)")
chars_provider_choices <- sort(data_choices(
  data = chars_parquet_no_total,
  column = "provider_name"
))

# for characteristic need to remove total first so can put at the beginning
characteristics_no_total <- chars_parquet %>%
  filter(characteristic != "Total")
chars_choices <- (data_choices(data = characteristics_no_total, column = "characteristic_type"))

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
          selected = NULL,
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
        selectInput(
          inputId = NS(id, "characteristic_type"),
          label = "Select characteristic",
          choices = c(chars_choices),
          selected = "Age"
        ),
      )
    ),

    # Main table ==============================================================
    navset_card_tab(
      id = "provider_learner_characteristics",
      ##  plot tab ------------------------------------------------------------
      nav_panel(
        "Graphic",
        plotlyOutput(NS(id, ("tree_map_plot")))
      ),
      ##  table tab ------------------------------------------------------------
      nav_panel(
        "Table",
        tableOutput(NS(id, ("chars_table")))
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
      choices = c("Total (All providers)", chars_provider_choices),
      server = TRUE,
      selected = "Total (All providers)"
    )

    # Reactive data set =======================================================
    chars_reactive_table <- reactive({
      chars_filtered <- chars_parquet
      chars_filtered <- chars_filtered %>% filter(provider_name == input$provider)
      chars_filtered <- chars_filtered %>% filter(year == input$year)
      chars_filtered <- chars_filtered %>% filter(measure == input$measure)
      chars_filtered <- chars_filtered %>% filter(characteristic_type == input$characteristic_type)
      # and sort into the right order

      chars_filtered$characteristic_type <- factor(chars_filtered$characteristic_type,
        levels = c(
          "Age", "Sex",
          "Learner with learning difficulties or disabilities (LLDD)", "Ethnicity"
        )
      )

      chars_filtered$characteristic <- factor(chars_filtered$characteristic,
        levels = c(
          "Total",
          "Under 19", "19-24", "25+",
          "Male", "Female",
          "LLDD - yes", "LLDD - no", "LLDD - unknown",
          "White",
          "Black / African / Caribbean / Black British",
          "Asian / Asian British",
          "Mixed / Multiple ethnic groups",
          "Other ethnic group",
          "Unknown"
        )
      )

      chars_filtered <- chars_filtered[order(
        chars_filtered$characteristic_type,
        chars_filtered$characteristic
      ), ]

      # Pull the lazy loaded and now filtered data into memory
      chars_filtered %>% collect()
    })

    # Treemap plot

    # Message when there are none of the measure at all
    output$tree_map_plot <- renderPlotly({
      validate(need(nrow(chars_reactive_table()) > 0, paste0("No ", input$measure, " for this provider.")))

      # Message when all groups are low, and treemap cannot be displayed
      # But can still be seen in the table
      validate(need(
        nrow(filter(chars_reactive_table(), count != "low" & characteristic != "Total")) > 0,
        paste0("All groups have low numbers.")
      ))

      chars_reactive_table() %>%
        filter(characteristic != "Total") %>%
        filter(count != "low") %>%

      plot_ly(
          labels = ~ stringr::str_wrap(characteristic, width = 5),
          parents = NA,
          values = ~ as.numeric(count),
          type = "treemap",
          hovertemplate = "%{label}<br>Count: %{value}<extra></extra>",
          marker = (list(
            colors = c("#12436D", "#28A197", "#801650", "#F46A25", "#3D3D3D", "#A285D1"),
            sizemode = "area"
          )),
          textfont = list(color = "white", size = 30)
        ) %>%
        config(displaylogo = FALSE, displayModeBar = FALSE)
    })

    # table

    # Message when there are none of the measure at all, and no table
    output$chars_table <- renderTable({
      validate(need(nrow(chars_reactive_table()) > 0, paste0("No ", input$measure, " for this provider.")))

      chars_reactive_table()
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
