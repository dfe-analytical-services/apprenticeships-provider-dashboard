cookies_page <- function() {
  layout_columns(
    col_widths = c(-2, 8, -2),
    actionLink(class = "govuk-back-link", style = "margin: 0", "cookies_to_dashboard", "Back to dashboard"),
    h1("Cookies")
  )
}
