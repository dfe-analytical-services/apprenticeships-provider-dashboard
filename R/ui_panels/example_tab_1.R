example_tab_1_panel <- function() {
  tabPanel(
    "Example tab 1",
    gov_main_layout(
      gov_row(
        column(
          width = 12,
          h1("Overall content title for this dashboard page"),
        )
      )
    )
  )
}
