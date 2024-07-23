national_provider_summary <- function() {
  div(
    h1("National provider summary"),

    # User selection area -----------------------------------------------------
    div(
      class = "well",
      style = "min-height: 100%; height: 100%; overflow-y: visible; margin-bottom: 1rem; padding-bottom: 0;",
      bslib::layout_column_wrap(
        width = "15rem", # Minimum width for each input box before wrapping
        # Dropdowns -----------------------------------------------------------
        # selectizeInput(
        #   inputId = "provider",
        #   label = "Search for provider",
        #   choices = NULL
        # ),
        selectInput(
          inputId = "provider",
          label = "Search for provider",
          choices = provider_choices,
          selectize = TRUE
        ), # Look at swapping this out for a crosstalk filter search
        selectInput(
          inputId = "year",
          label = "Select academic year",
          choices = year_choices,
          selectize = TRUE
        ),
        selectInput(
          inputId = "characteristic",
          label = "Select learner characteristic",
          choices = characteristic_choices,
          selectize = TRUE
        )
      )
    ),

    # Main table --------------------------------------------------------------
    navset_card_tab(
      nav_panel(
        "Table",
        reactable::reactableOutput("nps_table")
      ),
      nav_panel(
        "Download data",
        shinyGovstyle::radio_button_Input(
          inputId = "download_radios",
          choices = c("CSV (20 MB)", "XSLX (18 MB)", "JSON (30 MB)"),
          label = h2("Choose download file format")
        ),
        # Bit of a hack to force the button not to be full width
        layout_columns(
          col_widths = 3,
          downloadButton(
            "download_data",
            label = "Download data",
            class = "gov-uk-button",
            icon = NULL
          )
        )
      ),
      card_footer(
        style = "font-size: 16px",
        "The Index of Multiple deprivation (IMD) is a measure of relative deprivation. The IMD shown here has been
        split into quintiles, with a value of one indicating the 20% most deprived neighbourhoods and five the 20%
        least deprived. IMD is derived from the learner postcode recorded on the Individualised Learner Record."
      )
    )
  )
}
