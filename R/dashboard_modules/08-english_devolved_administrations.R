# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
# Change
eda_map_parquet <- arrow::read_parquet("data/eda_map_data_0.parquet") %>%
  select(year, provider_name, learner_home_devolved_administration, delivery_devolved_administration, starts, achievements, enrolments)

# Read in boundary files
# https://geoportal.statistics.gov.uk/datasets/7fdacaa99fce4d299d69f777d6e9c003_0/explore?location=53.383047%2C-2.634220%2C6.69
# https://geoportal.statistics.gov.uk/search?collection=Dataset
# GeoPackage

eda_boundaries_2024 <- sf::st_read("data/boundary_files/Combined_Authorities_May_2023_Boundaries_EN_BUC_8681527703865007386.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
  rename("eda_name" = CAUTH24NM)
eda_boundaries_2023 <- sf::st_read("data/boundary_files/Combined_Authorities_December_2023_Boundaries_EN_BUC_6728220830791984416.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
  rename("eda_name" = CAUTH23NM)
# region_boundaries_2022 <- sf::st_read("data/boundary_files/Local_Authority_Districts_December_2022_UK_BUC_V2_3956567894081366924.gpkg", quiet = TRUE) %>% # nolint: line-length-linter
#  rename("lad_name" = LAD22NM)

# Create static lists of options for dropdowns

eda_year_choices <- data_choices(data = eda_map_parquet, column = "year")
# Years should be in descending order order
eda_year_choices <- sort(eda_year_choices, decreasing = TRUE)

eda_measure_choices <- c("Starts", "Enrolments", "Achievements")

provider_choices <- c("", distinct(eda_map_parquet, provider_name) %>% pull())
# Providers should be in alphabetical order
provider_choices <- sort(provider_choices)

delivery_eda_choices <- c("", distinct(eda_map_parquet, delivery_devolved_administration) %>% pull())
delivery_eda_choices <- sort(delivery_eda_choices)

learner_home_eda_choices <- c("", distinct(eda_map_parquet, learner_home_devolved_administration) %>% pull())
learner_home_eda_choices <- sort(learner_home_eda_choices)

# Main module code ============================================================
eda_ui <- function(id) {
  div(
    h1("English Devolved Area breakdowns"),
    # User selection area =====================================================
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        selectInput(
          inputId = NS(id, "measure"),
          label = "Select measure",
          choices = firstup(eda_measure_choices)
        ),
        selectInput(
          inputId = NS(id, "year"),
          label = "Select academic year",
          choices = eda_year_choices
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
          inputId = NS(id, "delivery_devolved_administration"),
          label = "Search for a delivery devolved_administration",
          choices = NULL,
          options = list(dropdownParent = "body") # force dropdown menu to be in front of other objects
        ),
        selectizeInput(
          inputId = NS(id, "learner_home_devolved_administration"),
          label = "Search for a learner home devolved_administration",
          choices = NULL,
          options = list(dropdownParent = "body") # force dropdown menu to be in front of other objects
        )
      )
    ),
    layout_columns(
      col_widths = c(4, 8),
      ## Provider selection table ---------------------------------------------
      card(reactable::reactableOutput(NS(id, "prov_selection_table"))),
      ## Tabs -----------------------------------------------------------------
      navset_card_tab(
        id = "eda_maps_tabs",
        nav_panel(
          "Maps",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            div(
              h2("Delivery map"),
              leafletOutput(NS(id, "delivery_eda_map"), height = 600)
            ),
            div(
              h2("Learner home map"),
              leafletOutput(NS(id, "learner_home_eda_map"), height = 600)
            )
          )
        ),
        nav_panel(
          "Tables",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            reactable::reactableOutput(NS(id, "delivery_eda_table")),
            reactable::reactableOutput(NS(id, "learner_home_eda_table"))
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

eda_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # Drop downs ==============================================================
    # Set initial dropdown values
    updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
    updateSelectizeInput(session, "delivery_devolved_administration", choices = delivery_eda_choices, server = TRUE)
    updateSelectizeInput(session, "learner_home_devolved_administration", choices = learner_home_eda_choices, server = TRUE)

    # Update dropdown lists, clearing out when other options are selected
    observeEvent(input$provider, {
      if (input$provider != "") {
        updateSelectizeInput(session, "delivery_devolved_administration", choices = delivery_eda_choices, server = TRUE)
        updateSelectizeInput(session, "learner_home_devolved_administration", choices = learner_home_eda_choices, server = TRUE)
      }
    })

    observeEvent(input$delivery_eda, {
      if (input$delivery_eda != "") {
        updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
        updateSelectizeInput(session, "learner_home_devolved_administration", choices = learner_home_eda_choices, server = TRUE)
      }
    })

    observeEvent(input$learner_home_eda, {
      if (input$learner_home_eda != "") {
        updateSelectizeInput(session, "provider", choices = provider_choices, server = TRUE)
        updateSelectizeInput(session, "delivery_devolved_administration", choices = delivery_eda_choices, server = TRUE)
      }
    })

    # User map selection ------------------------------------------------------
    # While the maps themselves are defined elsewhere, if a user selects an LAD from a map, we capture the value here
    # and then pass into the dropdown as if the user had selected that LAD from the dropdown itself
    # all of the flushing of other values happens automatically when the calculations are rerun
    #
    # The 'id' that we pull here pulls from what we set as the 'layerId' in the map function
    observeEvent(input$delivery_eda_map_shape_click, {
      map_selected_delivery_eda <- input$delivery_eda_map_shape_click
      updateSelectizeInput(session, "delivery_devolved_administration", selected = map_selected_delivery_eda$id)
    })

    observeEvent(input$learner_home_eda_map_shape_click, {
      map_selected_learner_home_eda <- input$learner_home_eda_map_shape_click
      updateSelectizeInput(session, "learner_home_devolved_administration", selected = map_selected_learner_home_eda$id)
    })

    # Provider selection ======================================================
    # Create the data used for the table on the left you can select providers from
    prov_selection_table <- reactive({
      prov_selection_table <- eda_map_parquet %>%
        filter(year == input$year)

      # Filter to selected provider if selected
      if (input$provider != "") {
        prov_selection_table <- prov_selection_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_eda != "") {
        prov_selection_table <- prov_selection_table %>% filter(delivery_eda == input$delivery_eda)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_eda != "") {
        prov_selection_table <- prov_selection_table %>% filter(learner_home_eda == input$learner_home_eda)
      }

      # Summarise and aggregate the filtered table
      prov_selection_table <- prov_selection_table %>%
        with_groups(
          "provider_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        collect()

      return(prov_selection_table)
    })

    # Main reactive data ======================================================
    map_data <- reactive({
      eda_map_parquet %>%
        filter(year == input$year) %>%
        collect()
    })

    # Region table data =======================================================
    # Delivery regions --------------------------------------------------------
    delivery_eda_table <- reactive({
      delivery_eda_table <- map_data()

      # Filter to selected provider if selected
      if (input$provider != "") {
        delivery_eda_table <- delivery_eda_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_eda != "") {
        delivery_eda_table <- delivery_eda_table %>% filter(delivery_eda == input$delivery_eda)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_eda != "") {
        delivery_eda_table <- delivery_eda_table %>% filter(learner_home_eda == input$learner_home_eda)
      }

      delivery_eda_table <- delivery_eda_table %>%
        with_groups(
          delivery_eda,
          summarise,
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        filter(`Number of apprenticeships` != 0)

      return(delivery_eda_table)
    })

    # Home regions ------------------------------------------------------------
    learner_home_eda_table <- reactive({
      learner_home_eda_table <- map_data()

      # Filter to selected provider if selected
      if (input$provider != "") {
        learner_home_eda_table <- learner_home_eda_table %>% filter(provider_name == input$provider)
      }

      # Filter based on delivery LAD if selected
      if (input$delivery_eda != "") {
        learner_home_eda_table <- learner_home_eda_table %>% filter(delivery_eda == input$delivery_eda)
      }

      # Filter based on learner home LAD if selected
      if (input$learner_home_eda != "") {
        learner_home_eda_table <- learner_home_eda_table %>% filter(learner_home_eda == input$learner_home_eda)
      }

      learner_home_eda_table <- learner_home_eda_table %>%
        with_groups(
          learner_home_eda,
          summarise,
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        filter(`Number of apprenticeships` != 0)

      return(learner_home_eda_table)
    })

    # Output tables ===========================================================
    output$prov_selection_table <- renderReactable({
      dfe_reactable(prov_selection_table())
    })

    output$learner_home_eda_table <- renderReactable({
      validate(need(nrow(learner_home_eda_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_reactable(learner_home_eda_table())
    })

    output$delivery_eda_table <- renderReactable({
      validate(need(nrow(delivery_eda_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_reactable(delivery_eda_table())
    })

    # Create maps =============================================================
    # Reactive data sets used in maps -----------------------------------------
    boundary_data <- reactive({
      # Set the map boundary file based on the year
      boundary_list <- list(
        "2023/24 (Q3 Aug to Apr)" = eda_boundaries_2024,
        "2022/23" = eda_boundaries_2023,
        "2021/22" = eda_boundaries_2023
      )

      # Choose the boundary based on the year selection from the user
      return(boundary_list[[input$year]])
    })

    delivery_map_data <- reactive({
      # Join on the boundary to the data in the delivery LAD table
      boundary_data() %>%
        right_join(delivery_eda_table(), by = join_by("eda_name" == "delivery_eda")) %>%
        sf::st_transform(crs = 4326) # transform coordinates to a system we can use in leaflet maps in the app
    })

    learner_home_map_data <- reactive({
      # Join on the boundary to the data in the delivery LAD table / does learner_home_map_data need to be unique to geographies - Qu for Cam !!
      boundary_data() %>%
        right_join(learner_home_eda_table(), by = join_by("eda_name" == "learner_home_eda")) %>%
        sf::st_transform(crs = 4326) # transform coordinates to a system we can use in leaflet maps in the app
    })

    # Create the maps themselves ----------------------------------------------
    # dfe_lad_map is defined in R/helper_functions.R
    output$delivery_eda_map <- renderLeaflet({
      validate(need(nrow(delivery_eda_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_eda_map(delivery_map_data(), input$measure, NS(id, "delivery_eda"))
    })

    output$learner_home_eda_map <- renderLeaflet({
      validate(need(nrow(learner_home_eda_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_eda_map(learner_home_map_data(), input$measure, NS(id, "learner_home_eda"))
    })

    # Watch for the reset buttons and clear selection if pressed
    observeEvent(input$delivery_eda_reset, {
      updateSelectizeInput(session, "delivery_eda", selected = "")
    })

    observeEvent(input$learner_home_eda_reset, {
      updateSelectizeInput(session, "learner_home_eda", selected = "")
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0("eda-", input$year, "-", input$measure)
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
