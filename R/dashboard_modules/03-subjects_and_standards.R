# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
sas_parquet <- read_sas("data/apprenticeships_data_0.parquet")

# Create static lists of options for dropdowns
sas_provider_choices <- data_choices(data = sas_parquet, column = "provider_name")
# Providers should be in alphabetical order
sas_provider_choices <- sort(sas_provider_choices)
sas_year_choices <- sort(data_choices(data = sas_parquet, column = "year"),
  decreasing = TRUE
)
sas_measure_choices <- data_choices(data = sas_parquet, column = "measure")

sas_level_choices <- data_choices(data = sas_parquet, column = "apps_Level")

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
          choices = NULL,
          multiple = TRUE,
          options = list(maxOptions = 6000)
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
        ),
        selectInput(
          inputId = NS(id, "level"),
          label = "Select apprenticeship level",
          choices = c(sas_level_choices),
          multiple = TRUE,
          selected = data_choices(data = sas_parquet, column = "apps_Level")
        ),
      )
    ),
    card(
      layout_columns(
        col_widths = c(4, 8),
        # Provider list
        card(
          card_header(textOutput(NS(id, "sas_provider_table_title"))),
          card_body(reactable::reactableOutput(NS(id, "sas_provider_table")))
        ),
        ## Tabs ----------------------------------------------------------------
        navset_card_tab(
          id = "sas_tabs",
          nav_panel(
            "Graphic",
            girafeOutput(NS(id, "subject_area_bar")),
          ),
          nav_panel(
            "Table including level and standard",
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
      choices = c(sas_provider_choices),
      server = TRUE
    )

    subject_selection <- reactive({
      if (is.null(input$subject_area_bar_selected)) {
        "all subjects"
      } else {
        input$subject_area_bar_selected
      }
    })

    # Filter subject area data set based on inputs on this page. This reactive
    # feeds the tables and chart.
    subject_area_data <- reactive({
      data <- sas_parquet %>%
        filter(
          measure == input$measure,
          year == input$year,
          apps_Level %in% input$level
        )
      if (!(is.null(input$provider))) {
        data <- data %>%
          filter(
            provider_name %in% input$provider
          )
      }
      data
    })

    # Adding a reactive to handle cleaning the selected SSA T1 Description from
    # the bar chart. Removes the line wrapping I've added for the chart.
    ssa_t1_selected <- reactive({
      gsub("\\n", " ", input$subject_area_bar_selected)
    })

    # Create dynamic title for the provider table
    output$sas_provider_table_title <- renderText({
      paste(
        input$measure, "for providers across",
        ifelse(
          length(ssa_t1_selected()) != 0,
          paste0(ssa_t1_selected(), collapse = " / "),
          "all subject areas"
        )
      )
    })

    provider_selection_table <- reactive({
      # Filter the data based on whether the user's selected any subject areas
      # from the chart
      if (!is.null(input$subject_area_bar_selected)) {
        provider_data <- subject_area_data() %>%
          filter(ssa_t1_desc %in% ssa_t1_selected())
      } else {
        provider_data <- subject_area_data()
      }
      # Run a quick aggregate of numbers by provider name.
      provider_data %>%
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
    })

    output$sas_provider_table <- renderReactable({
      # Put in message where there are none of the measure
      validate(need(
        nrow(provider_selection_table()) > 0,
        paste0("No ", firstlow(input$measure), " for this provider.")
      ))

      dfe_reactable(
        provider_selection_table()
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
          openxlsx::write.xlsx(chars_reactive_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
