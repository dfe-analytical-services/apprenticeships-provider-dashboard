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
  page_fluid(
    # Set app metadata --------------------------------------------------------
    tags$head(HTML("<title>Apprenticeships provider dashboard</title>")),
    tags$head(tags$link(rel = "shortcut icon", href = "dfefavicon.png")),
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

    # Page navigation ---------------------------------------------------------
    # This switches between the supporting pages in the footer and the main dashboard
    bslib::navset_hidden(
      id = "pages",
      nav_panel(
        "dashboard",
        # Main dashboard ----------------------------------------------------------
        gov_main_layout(
          layout_columns(
            col_widths = c(2, 8),
            # Left navigation -------------------------------------------------------
            tags$div(
              style = "position: sticky; top: 1rem",
              h2(style = "margin-left: 1rem", "Contents"),
              tags$ul(
                style = "list-style-type: none",
                tags$li(actionLink("example_panel", "Example panel")),
                tags$li(actionLink("user_guide", "User guide")),
                tags$li(actionLink("footnotes", "Footnotes")),
                tags$li(actionLink("support", "Support and feedback"))
              )
            ),
            # Dashboard panels ------------------------------------------------------
            bslib::navset_hidden(
              id = "left_nav",
              nav_panel("example_panel", example_panel()),
              nav_panel("user_guide", user_guide_panel()),
              nav_panel("footnotes", footnotes_panel()),
              nav_panel("support", support_panel())
            )
          )
        )
      ),
      # Pages linked from the footer ------------------------------------------
      nav_panel("accessibility", accessibility_page()),
      nav_panel("cookies", cookies_page())
    ),

    # Footer ------------------------------------------------------------------
    custom_footer() # set in utils.R
  )
}
