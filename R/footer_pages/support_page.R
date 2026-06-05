support_page <- function() {
  # Set up column layout to center it -----------------------------------------
  layout_columns(
    col_widths = c(-2, 8, -2),

    # Add in back link
    actionLink(class = "govuk-back-link", style = "margin: 0", "support_to_dashboard", "Back to dashboard"),

    # Main text content -------------------------------------------------------


    support_panel(
      team_email = "fe.officialstatistics@education.gov.uk",
      repo_name = "https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard",
      publication_name = "Apprenticeships",
      publication_slug = "apprenticeships",
      form_url = "https://forms.office.com/e/wL1aV83LAn",
      custom_data_info = "This provider-focussed dashboard is a prototype, designed to supplement
       the main apprenticeships visualisation tool and table tool, and to replace the current
       provider-focussed interactive tool.",
    )
  )
}
