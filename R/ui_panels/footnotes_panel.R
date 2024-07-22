footnotes_panel <- function() {
  div(
    h1("Footnotes"),
    h2("All pages"),
    tags$ol(
      tags$li(
        "The data source for the interactive tool is the ",
        a(
          href = "",
          "Individualised Learner Record"
        )
      ),
      tags$li("Numbers are rounded to the nearest 10, with values of 0, 1, 2, 3 and 4 shown as 0, components therefore
              may not sum to totals")
    ),
    h2("Geographical breakdowns")
  )
}
