# -----------------------------------------------------------------------------
# This is the ui file. Use it to call elements created in your server file into
# the app, and define where they are placed, and define any user inputs.
#
# Other elements like charts, navigation bars etc. are completely up to you to
# decide what goes in. However, every element should meet accessibility
# requirements and user needs.
#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# The documentation for GOV.UK components can be found at:
#
#    https://github.com/moj-analytical-services/shinyGovstyle
#
# -----------------------------------------------------------------------------
ui <- function(input, output, session) {
  fluidPage(
    # Set app metadata --------------------------------------------------------
    title = tags$head(
      tags$link(
        rel = "shortcut icon",
        href = "dfefavicon.png"
      ),
      # Add title for browser tabs
      tags$head(HTML("<title>Apprenticeships provider dashboard</title>"))
    ),
    tags$html(lang = "en"),
    # Add meta description for search engines
    meta() %>%
      meta_general(
        application_name = "Apprenticeships provider dashboard",
        description = "Interactive tool for exploring apprenticeships provider data",
        robots = "index,follow",
        generator = "R Shiny",
        subject = "apprenticeships",
        rating = "General",
        referrer = "no-referrer"
      ),

    # Custom CSS --------------------------------------------------------------
    tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "dfe_shiny_gov_style.css"
      )
    ),

    # Custom disconnect function ----------------------------------------------
    # Variables used here are set in the global.R file
    dfeshiny::custom_disconnect_message(
      links = sites_list,
      publication_name = parent_pub_name,
      publication_link = parent_publication
    ),

    # Header ------------------------------------------------------------------
    shinyGovstyle::header(
      main_text = "",
      main_link = "https://www.gov.uk/government/organisations/department-for-education",
      secondary_text = "Apprenticeships provider dashboard",
      logo = "images/DfE_logo_landscape.png",
      logo_width = 150,
      logo_height = 32
    ),

    # Beta banner -------------------------------------------------------------
    shinyGovstyle::banner(
      "beta banner",
      "Beta",
      paste0(
        "This dashboard is being actively developed, contact explore.statistics@education.gov.uk with any feedback"
      )
    ),

    # Nav panels --------------------------------------------------------------
    shiny::navlistPanel(
      "",
      id = "navlistPanel",
      widths = c(2, 8),
      well = FALSE,
      # Content for these panels is defined in the R/ui_panels/ folder
      example_tab_1_panel(),
      user_guide_panel(),
      a11y_panel(),
      support_panel()
    ),

    # Footer ------------------------------------------------------------------
    footer(full = TRUE)
  )
}
