# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
lad_map_parquet <- arrow::read_parquet("data/lad_map_data_0.parquet") %>%
  select(year, provider_name, learner_home_lad, delivery_lad, starts, achievements, enrolments)

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

lad_measure_choices <- c("Starts", "Enrolments", "Achievements")

provider_choices <- c("", distinct(lad_map_parquet, provider_name) %>% pull())
# Providers should be in alphabetical order
provider_choices <- sort(provider_choices)

delivery_lad_choices <- c("", distinct(lad_map_parquet, delivery_lad) %>% pull())
delivery_lad_choices <- sort(delivery_lad_choices)

learner_home_lad_choices <- c("", distinct(lad_map_parquet, learner_home_lad) %>% pull())
learner_home_lad_choices <- sort(learner_home_lad_choices)

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
          choices = firstup(lad_measure_choices)
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
          choices = NULL,
          options = list(dropdownParent = "body") # force dropdown menu to be in front of other objects
        ),
        selectizeInput(
          inputId = NS(id, "learner_home_lad"),
          label = "Search for a learner home LAD",
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
        id = "lad_maps_tabs",
        nav_panel(
          "Maps",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            div(
              h2("Delivery map"),
              leafletOutput(NS(id, "delivery_lad_map"), height = 600)
            ),
            div(
              h2("Learner home map"),
              leafletOutput(NS(id, "learner_home_lad_map"), height = 600)
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
              "This will download data for all local authority districts based on the ",
              "year and provider selected. The XLSX format is designed for use in Microsoft Excel."
            ),
            choices = c("CSV (Up to 16.66 MB)", "XLSX (Up to 5.97 MB)"),
            selected = "CSV (Up to 16.66 MB)"
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

    # User map selection ------------------------------------------------------
    # While the maps themselves are defined elsewhere, if a user selects an LAD from a map, we capture the value here
    # and then pass into the dropdown as if the user had selected that LAD from the dropdown itself
    # all of the flushing of other values happens automatically when the calculations are rerun
    #
    # The 'id' that we pull here pulls from what we set as the 'layerId' in the map function
    observeEvent(input$delivery_lad_map_shape_click, {
      map_selected_delivery_lad <- input$delivery_lad_map_shape_click
      updateSelectizeInput(session, "delivery_lad", selected = map_selected_delivery_lad$id)
    })

    observeEvent(input$learner_home_lad_map_shape_click, {
      map_selected_learner_home_lad <- input$learner_home_lad_map_shape_click
      updateSelectizeInput(session, "learner_home_lad", selected = map_selected_learner_home_lad$id)
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
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
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
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        filter(`Number of apprenticeships` != 0)

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
          `Number of apprenticeships` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        filter(`Number of apprenticeships` != 0)

      return(learner_home_lad_table)
    })

    # Output tables ===========================================================
    output$prov_selection_table <- renderReactable({
      dfe_reactable(prov_selection_table())
    })

    output$learner_home_lad_table <- renderReactable({
      validate(need(nrow(learner_home_lad_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_reactable(learner_home_lad_table())
    })

    output$delivery_lad_table <- renderReactable({
      validate(need(nrow(delivery_lad_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_reactable(delivery_lad_table())
    })

    # Create maps =============================================================
    # Reactive data sets used in maps -----------------------------------------
    boundary_data <- reactive({
      # Set the map boundary file based on the year
      # this would be better not hard coded - values change for the latest year according to qr
      # have made sure in the code below that the quarter doesn't matter
      # don't want to further hard code as this will change as boundaries change
      # want to stay aware of this
      # lad_boundaries_2024 is OK for Q1 2024/25 - no empty LADs
      # as soon as empty LADs appear, need to update

      boundary_list <- list(
        "2024/25" = lad_boundaries_2024,
        "2023/24" = lad_boundaries_2024,
        "2022/23" = lad_boundaries_2023
      )

      # Choose the boundary based on the year selection from the user
      # think this will sort the hard -coding for the boundary list
      # will match to the first bit of the string - just the academic year & not qr
      return(boundary_list[[substring(input$year, 1, 7)]])
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
    # dfe_lad_map is defined in R/helper_functions.R
    output$delivery_lad_map <- renderLeaflet({
      validate(need(nrow(delivery_lad_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_lad_map(delivery_map_data(), input$measure, NS(id, "delivery_lad"))
    })

    output$learner_home_lad_map <- renderLeaflet({
      validate(need(nrow(learner_home_lad_table()) > 0, paste0("No ", input$measure, " for these selections.")))

      dfe_lad_map(learner_home_map_data(), input$measure, NS(id, "learner_home_lad"))
    })

    # Watch for the reset buttons and clear selection if pressed
    observeEvent(input$delivery_lad_reset, {
      updateSelectizeInput(session, "delivery_lad", selected = "")
    })

    observeEvent(input$learner_home_lad_reset, {
      updateSelectizeInput(session, "learner_home_lad", selected = "")
    })
    # Data download ===========================================================
    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0("lad-", input$year, "-", input$provider)
        extension <- if (input$file_type == "CSV (Up to 16.66 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 16.66 MB)" & input$provider == "") {
          data.table::fwrite(map_data(), file)
        } else if (input$file_type == "CSV (Up to16.66 MB)" & input$provider != "") {
          data.table::fwrite(map_data() %>%
            filter(year %in% input$year) %>%
            filter(provider_name %in% input$provider), file)
        } else if (input$file_type == "XLSX (Up to 5.97 KB)" & input$provider != "") {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(map_data() %>%
            filter(year %in% input$year) %>%
            filter(provider_name %in% input$provider), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        } else {
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(map_data() %>%
            filter(year %in% input$year), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
