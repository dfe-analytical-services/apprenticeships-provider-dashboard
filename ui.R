# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ui <- function(input, output, session) {
  page_fluid(
    # Metadata for app ========================================================
    tags$html(lang = "en"),
    tags$head(HTML(paste0("<title>", site_title, "</title>"))), # set in global.R
    tags$head(tags$link(rel = "shortcut icon", href = "dfefavicon.png")),
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

    # Required to make the title update based on tab changes
    shinytitle::use_shiny_title(),

    ## Custom CSS -------------------------------------------------------------
    tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "dfe_shiny_gov_style.css"
      )
    ),

    ## Custom disconnect function ---------------------------------------------
    # Variables used here are set in the global.R file
    dfeshiny::custom_disconnect_message(
      links = site_primary,
      publication_name = parent_pub_name,
      publication_link = parent_publication
    ),

    ## Header -----------------------------------------------------------------
    shinyGovstyle::header(
      main_text = "",
      main_link = "https://www.gov.uk/government/organisations/department-for-education",
      secondary_text = "Apprenticeships provider dashboard",
      logo = "images/DfE_logo_landscape.png",
      logo_width = 150,
      logo_height = 32
    ),

    ## Beta banner ------------------------------------------------------------
    shinyGovstyle::banner(
      "gds_phase_banner",
      "Alpha",
      paste0(
        "This dashboard is being actively developed, contact explore.statistics@education.gov.uk with any feedback"
      )
    ),

    # Page navigation =========================================================
    # This switches between the supporting pages in the footer and the main dashboard
    gov_main_layout(
      bslib::navset_hidden(
        id = "pages",
        nav_panel(
          "dashboard",
          ## Main dashboard ---------------------------------------------------
          layout_columns(
            # Override default wrapping breakpoints to avoid text overlap
            col_widths = breakpoints(sm = c(4, 8), md = c(3, 9), lg = c(2, 9)),
            ## Left navigation ------------------------------------------------
            dfe_contents_links(
              links_list =
                c(
                  "Provider breakdowns",
                  "Local authority district",
                  "Subjects and standards",
                  "Learner characteristics",
                  "National provider summary",
                  "User guide"
                )
            ),
            ## Dashboard panels -----------------------------------------------
            bslib::navset_hidden(
              id = "left_nav",
              nav_panel("provider_breakdowns", provider_breakdowns()),
              nav_panel("local_authority_district", local_authority_district()),
              nav_panel("subjects_and_standards", subjects_standards_ui(id = "sas")),
              nav_panel("learner_characteristics", learner_characteristics_ui(id = "learner_characteristics")),
              nav_panel("national_provider_summary", nps_ui(id = "nps")),
              nav_panel("user_guide", user_guide())
            )
          )
        ),
        ## Footer pages -------------------------------------------------------
        nav_panel("footnotes", footnotes_page()),
        nav_panel("support", support_page()),
        nav_panel("accessibility_statement", accessibility_page()),
        nav_panel("cookies", cookies_page())
      )
    ),

    # Footer ==================================================================
    dfe_footer(links_list = c("Footnotes", "Support", "Accessibility statement", "Cookies"))
  )
}
