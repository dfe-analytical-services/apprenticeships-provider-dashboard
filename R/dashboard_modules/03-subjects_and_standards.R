# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
sas_parquet <- read_sas("data/apprenticeships_data_0.parquet")

# Create static lists of options for dropdowns
sas_year_choices <- sort(data_choices(data = sas_parquet, column = "year"),
  decreasing = TRUE
)
sas_measure_choices <- data_choices(data = sas_parquet, column = "measure")
sas_level_choices <- data_choices(data = sas_parquet, column = "apps_Level")

# Creating a table of levels to standards so we can filter the standards options based on level selection
sas_standard_table <- sas_parquet |>
  select(apps_Level, std_fwk_name) |>
  distinct() |>
  arrange(std_fwk_name)

subjects_standards_ui <- function(id) {
  div(
    h1("Subjects and standards"),
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = c(sas_year_choices)
        ),
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = c(sas_measure_choices)
        ),
        selectizeInput(
          inputId = NS(id, "level"),
          label = NULL,
          choices = NULL,
          multiple = TRUE
        ),
        selectizeInput(
          inputId = NS(id, "standard"),
          label = NULL,
          choices = NULL,
          multiple = TRUE,
          options = list(maxOptions = 6000)
        )
      )
    ),
    # Main data area ===========================================================
    # Provider list --------------------------------------------------------
    layout_columns(
      col_widths = c(4, 8),
      card(
        reactable::reactableOutput(NS(id, "sas_provider_table"))
      ),
      ## Tabs ----------------------------------------------------------------
      navset_card_tab(
        id = "sas_tabs",
        nav_panel(
          "Bar chart",
          girafeOutput(NS(id, "subject_area_bar")),
        ),
        nav_panel(
          "Table",
          reactable::reactableOutput(NS(id, "sas_subject_area_table"))
        ),
        nav_panel(
          "Download data",
          shinyGovstyle::radio_button_Input(
            inputId = NS(id, "file_type"),
            label = h2("Choose download file format"),
            hint_label = "This will download all data related to the providers and options selected.
          The XLSX format is designed for use in Microsoft Excel",
            choices = c("CSV (Up to 13.18 MB)", "XLSX (Up to 2.12 MB)"),
            selected = "CSV (Up to 13.18 MB)"
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
      )
    )
  )
}

subject_standards_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Calculate the standards available based on level selection
    sas_std_choices <- reactive({
      if (any(is.null(input$level), input$level == "")) {
        sas_standard_table %>%
          pull(std_fwk_name) %>%
          unique()
      } else {
        sas_standard_table %>%
          filter(apps_Level %in% input$level) %>%
          pull(std_fwk_name)
      }
    })

    updateSelectizeInput(
      session = session,
      inputId = "level",
      label = "Select level",
      choices = sas_level_choices,
      server = TRUE
    )

    # This dropdown needs to watch (observe) and update when a level is selected
    observe({
      updateSelectizeInput(
        session = session,
        inputId = "standard",
        label = "Search for standard",
        choices = sas_std_choices(),
        server = TRUE
      )
    })

    # Get the selections from the provider table ==============================
    selected_providers <- reactive({
      # Filter to only the selected providers and convert to a vector to use for filtering elsewhere
      unlist(provider_selection_table()[getReactableState("sas_provider_table", "selected"), 1], use.names = FALSE)
    })

    # Reactive data ===========================================================
    # Filter subject area data set based on inputs on this page. This reactive
    # feeds the tables and chart.
    filtered_raw_data <- reactive({
      data <- sas_parquet %>%
        filter(measure == input$measure, year == input$year)

      if (!(is.null(input$level))) {
        data <- data %>% filter(apps_Level %in% input$level)
      }
      if (!(is.null(input$standard))) {
        data <- data %>% filter(std_fwk_name %in% input$standard)
      }

      return(data)
    })

    # Create the table for providers to select from
    provider_selection_table <- reactive({
      provider_data <- filtered_raw_data()

      # Run a quick aggregate of numbers by provider name.
      provider_data <- provider_data %>%
        summarise(
          values = sum(values),
          .by = c("provider_name")
        ) %>%
        arrange(-values) %>%
        filter(values > 0) %>%
        rename(
          `Provider name` = provider_name,
          !!quo_name(input$measure) := values
        )

      return(provider_data)
    })

    # Main expandable table data (adds the filter for provider selections)
    subject_area_data <- reactive({
      data <- filtered_raw_data()

      if (length(selected_providers() != 0)) {
        data <- data %>% filter(provider_name %in% selected_providers())
      }

      return(data)
    })



    output$sas_provider_table <- renderReactable({
      # Put in message where there are none of the measure
      validate(need(
        nrow(provider_selection_table()) > 0,
        paste0("No ", firstlow(input$measure), " for this provider.")
      ))

      dfe_reactable(
        provider_selection_table(),
        on_click = "select",
        selection = "multiple",
        searchable = TRUE,
        row_style = list(cursor = "pointer"),
        default_page_size = 15
      )
    })

    # Create an interactive chart showing the numbers broken down by subject
    # area
    output$subject_area_bar <- renderGirafe(
      girafe(
        ggobj =
          subject_area_data() %>%
            summarise( # nolint: indentation_linter
              values = sum(values),
              .by = c("ssa_t1_desc")
            ) %>%
            mutate(ssa_t1_desc = str_wrap(ssa_t1_desc, 32)) %>%
            ggplot(
              aes(
                x = reorder(ssa_t1_desc, values),
                y = values,
                tooltip = ssa_t1_desc,
                data_id = ssa_t1_desc
              )
            ) +
            geom_col_interactive(fill = "#12436D") +
            theme_classic() +
            coord_flip() +
            xlab("") +
            ylab(input$measure),
        options = list(opts_selection(
          type = "multiple",
          css = "fill:#28A197;stroke:#28A197;r:5pt;"
        ))
      )
    )





    # Expandable table of subject areas.
    output$sas_subject_area_table <- renderReactable({
      # Put in message where there are none of the measure
      validate(need(nrow(subject_area_data()) > 0, paste0("No ", firstlow(input$measure), " for this provider.")))

      subject_data <- subject_area_data() %>%
        summarise(
          values = sum(values),
          .by = c("ssa_t1_desc", "ssa_t2_desc", "apps_Level", "std_fwk_name")
        )
      if (!is.null(input$subject_area_bar_selected)) {
        subject_data <- subject_data %>%
          filter(ssa_t1_desc %in% ssa_t1_selected())
      }
      reactable(
        subject_data %>%
          rename(
            `Subject area` = ssa_t1_desc,
            `Subject area (tier 2)` = ssa_t2_desc,
            `Level` = apps_Level,
            `Standard` = std_fwk_name,
          ) %>%
          arrange(-values),
        highlight = TRUE,
        borderless = TRUE,
        showSortIcon = FALSE,
        style = list(fontSize = "16px"),
        defaultColDef = colDef(headerClass = "bar-sort-header"),
        groupBy = c("Subject area"),
        defaultSorted = c("Subject area (tier 2)", "Level"),
        columns = list(
          values = colDef(
            name = input$measure,
            aggregate = "sum"
          )
        )
      )
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$year, "-", input$level, "-", input$provider, "-subjects-and-standards")
        extension <- if (input$file_type == "CSV (Up to 13.18 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 13.18 MB)") {
          data.table::fwrite(subject_area_data(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(subject_area_data(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
