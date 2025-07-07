# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
sas_parquet <- arrow::read_parquet("data/subjects_and_standards_0.parquet")

# Create static lists of options for dropdowns
sas_year_choices <- sort(data_choices(data = sas_parquet, column = "year"),
  decreasing = TRUE
)
sas_subject_choices <- data_choices(data = sas_parquet, column = "ssa_t1_desc")
sas_measure_choices <- data_choices(data = sas_parquet, column = "measure")
sas_level_choices <- data_choices(data = sas_parquet, column = "apps_Level")
sas_provider_choices <- sort(data_choices(data = sas_parquet, column = "provider_name"))
sas_standard_choices <- sort(data_choices(data = sas_parquet, column = "std_fwk_name"))

# Creating a table of levels and subjects to standards so we can filter the
# standards options based on level and subject selection
sas_standard_table <- sas_parquet |>
  select(apps_Level, ssa_t1_desc, std_fwk_name) |>
  distinct() |>
  arrange(std_fwk_name)

subjects_standards_ui <- function(id) {
  div(
    h1("Subjects and standards"),
    p("Select options as required. If you select a standard before level(s) and subject(s),
      it will default to a list of standards relating to the level and subject. The standard required
      can then be reselected."),
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
          label = "Select level",
          choices = sas_level_choices,
          multiple = TRUE
        )
      )
    ),
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        heights_equal = "row",
        selectizeInput(
          inputId = NS(id, "provider"),
          label = NULL,
          choices = NULL,
          multiple = TRUE,
          options = list(maxOptions = 6000)
        ),
        selectizeInput(
          inputId = NS(id, "subject"),
          label = "Select subject area",
          choices = sas_subject_choices,
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
            choices = c("CSV (Up to 11.58 MB)", "XLSX (Up to 1.89 MB)"),
            selected = "CSV (Up to 11.58 MB)"
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
    # Initial selections
    # Calculate the standards available based on level/subject selection
    sas_std_choices <- reactive({
      # if both empty - all standards
      if (any(is.null(input$level), input$level == "") & any(is.null(input$subject), input$subject == "")) {
        sas_standard_table %>%
          pull(std_fwk_name) %>%
          unique()
      } else
      # if level is empty and subject isn't then get list for that subject
      if (any(is.null(input$level), input$level == "")) {
        sas_standard_table %>%
          filter(ssa_t1_desc %in% input$subject) %>%
          pull(std_fwk_name) %>%
          unique()
      } else
      # if subject is empty and level isn't then get list for that level
      if (any(is.null(input$subject), input$subject == "")) {
        sas_standard_table %>%
          filter(apps_Level %in% input$level) %>%
          pull(std_fwk_name) %>%
          unique()
        # if both populated then get list based on both
      } else {
        sas_standard_table %>%
          filter(apps_Level %in% input$level) %>%
          filter(ssa_t1_desc %in% input$subject) %>%
          pull(std_fwk_name) %>%
          unique()
      }
    })
    # Ensure the level/subject is based on a selection in the standard dropdown
    # if there is one
    observeEvent(input$standard, {
      remember_standard <- input$standard

      relevant_level <- sas_standard_table %>%
        filter(std_fwk_name %in% input$standard) %>%
        pull(apps_Level)
      updateSelectizeInput(session, "level", selected = relevant_level)

      relevant_subject <- sas_standard_table %>%
        filter(std_fwk_name %in% input$standard) %>%
        pull(ssa_t1_desc)
      updateSelectizeInput(session, "subject", selected = relevant_subject)

      updateSelectizeInput(session, "standard", selected = remember_standard)
    })

    observeEvent(input$subject, {
      relevant_standard <- sas_standard_table %>%
        filter(ssa_t1_desc %in% input$subject) %>%
        pull(std_fwk_name)
      updateSelectizeInput(session, "standard", selected = relevant_standard)
    })

    observeEvent(input$level, {
      relevant_standard <- sas_standard_table %>%
        filter(apps_Level %in% input$level) %>%
        pull(std_fwk_name)
      updateSelectizeInput(session, "standard", selected = relevant_standard)
    })

    # This dropdown needs to watch (observe) and update when a level
    # or subject area is selected
    observe({
      updateSelectizeInput(
        session = session,
        inputId = "standard",
        label = "Search for standard",
        choices = sas_std_choices(),
        server = TRUE
      )
    })

    # provider dropdown
    updateSelectizeInput(
      session = session,
      inputId = "provider",
      label = "Search for providers",
      choices = sas_provider_choices,
      server = TRUE
    )




    # Reactive data ===========================================================
    # Filter subject area data set based on inputs on this page. This reactive
    # feeds the table.
    filtered_raw_data_table <- reactive({
      data <- sas_parquet %>%
        filter(measure == input$measure, year == input$year)

      if (!(is.null(input$provider))) {
        data <- data %>% filter(provider_name %in% input$provider)
      }
      if (!(is.null(input$level))) {
        data <- data %>% filter(apps_Level %in% input$level)
      }
      if (!(is.null(input$subject))) {
        data <- data %>% filter(ssa_t1_desc %in% input$subject)
      }
      if (!(is.null(input$standard))) {
        data <- data %>% filter(std_fwk_name %in% input$standard)
      }
      return(data)
    })

    # Filter subject area data separately. Don't want same filters.
    filtered_raw_data_chart <- reactive({
      data <- sas_parquet %>%
        filter(measure == input$measure, year == input$year)
      # Only want this filtered by level, otherwise the bar chart disappears when
      # a subject is selected, if filtered by them
      if (!(is.null(input$provider))) {
        data <- data %>% filter(provider_name %in% input$provider)
      }
      if (!(is.null(input$level))) {
        data <- data %>% filter(apps_Level %in% input$level)
      }
      return(data)
    })

    # Create the table for providers to select from
    provider_selection_table <- reactive({
      provider_data <- filtered_raw_data_table()

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
    subject_area_data_table <- reactive({
      data <- filtered_raw_data_table()
      return(data)
    })

    # Separate data file for the chart - don't want it to be filtered by subject
    # So that bars don't disappear if not selected
    subject_area_data_chart <- reactive({
      data <- filtered_raw_data_chart()
      return(data)
    })

    # list of providers
    output$sas_provider_table <- renderReactable({
      # Put in message where there are none of the measure
      validate(need(
        nrow(provider_selection_table()) > 0,
        paste0("No ", firstlow(input$measure), " for these selections.")
      ))

      dfe_reactable(
        provider_selection_table(),
        searchable = FALSE,
        row_style = list(cursor = "pointer"),
        default_page_size = 15
      )
    })

    # Create an interactive chart showing the numbers broken down by subject
    # area
    output$subject_area_bar <- renderGirafe({
      # empty message if there are no rows for that provider
      validate(need(
        nrow(subject_area_data_chart()) > 0, ""
      ))

      girafe(
        ggobj =
          subject_area_data_chart() %>%
            summarise( # nolint: indentation_linter
              values = sum(values),
              .by = c("ssa_t1_desc")
            ) %>%
            ggplot(
              aes(
                x = reorder(as.factor(ssa_t1_desc), values),
                y = values,
                tooltip = paste0(
                  ssa_t1_desc, ": ", dfeR::comma_sep(values), " ",
                  # puts the selected levels into the tooltip
                  if_else(!(is.na(input$level[1])), gsub(".{14}$", "", input$level[1]), ""),
                  if_else(!(is.na(input$level[2])), gsub(".{14}$", "", paste("&", input$level[2])), ""),
                  if_else(!(is.na(input$level[3])), gsub(".{14}$", "", paste("&", input$level[3])), ""),
                  firstlow(input$measure)
                ),
                data_id = ssa_t1_desc
              )
            ) +
            geom_col_interactive(fill = afcolours::af_colours(n = 4)[1], position = position_dodge(width = 4.9)) +
            coord_flip() +
            xlab("") +
            ylab(input$measure) +
            scale_y_continuous(labels = dfeR::comma_sep) +
            scale_x_discrete(
              labels = function(x) str_wrap(x, width = 30),
              drop = FALSE
            ) +
            ggplot2::theme_minimal() +
            ggplot2::theme(
              legend.position = "top",
              legend.title = element_blank(),
              panel.grid = element_blank(),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              axis.title.x = element_text(size = 10, face = "bold", margin = margin(t = 10)),
              axis.text.x = element_text(size = 10),
              axis.text.y = element_text(size = 10),
              text = element_text(family = dfe_font)
            ),
        options = list(
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:2px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "multiple",
            selected = input$subject,
            css = "cursor:pointer;stroke:black;stroke-width:2px;fill:#ffdd00;"
          ),
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          )
        ),
        fonts = list(sans = dfe_font)
      )
    })

    # Expandable table of subject areas.
    output$sas_subject_area_table <- renderReactable({
      # Put in message where there are none of the measure
      # can be blank as message in provider table
      validate(need(
        nrow(subject_area_data_table()) > 0, ""
      ))

      subject_data <- subject_area_data_table() %>%
        summarise(
          values = sum(values),
          .by = c("ssa_t1_desc", "ssa_t2_desc", "apps_Level", "std_fwk_name")
        )
      if (!is.null(input$subject)) {
        subject_data <- subject_data %>%
          filter(ssa_t1_desc %in% input$subject)
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

    # Get provider name for file name
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(
          input$year, "-", input$measure, "-", input$subject, "-",
          input$level, input$provider, "-subjects-and-standards"
        )
        extension <- if (input$file_type == "CSV (Up to 11.58 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 11.58 MB)") {
          data.table::fwrite(subject_area_data_table(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(subject_area_data_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
