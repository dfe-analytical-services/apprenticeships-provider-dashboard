# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
prov_breakdowns_parquet <- arrow::read_parquet("data/provider_breakdowns_0.parquet")

# Create static lists of options for dropdowns
apps_measure_choices <- c("Starts", "Enrolments", "Achievements")
apps_prov_type_choices <- data_choices(data = prov_breakdowns_parquet, column = "provider_type")
apps_year_choices <- sort(data_choices(data = prov_breakdowns_parquet, column = "year"),
  decreasing = TRUE
)
apps_level_choices <- data_choices(data = prov_breakdowns_parquet, column = "apps_Level")
apps_age_choices <- data_choices(data = prov_breakdowns_parquet, column = "age_group")

# Create static list of regions to set the order for the region tables and use in the user selections
regions <- c(
  "North East", "North West", "Yorkshire and The Humber", "East Midlands", "West Midlands", "East of England",
  "London", "South East", "South West", "Outside of England and unknown"
)

# Main module code ============================================================

prov_breakdowns_ui <- function(id) {
  div(
    # Page header =============================================================
    h1("Provider breakdowns"),
    # User selection area ===================================================
    column(
      width = 12,
      div(
        class = "well",
        bslib::layout_column_wrap(
          width = "15rem", # Minimum width for each input box before wrapping
          selectInput(
            inputId = NS(id, "measure"),
            label = "Select measure",
            choices = apps_measure_choices
          ),
          selectInput(
            inputId = NS(id, "prov_type"),
            label = "Select provider type",
            choices = c("All provider types", apps_prov_type_choices)
          ),
          selectInput(
            inputId = NS(id, "year"),
            label = "Select academic year",
            choices = apps_year_choices
          ),
          selectInput(
            inputId = NS(id, "level"),
            label = "Select level",
            choices = c("All levels", apps_level_choices)
          ),
          selectInput(
            inputId = NS(id, "age"),
            label = "Select age group",
            choices = c("All age groups", apps_age_choices)
          )
        )
      ),
      layout_columns(
        col_widths = c(4, 8),
        ## Provider table -------------------------------------------------------
        card(reactable::reactableOutput(NS(id, "prov_selection"))),
        ## Tabs on right --------------------------------------------------------
        navset_card_tab(
          id = "provider_breakdown_tabs",
          nav_panel(
            "Bar chart",
            girafeOutput(NS(id, "regions_bar")),
          ),
          nav_panel(
            "Tables",
            bslib::layout_column_wrap(
              reactable::reactableOutput(NS(id, "delivery_region")),
              reactable::reactableOutput(NS(id, "home_region"))
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
  )
}

prov_breakdowns_server <- function(id) { # nolint: cyclocomp_linter
  shiny::moduleServer(id, function(input, output, session) {
    # Main data ===============================================================
    # Main data set for use in charts / tables / download
    # This reads in the raw data and applies the filters from the dropdowns
    filtered_raw_data <- reactive({
      filtered_raw_data <- prov_breakdowns_parquet %>%
        filter(year == input$year)

      # Only filtering these if needed, by default we want all returned
      if (input$prov_type != "All provider types") {
        filtered_raw_data <- filtered_raw_data %>% filter(provider_type %in% input$prov_type)
      }
      if (input$level != "All levels") {
        filtered_raw_data <- filtered_raw_data %>% filter(apps_Level %in% input$level)
      }
      if (input$age != "All age groups") {
        filtered_raw_data <- filtered_raw_data %>% filter(age_group == input$age)
      }

      return(filtered_raw_data)
    })

    # User selections =========================================================
    # Here we get the user selections from the tables to then use to filter the table reactive data sets

    # Provider table selections -----------------------------------------------
    selected_providers <- reactive({
      # Filter to only the selected providers and convert to a vector to use for filtering elsewhere
      unlist(prov_selection_table()[getReactableState("prov_selection", "selected"), 1], use.names = FALSE)
    })

    # Region table selections -------------------------------------------------
    selected_learner_home_region <- reactive({
      # Filter to only the selected region using the vector at the top of the script
      return(regions[getReactableState("home_region", "selected")])
    })

    selected_delivery_region <- reactive({
      # Filter to only the selected region using the vector at the top of the script
      return(regions[getReactableState("delivery_region", "selected")])
    })

    # Table reactive data =====================================================
    ## Provider data ----------------------------------------------------------
    prov_selection_table <- reactive({
      prov_selection_table <- filtered_raw_data()

      # Filter to learner home region selection if it exists
      if (length(selected_learner_home_region()) == 1) {
        prov_selection_table <- prov_selection_table %>% filter(learner_home_region == selected_learner_home_region())
      }

      # Filter to delivery region selection if it exists
      if (length(selected_delivery_region()) == 1) {
        prov_selection_table <- prov_selection_table %>% filter(delivery_region == selected_delivery_region())
      }

      prov_selection_table <- prov_selection_table %>%
        with_groups(
          "provider_name",
          summarise,
          `number` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        rename("Provider name" = provider_name) %>%
        rename_with(~ paste("Number of", firstlow(input$measure)), `number`) %>%
        collect()

      return(prov_selection_table)
    }) %>%
      # Set the dependent variables that will trigger this table to update
      bindEvent(
        firstlow(input$measure), filtered_raw_data(), selected_learner_home_region(),
        selected_delivery_region()
      )

    ## Delivery region data ---------------------------------------------------
    delivery_region_table <- reactive({
      # Start with the filtered data
      delivery_region_table <- filtered_raw_data()

      # Filter down provider list there is something selected from the providers
      if (length(selected_providers() != 0)) {
        delivery_region_table <- delivery_region_table %>% filter(provider_name %in% selected_providers())
      }

      # Filter to learner home region selection if it exists
      if (length(selected_learner_home_region()) == 1) {
        delivery_region_table <- delivery_region_table %>% filter(learner_home_region == selected_learner_home_region())
      }

      delivery_region_table <- delivery_region_table %>%
        with_groups(
          "delivery_region",
          summarise,
          `number` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        rename("Delivery region" = delivery_region)

      # Make sure all regions have a row even if 0
      # Regions vector defined at top of this script
      delivery_region_table <- tibble(`Delivery region` = regions) %>%
        left_join(delivery_region_table, by = "Delivery region") %>%
        mutate(across(
          number,
          ~ replace_na(., 0)
        )) %>%
        collect()

      return(delivery_region_table)
    }) %>%
      bindEvent(firstlow(input$measure), filtered_raw_data(), selected_providers())

    ## Home region data -------------------------------------------------------
    home_region_table <- reactive({
      # Start with the filtered data
      home_region_table <- filtered_raw_data()

      # Filter down provider list there is something selected from the providers
      if (length(selected_providers() != 0)) {
        home_region_table <- home_region_table %>% filter(provider_name %in% selected_providers())
      }

      # Filter to delivery region selection if it exists
      if (length(selected_delivery_region()) == 1) {
        home_region_table <- home_region_table %>% filter(delivery_region == selected_delivery_region())
      }

      home_region_table <- home_region_table %>%
        with_groups(
          "learner_home_region",
          summarise,
          `number` = sum(!!sym(firstlow(input$measure)), na.rm = TRUE)
        ) %>%
        rename("Learner home region" = learner_home_region)

      # Make sure all regions have a row even if 0
      # Regions vector defined at top of this script
      home_region_table <- tibble(`Learner home region` = regions) %>%
        left_join(home_region_table, by = "Learner home region") %>%
        mutate(across(
          number,
          ~ replace_na(., 0)
        )) %>%
        collect()

      return(home_region_table)
    }) %>%
      bindEvent(firstlow(input$measure), filtered_raw_data(), selected_providers())

    # Bar chart data ----------------------------------------------------------
    regions_bar_data <- reactive({
      learner_home <- home_region_table() |>
        rename(
          "Region" = `Learner home region`,
          "Learner home" = number
        )

      delivery <- delivery_region_table() |>
        rename(
          "Region" = `Delivery region`,
          "Delivery" = number
        )

      # Pivot the data so there's 3 columns, region, delivery / learner as a filter, and count
      regions_bar_data <- left_join(learner_home, delivery, by = "Region") |>
        tidyr::pivot_longer(
          cols = c(`Learner home`, `Delivery`),
          names_to = "type",
          values_to = "count"
        )

      # Force the ordering of the regions
      regions_bar_data$Region <- forcats::fct_rev(factor(regions_bar_data$Region, levels = regions))

      # Create a unique column used for the hover on each bar
      regions_bar_data$data_id <- paste(regions_bar_data$Region, regions_bar_data$type, sep = "_")

      return(regions_bar_data)
    })

    # Bar chart output object =================================================
    # Get the selected region and return in a form that matches the id's used in the chart
    # This is then used to show which region is currently selected from the tables
    selected_region <- reactive({
      # We know only one of the two can be selected in the tables at once so we can cheat a bit with our logic here
      # Filter to delivery region selection if it exists
      if (length(selected_delivery_region()) == 1) {
        return(paste0(selected_delivery_region(), "_Delivery"))
      } else {
        # Filter to learner home region selection if it exists, if it doesn't then it returns _Leaner home
        # which won't match an id in the chart and will act as if nothing is selected
        return(paste0(selected_learner_home_region(), "_Learner home"))
      }
    })

    output$regions_bar <- renderGirafe(
      girafe(
        ggobj =
          regions_bar_data() %>%
            ggplot(
              aes(
                fill = type,
                x = Region,
                y = count,
                tooltip = paste(
                  lapply(count, dfeR::pretty_num), firstlow(input$measure), "<br>",
                  type, "in", Region
                ),
                data_id = data_id
              )
            ) +
            # Make it an interactive, clustered, bar
            geom_bar_interactive(position = "dodge", stat = "identity") +
            # Make it horizontal
            coord_flip() +
            # Axis labels
            xlab("") +
            ylab(input$measure) +
            # Set the colours
            scale_fill_manual(values = c(
              "Learner home" = afcolours::af_colours(n = 4)[1],
              "Delivery" = afcolours::af_colours(n = 4)[4]
            )) +
            # Format the x-axis numbers (using the Y function as we've flipped to horizontal!)
            scale_y_continuous(labels = dfeR::comma_sep) +
            # Wrap y-axis labels (set so East of England and longer will wrap onto multiple lines)
            scale_x_discrete(labels = function(x) str_wrap(x, width = 13)) +
            # Custom theme
            # TODO: extract list of this to reuse in dfeshiny
            ggplot2::theme_minimal() +
            ggplot2::theme(
              legend.position = "top",
              legend.title = element_blank(),
              panel.grid = element_blank(),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              axis.title.x = element_text(family = "Arial", size = 10, face = "bold", margin = margin(t = 10)),
              axis.text.x = element_text(family = "Arial", size = 10),
              axis.text.y = element_text(family = "Arial", size = 10)
            ),
        # TODO: break out custom options to function to reuse for dfeshiny
        options = list(
          # Turn off toolbar options (as they're bad for accessibility / confusing for users)
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          ),
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:2px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "single",
            selected = selected_region(),
            css = "cursor:pointer;stroke:black;stroke-width:2px;fill:#ffdd00;"
          )
        ),
        fonts = list(sans = "Arial")
      )
    )

    # Table output objects ====================================================
    output$prov_selection <- renderReactable({
      dfe_reactable(
        prov_selection_table(),
        on_click = "select",
        selection = "multiple",
        row_style = list(cursor = "pointer"),
        searchable = TRUE
      )
    })

    output$delivery_region <- renderReactable({
      dfe_reactable(
        delivery_region_table() |>
          rename_with(~ paste("Number of", firstlow(input$measure)), `number`),
        on_click = "select",
        selection = "single",
        row_style = list(cursor = "pointer")
      )
    })

    output$home_region <- renderReactable({
      dfe_reactable(
        home_region_table() |>
          rename_with(~ paste("Number of", firstlow(input$measure)), `number`),
        on_click = "select",
        selection = "single",
        row_style = list(cursor = "pointer")
      )
    })

    # Data download ===========================================================
    output$download_data <- downloadHandler(
      # This currently just downloads the filtered raw data, which doesn't react to any
      # selections made from the tables made by users

      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(input$year, "-", input$level, "-", input$age, "-provider_breakdowns")
        extension <- if (input$file_type == "CSV (Up to X MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to X MB)") {
          data.table::fwrite(filtered_raw_data(), file)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(filtered_raw_data(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
