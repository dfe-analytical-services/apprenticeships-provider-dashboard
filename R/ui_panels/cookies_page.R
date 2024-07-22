cookies_page <- function() {
  layout_columns(
    col_widths = c(-1, 8, -3),
    actionLink(class = "govuk-back-link", "cookies_to_dashboard", "Back to dashboard"),
    h1("Cookies")
  )
}
