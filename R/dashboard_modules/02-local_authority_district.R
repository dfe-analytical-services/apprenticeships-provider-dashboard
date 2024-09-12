# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
lad_map_parquet <- read_lad("data/lad_map_data_0.parquet")

# Read in boundary files
lad_boundaries_2024 <- sf::st_read("data/boundary_files/Local_Authority_Districts_May_2024_Boundaries_UK_BUC_-3799209068982948111.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
  rename("lad_name" = LAD24NM)
lad_boundaries_2023 <- sf::st_read("data/boundary_files/Local_Authority_Districts_May_2023_UK_BUC_V2_8757178717458576320.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
  rename("lad_name" = LAD23NM)
lad_boundaries_2022 <- sf::st_read("data/boundary_files/Local_Authority_Districts_December_2022_UK_BUC_V2_3956567894081366924.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
  rename("lad_name" = LAD22NM)

# Create static lists of options for dropdowns

lad_year_choices <- data_choices(data = lad_map_parquet, column = "year")
# Years should be in descending order order
lad_year_choices <- sort(lad_year_choices, decreasing = TRUE)

lad_measure_choices <- c("achievements", "enrolments", "starts") # TODO: would like to capitalise eventually

provider_choices <- c("", distinct(lad_map_parquet, provider_name) %>% pull())
# Providers should be in alphabetical order
provider_choices <- sort(provider_choices)

delivery_lad_choices <- c("", distinct(lad_map_parquet, delivery_lad) %>% pull())

learner_home_lad_choices <- c("", distinct(lad_map_parquet, learner_home_lad) %>% pull())

# Main module code ============================================================
lad_ui <- function(id) {
  div(
    h1("Local authority district breakdowns"),
    # User selection area =====================================================
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = lad_measure_choices
        ),
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = lad_year_choices
        )
      ),
      # Main data area ==========================================================
      layout_column_wrap(
        width = 1 / 3,

        ## Maps and tables and download -----------------------------------------
        ## Dropdown options for LADs
        selectizeInput(
          inputId = NS(id, "provider"),
          label = "Search for a provider",
          choices = NULL,
          options = list(maxOptions = 6000)
        ),
        selectizeInput(
          inputId = NS(id, "delivery_lad"),
          label = "Search for a delivery LAD",
          choices = NULL
        ),
        selectizeInput(
          inputId = NS(id, "learner_home_lad"),
          label = "Search for a learner home LAD",
          choices = NULL
        )
      )
    ),
    layout_columns(
      col_widths = c(4, 8),
      ## Provider selection table ---------------------------------------------
      card(reactable::reactableOutput(NS(id, "prov_selection_table"))),
      ## Tabs -----------------------------------------------------------------
      navset_card_tab(
        id = "lad_maps_tabs",
        nav_panel(
          "Maps",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            div(
              h2("Delivery map"),
              leafletOutput(NS(id, "delivery_lad_map"))
            ),
            div(
              h2("Learner home map"),
              leafletOutput(NS(id, "learner_home_lad_map"))
            )
          )
        ),
        nav_panel(
          "Tables",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            reactable::reactableOutput(NS(id, "delivery_lad_table")),
            reactable::reactableOutput(NS(id, "learner_home_lad_table"))
          )
        ),
        nav_panel(
          "Download data",
          shinyGovstyle::radio_button_Input(
            inputId = NS(id, "file_type"),
            label = h2("Choose download file format"),
            hint_label = paste0(
              "This will download data for all providers and local authority districts based on the ",
              "options selected. The XLSX format is designed for use in Microsoft Excel."
            ),
            choices = c("CSV (Up to 18.42 MB)", "XLSX (Up to 5.92 MB)"),
            selected = "CSV (Up to 18.42 MB)"
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
}

lad_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Set initial dropdown values
    updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
    updateSelectizeInput(session, "delivery_lad", choices = delivery_lad_choices, server = TRUE)
    updateSelectizeInput(session, "learner_home_lad", choices = learner_home_lad_choices, server = TRUE)

    # Update dropdown lists, clearing out when other options are selected
    observeEvent(input$provider, {
      if (input$provider != "") {
        updateSelectizeInput(session, "delivery_lad", choices = delivery_lad_choices, server = TRUE)
        updateSelectizeInput(session, "learner_home_lad", choices = learner_home_lad_choices, server = TRUE)
      }
    })

    observeEvent(input$delivery_lad, {
      if (input$delivery_lad != "") {
        updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
        updateSelectizeInput(session, "learner_home_lad", choices = learner_home_lad_choices, server = TRUE)
      }
    })

    observeEvent(input$learner_home_lad, {
      if (input$learner_home_lad != "") {
        updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
        updateSelectizeInput(session, "delivery_lad", choices = delivery_lad_choices, server = TRUE)
      }
    })

    # Provider selection ======================================================
    # Create the data used for the table on the left you can select providers from
    prov_selection_table <- reactive({
      prov_selection_table <- lad_map_parquet %>%
        filter(year == input$year)

      # Filter to selected provider if selected
      if (input$provider != "") {
        prov_selection_table <- prov_selection_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_lad != "") {
        prov_selection_table <- prov_selection_table %>% filter(delivery_lad == input$delivery_lad)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_lad != "") {
        prov_selection_table <- prov_selection_table %>% filter(learner_home_lad == input$learner_home_lad)
      }

      # Summarise and aggregate the filtered table
      prov_selection_table <- prov_selection_table %>%
        with_groups(
          "provider_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        collect()

      return(prov_selection_table)
    })

    # Main reactive data ======================================================
    map_data <- reactive({
      lad_map_parquet %>%
        filter(year == input$year) %>%
        collect()
    })

    # Region table data =======================================================
    # Delivery regions --------------------------------------------------------
    delivery_lad_table <- reactive({
      delivery_lad_table <- map_data()

      # Filter to selected provider if selected
      if (input$provider != "") {
        delivery_lad_table <- delivery_lad_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_lad != "") {
        delivery_lad_table <- delivery_lad_table %>% filter(delivery_lad == input$delivery_lad)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_lad != "") {
        delivery_lad_table <- delivery_lad_table %>% filter(learner_home_lad == input$learner_home_lad)
      }

      delivery_lad_table <- delivery_lad_table %>%
        with_groups(
          delivery_lad,
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )
      return(delivery_lad_table)
    })

    # Home regions ------------------------------------------------------------
    learner_home_lad_table <- reactive({
      learner_home_lad_table <- map_data()

      # Filter to selected provider if selected
      if (input$provider != "") {
        learner_home_lad_table <- learner_home_lad_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_lad != "") {
        learner_home_lad_table <- learner_home_lad_table %>% filter(delivery_lad == input$delivery_lad)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_lad != "") {
        learner_home_lad_table <- learner_home_lad_table %>% filter(learner_home_lad == input$learner_home_lad)
      }

      learner_home_lad_table <- learner_home_lad_table %>%
        with_groups(
          learner_home_lad,
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )

      return(learner_home_lad_table)
    })

    # Output tables ===========================================================
    output$prov_selection_table <- renderReactable({
      dfe_reactable(prov_selection_table())
    })

    output$learner_home_lad_table <- renderReactable({
      dfe_reactable(learner_home_lad_table())
    })

    output$delivery_lad_table <- renderReactable({
      dfe_reactable(delivery_lad_table())
    })

    # Create maps =============================================================
    # Reactive data sets used in maps -----------------------------------------
    boundary_data <- reactive({
      # Set the map boundary file based on the year
      boundary_list <- list(
        "2023/24 (Q3 Aug to Apr)" = lad_boundaries_2024,
        "2022/23" = lad_boundaries_2023,
        "2021/22" = lad_boundaries_2022
      )

      # Choose the boundary based on the year selection from the user
      return(boundary_list[[input$year]])
    })

    delivery_map_data <- reactive({
      # Join on the boundary to the data in the delivery LAD table
      boundary_data() %>%
        right_join(delivery_lad_table(), by = join_by("lad_name" == "delivery_lad")) %>%
        sf::st_transform(crs = 4326) # transform coordinates to a system we can use in leaflet maps in the app
    })

    learner_home_map_data <- reactive({
      # Join on the boundary to the data in the delivery LAD table
      boundary_data() %>%
        right_join(learner_home_lad_table(), by = join_by("lad_name" == "learner_home_lad")) %>%
        sf::st_transform(crs = 4326) # transform coordinates to a system we can use in leaflet maps in the app
    })

    # Create the maps themselves ----------------------------------------------
    # dfe_map is defined in R/helper_functions.R
    output$delivery_lad_map <- renderLeaflet({
      dfe_map(delivery_map_data(), input$measure)
    })

    output$learner_home_lad_map <- renderLeaflet({
      dfe_map(learner_home_map_data(), input$measure)
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0("lad-", input$year, "-", input$measure)
        extension <- if (input$file_type == "CSV (Up to 18.42 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 18.42 MB)") {
          data.table::fwrite(map_data(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(map_data(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
