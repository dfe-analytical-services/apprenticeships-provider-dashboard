# Load data ===================================================================
# Functions used here are created in the R/read_data.R file
chars_parquet <- arrow::read_parquet("data/apprenticeships_demographics_0.parquet")

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

# create lists for ordering the bar charts
chars_parquet_age <- chars_parquet %>% filter(characteristic_type == "Age" & characteristic != "Total")
chars_age_choices <- data_choices(data = chars_parquet_age, column = "characteristic")

chars_parquet_sex <- chars_parquet %>% filter(characteristic_type == "Sex" & characteristic != "Total")
chars_sex_choices <- data_choices(data = chars_parquet_sex, column = "characteristic")

chars_parquet_lldd <- chars_parquet %>% filter(characteristic_type ==
  "Learner with learning difficulties or disabilities (LLDD)" & characteristic != "Total")
chars_lldd_choices <- data_choices(data = chars_parquet_lldd, column = "characteristic")

chars_parquet_ethnicity <- chars_parquet %>% filter(characteristic_type == "Ethnicity" & characteristic != "Total")
chars_ethnicity_choices <- data_choices(data = chars_parquet_ethnicity, column = "characteristic")

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
      )
    ),

    # Main table ==============================================================
    navset_card_tab(
      id = "provider_learner_characteristics",
      ##  plot tab ------------------------------------------------------------
      nav_panel(
        "Charts",
        layout_columns(
          col_widths = c(3, 3, 3, 3),
          girafeOutput(NS(id, "age_bar_plot")),
          girafeOutput(NS(id, "sex_bar_plot")),
          girafeOutput(NS(id, "lldd_bar_plot")),
          girafeOutput(NS(id, "ethnicity_bar_plot")),
        )
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
          hint_label = "Selecting a provider will download the data relating to
          that provider and selections. Selecting Total (all providers) will download
          data for all providers relating to the selected year and measure.
          The XLSX format is designed for use in Microsoft Excel.",
          choices = c("CSV (Up to 2.13 MB)", "XLSX (Up to 515.75 KB)"),
          selected = "CSV (Up to 2.13 MB)"
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

    # plot

    output$age_bar_plot <- renderGirafe({
      # Message when there are none of the measure at all
      validate(need(nrow(chars_reactive_table()) > 0, paste0("No ", firstlow(input$measure), " for these selections.")))

      # Message when all groups are low, and chart cannot be displayed
      # But can still be seen in the table
      validate(need(
        nrow(filter(chars_reactive_table(), characteristic_type == "Age" & count != "low" &
          characteristic != "Total")) > 0, paste0("All age groups have low numbers.")
      ))

      girafe(
        ggobj =
          chars_reactive_table() %>%
            filter(characteristic_type == "Age" & characteristic != "Total") %>%
            # need data in all categories else columns expand if missing data
            mutate(count = ifelse(count == "low", "0", count)) %>%
            ggplot(aes(
              x = characteristic,
              y = as.numeric(count),
              tooltip = paste0(characteristic, ": ", dfeR::comma_sep(as.numeric(count)), " ", firstlow(input$measure)),
              data_id = characteristic
            )) +
            geom_col_interactive(
              fill = afcolours::af_colours(n = 4)[1],
              position = position_dodge(preserve = "single")
            ) +
            coord_flip() +
            labs(title = "Age") +
            xlab("") +
            ylab("") +
            scale_y_continuous(labels = dfeR::comma_sep) +
            scale_x_discrete(
              labels = function(x) str_wrap(x, width = 10),
              limit = rev(chars_age_choices)
            ) +
            ggplot2::theme_minimal() +
            ggplot2::theme(
              legend.position = "top",
              legend.title = element_blank(),
              panel.grid = element_blank(),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              plot.title = element_text(family = "Arial", face = "bold", size = 20, hjust = 0),
              axis.text.x = element_text(family = "Arial", size = 15),
              axis.text.y = element_text(family = "Arial", size = 20)
            ),
        options = list(
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:5px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "single", css = "fill:#12436D;stroke:#12436D;"
          ),
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          )
        ),
        fonts = list(sans = "Arial")
      )
    })

    output$sex_bar_plot <- renderGirafe({
      # Message when there are none of the measure at all - blank - only shown for age
      validate(need(nrow(chars_reactive_table()) > 0, ""))

      # Message when all groups are low, and chart cannot be displayed
      # But can still be seen in the table
      validate(need(
        nrow(filter(chars_reactive_table(), characteristic_type == "Sex" & count != "low" &
          characteristic != "Total")) > 0,
        "Males and females both have low numbers."
      ))

      girafe(
        ggobj =
          chars_reactive_table() %>%
            filter(characteristic_type == "Sex" & characteristic != "Total") %>%
            # need data in all categories else columns expand if missing data
            mutate(count = ifelse(count == "low", "0", count)) %>%
            ggplot(aes(x = "", y = as.numeric(count), fill = characteristic)) +
            geom_col_interactive(aes(
              tooltip = paste0(characteristic, ": ", dfeR::comma_sep(as.numeric(count)), " ", firstlow(input$measure)),
              data_id = characteristic
            ), color = "white", size = 2, ) +
            coord_polar(theta = "y", start = 0) +
            scale_fill_manual(breaks = c("Male", "Female"), values = afcolours::af_colours("duo")) +
            scale_y_discrete(limit = rev(chars_sex_choices)) +
            labs(title = "Sex") +
            xlab("") +
            ylab("") +
            #  scale_y_continuous(labels = dfeR::comma_sep) +
            ggplot2::theme_void() +
            ggplot2::theme(
              legend.position = "bottom",
              legend.title = element_blank(),
              legend.text = element_text(family = "Arial", size = 15),
              plot.title = element_text(family = "Arial", face = "bold", size = 20, hjust = 0)
            ),
        options = list(
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:5px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "single", css = "fill:afcolours::af_colours;stroke:afcolours::af_colours;"
          ),
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          )
        ),
        fonts = list(sans = "Arial")
      )
    })



    output$lldd_bar_plot <- renderGirafe({
      # Message when there are none of the measure at all - blank - only shown for age
      validate(need(nrow(chars_reactive_table()) > 0, ""))

      # Message when all groups are low, and chart cannot be displayed
      # But can still be seen in the table
      validate(need(
        nrow(filter(chars_reactive_table(), characteristic_type ==
          "Learner with learning difficulties or disabilities (LLDD)" &
          count != "low" & characteristic != "Total")) > 0, "All LLDD groups have low numbers."
      ))

      girafe(
        ggobj =
          chars_reactive_table() %>%
            filter(characteristic_type == "Learner with learning difficulties or disabilities (LLDD)" &
              characteristic != "Total") %>%
            # need data in all categories else columns expand if missing data
            mutate(count = ifelse(count == "low", "0", count)) %>%
            ggplot(aes(
              x = characteristic,
              y = as.numeric(count),
              tooltip = paste0(
                characteristic, ": ", dfeR::comma_sep(as.numeric(count)), " ",
                firstlow(input$measure)
              ),
              data_id = characteristic
            )) +
            geom_col_interactive(
              fill = afcolours::af_colours(n = 4)[1],
              position = position_dodge(preserve = "single")
            ) +
            coord_flip() +
            labs(title = "Learner with learning difficulties\nor disabilities (LLDD)") +
            xlab("") +
            ylab("") +
            scale_y_continuous(labels = dfeR::comma_sep) +
            scale_x_discrete(
              labels = function(x) str_wrap(x, width = 10),
              limit = rev(chars_lldd_choices)
            ) +
            ggplot2::theme_minimal() +
            ggplot2::theme(
              legend.position = "top",
              legend.title = element_blank(),
              panel.grid = element_blank(),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              plot.title = element_text(family = "Arial", face = "bold", size = 20, hjust = 0),
              axis.text.x = element_text(family = "Arial", size = 15),
              axis.text.y = element_text(family = "Arial", size = 20)
            ),
        options = list(
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:5px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "single", css = "fill:#12436D;stroke:#12436D;"
          ),
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          )
        ),
        fonts = list(sans = "Arial")
      )
    })


    output$ethnicity_bar_plot <- renderGirafe({
      # Message when there are none of the measure at all - blank - only shown for age
      validate(need(nrow(chars_reactive_table()) > 0, ""))

      # Message when all groups are low, and chart cannot be displayed
      # But can still be seen in the table
      validate(need(
        nrow(filter(chars_reactive_table(), characteristic_type == "Ethnicity" & count != "low" &
          characteristic != "Total")) > 0, "All ethnic groups have low numbers."
      ))

      girafe(
        ggobj =
          chars_reactive_table() %>%
            filter(characteristic_type == "Ethnicity" & characteristic != "Total") %>%
            # need data in all categories else columns expand if missing data
            mutate(count = ifelse(count == "low", "0", count)) %>%
            # shorten name of category to fit better
            mutate(characteristic = if_else(nchar(as.character(characteristic)) > 10,
              substr(characteristic, 1, 5),
              characteristic
            )) %>%
            ggplot(aes(
              x = characteristic,
              y = as.numeric(count),
              tooltip = paste0(
                characteristic, ": ", dfeR::comma_sep(as.numeric(count)), " ",
                firstlow(input$measure)
              ),
              data_id = characteristic
            )) +
            geom_col_interactive(
              fill = afcolours::af_colours(n = 4)[1],
              position = position_dodge2(preserve = "single")
            ) +
            coord_flip() +
            labs(title = "Ethnicity") +
            xlab("") +
            ylab("") +
            scale_y_continuous(labels = dfeR::comma_sep) +
            scale_x_discrete(limit = rev(if_else(nchar(as.character(chars_ethnicity_choices)) > 10,
              substr(chars_ethnicity_choices, 1, 5), chars_ethnicity_choices
            ))) +
            ggplot2::theme_minimal() +
            ggplot2::theme(
              legend.position = "top",
              legend.title = element_blank(),
              panel.grid = element_blank(),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              plot.title = element_text(family = "Arial", face = "bold", size = 20, hjust = 0),
              axis.text.x = element_text(family = "Arial", size = 15),
              axis.text.y = element_text(family = "Arial", size = 20)
            ),
        options = list(
          # Set styling for bars on hover and when selected
          ggiraph::opts_hover(
            css = "cursor:pointer;stroke:black;stroke-width:5px;fill:#ffdd00;"
          ),
          ggiraph::opts_selection(
            type = "single", css = "fill:#12436D;stroke:#12436D;"
          ),
          ggiraph::opts_toolbar(
            saveaspng = FALSE,
            hidden = c("lasso_select", "lasso_deselect")
          )
        ),
        fonts = list(sans = "Arial")
      )
    })



    # table

    output$chars_table <- renderTable({
      # Message when there are none of the measure at all
      validate(need(nrow(chars_reactive_table()) > 0, paste0("No ", firstlow(input$measure), " for these selections.")))

      chars_reactive_table_tidied <- chars_reactive_table() %>%
        mutate(count = if_else(count != "low", as.character(dfeR::comma_sep(as.numeric(count))), count))

      colnames(chars_reactive_table_tidied) <-
        c(
          "Academic year", "Provider name", "Type of characteristic", "Characteristic",
          "Measure", "Number of apprenticeships"
        )

      chars_reactive_table_tidied
    })

    # Data download ===========================================================

    output$download_data <- downloadHandler(
      ## Set filename ---------------------------------------------------------
      filename = function(name) {
        raw_name <- paste0(
          input$provider, "-", input$year, "-", input$measure, "-",
          input$characteristic_type, "-learner-characteristics-provider-summary"
        )
        extension <- if (input$file_type == "CSV (Up to 2.13 MB)") {
          ".csv"
        } else {
          ".xlsx"
        }
        paste0(tolower(gsub(" ", "", raw_name)), extension)
      },
      ## Generate downloaded file ---------------------------------------------
      content = function(file) {
        if (input$file_type == "CSV (Up to 2.13 MB)" & input$provider != "Total (All providers)") {
          data.table::fwrite(chars_reactive_table(), file)
        } else if (input$file_type == "CSV (Up to 2.34 MB)" & input$provider == "Total (All providers)") {
          data.table::fwrite(chars_parquet %>%
            filter(year %in% input$year) %>%
            filter(measure %in% input$measure), file)
        } else if (input$file_type == "XLSX (Up to 550.45 KB)" & input$provider != "Total (All providers)") {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(chars_reactive_table(), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        } else {
          # Added a basic pop up notification as the Excel file can take time to generate
          pop_up <- showNotification("Generating download file", duration = NULL)
          openxlsx::write.xlsx(chars_parquet %>%
            filter(year %in% input$year) %>%
            filter(measure %in% input$measure), file, colWidths = "Auto")
          on.exit(removeNotification(pop_up), add = TRUE)
        }
      }
    )
  })
}
