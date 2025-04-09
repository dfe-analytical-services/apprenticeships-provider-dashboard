cookies_page <- function() {
  # Set up column layout to center it -----------------------------------------
  layout_columns(
    col_widths = c(-2, 8, -2),

    # Add backlink
    actionLink(
      class = "govuk-back-link",
      style = "margin: 0",
      "cookies_to_dashboard",
      "Back to dashboard"
    ),

    # Main text content -------------------------------------------------------
    cookies_panel_ui(google_analytics_key = google_analytics_key)
  )
}
