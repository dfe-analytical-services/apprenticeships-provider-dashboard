# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
lad_prov_parquet <- read_lad("data/apprenticeships_data_0.parquet") # TODO: use a cut down version of the data
lad_map_parquet <- read_lad_map("data/lad_maps.parquet") %>%
  pivot_longer(
    cols = c(
      "starts_delivery", "enrolments_delivery", "achievements_delivery",
      "starts_learner", "enrolments_learner", "achievements_learner"
    ),
    names_to = c(".value", "lad_type"),
    names_sep = "_"
  )

# Create static lists of options for dropdowns
lad_year_choices <- data_choices(data = lad_map_parquet, column = "year")
lad_measure_choices <- c("achievements", "enrolments", "starts") # TODO: would like to capitalise eventually

# Main module code ============================================================

lad_ui <- function(id) {
  div(
    h1("Local authority district"),
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
      )
    ),
    # Main data area ==========================================================
    # TODO: Make separate search boxes above the tabs?
    # TODO: Does search reset when you move tabs?
    layout_columns(
      col_widths = c(3, 9),
      ## Provider selection table ---------------------------------------------
      card(reactable::reactableOutput(NS(id, "prov_selection_table"))),
      ## Maps and tables and download -----------------------------------------
      navset_card_tab(
        id = "lad_maps_tabs",
        nav_panel(
          "Maps",
          bslib::layout_column_wrap(
            width = "15rem", # Minimum width for each input box before wrapping
            leafletOutput(NS(id, "delivery_lad_map")),
            leafletOutput(NS(id, "learner_home_lad_map"))
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
              "This will download all data related to the providers and options selected.",
              " The XLSX format is designed for use in Microsoft Excel."
            ),
            choices = c("CSV (Up to X MB)", "XLSX (Up to X MB)"),
            selected = "CSV (Up to X MB)"
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
    # Provider selection ======================================================
    # Create the data used for the table on the left you can select providers from
    prov_selection_table <- reactive({
      lad_prov_parquet %>%
        filter(year == input$year) %>%
        with_groups(
          "provider_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        ) %>%
        collect()
    })

    # Create the table itself
    output$prov_selection_table <- renderReactable({
      dfe_reactable(
        prov_selection_table(),
        on_click = "select",
        selection = "multiple",
        row_style = list(cursor = "pointer"),
        searchable = TRUE
      )
    })

    # Get the selections from the provider table
    selected_providers <- reactive({
      selected <- getReactableState("prov_selection_table", "selected")
      if (length(selected) == 0) {
        # Return the full data of all providers if nothing selected from the table
        # use.names = FALSE is used as it is much faster to process and we don't name the items
        return(unlist(prov_selection_table()[, 1], use.names = FALSE))
      }

      # Filter to only the selected providers
      # Convert to a vector of provider names to use for filtering elsewhere
      unlist(prov_selection_table()[selected, 1], use.names = FALSE)
    })

    # Reactive data set =======================================================
    map_data <- reactive({
      lad_map_parquet %>%
        filter(year == input$year)
    })


    # Region tables ===========================================================
    # Delivery regions --------------------------------------------------------
    delivery_lad_table <- reactive({
      map_data() %>%
        filter(lad_type == "delivery") %>%
        with_groups(
          "lad_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )
    })

    output$delivery_lad_table <- renderReactable({
      dfe_reactable(delivery_lad_table())
    })

    # Home regions ------------------------------------------------------------
    learner_home_lad_table <- reactive({
      map_data() %>%
        filter(lad_type == "learner") %>%
        with_groups(
          "lad_name",
          summarise,
          `Number of apprenticeships` = sum(!!sym(input$measure), na.rm = TRUE)
        )
    })

    output$learner_home_lad_table <- renderReactable({
      dfe_reactable(learner_home_lad_table())
    })

    # Create maps =============================================================

    # Create the delivery map
    # output$delivery_lad_map <- renderLeaflet({
    #   # Set the color scheme and scale
    #   pal_fun <- colorNumeric(
    #     "Blues",
    #     domain = c(
    #       min(map_data$example_count),
    #       max(map_data$example_count)
    #     )
    #   )
    #
    #   # Set a pop up
    #   map_popup <- paste(
    #     map_data$example_count,
    #     " example count for ",
    #     map_data$lsip_name
    #   )
    #
    #   # Create the map
    #   map <- leaflet(
    #     map_data,
    #     # Take off annoying scrolling, personal preference
    #     options = leafletOptions(scrollWheelZoom = FALSE)
    #   ) %>%
    #     # Set the basemap (this is a good neutral one)
    #     addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    #     # Add the shaded regions
    #     addPolygons(
    #       color = "black",
    #       weight = 1,
    #       fillColor = pal_fun(map_data[["example_count"]]),
    #       popup = map_popup
    #     ) %>%
    #     # Add a legend to the map
    #     addLegend("topright",
    #               pal = pal_fun,
    #               values = ~map_data[["example_count"]],
    #               title = "Example map title"
    #     )
    # })
  })
}
