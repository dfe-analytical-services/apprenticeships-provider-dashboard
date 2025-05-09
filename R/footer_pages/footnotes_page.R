## automate years referred to
footnote_years <- sort(data_choices(data = prov_breakdowns_parquet, column = "year"),
  decreasing = TRUE
)

footnote_years <- unlist(footnote_years)
footnote_most_recent_year_months <- footnote_years[1]
footnote_year_2 <- footnote_years[2]
footnote_year_3 <- footnote_years[3]


if (substr(most_recent_year_months, 10, 19) == "Aug to Oct") {
  footnote_months <- "cover the year to date (i.e. cumulative data for the 3 months from 1 August to 31 October)."
  provisional_final <- "provisional"
}

if (substr(most_recent_year_months, 10, 19) == "Aug to Jan") {
  footnote_months <- "cover the year to date (i.e. cumulative data for the 6 months from 1 August to 31 January)."
  provisional_final <- "provisional"
}

if (substr(most_recent_year_months, 10, 19) == "Aug to Apr") {
  footnote_months <- "cover the year to date (i.e. cumulative data for the 9 months from 1 August to 30 April)."
  provisional_final <- "provisional"
}

if (substr(most_recent_year_months, 10, 19) == "") {
  footnote_months <- "cover the whole year (i.e. data from August to July). "
  provisional_final <- "final"
}

footnote_most_recent_year <- substr(most_recent_year_months, 1, 7)



footnotes_page <- function() {
  # Set up column layout to center it -----------------------------------------
  layout_columns(
    col_widths = c(-2, 8, -2),

    # Add in back link
    actionLink(class = "govuk-back-link", style = "margin: 0", "footnotes_to_dashboard", "Back to dashboard"),

    # Main text content -------------------------------------------------------
    h1("Footnotes"),
    h2("All pages"),
    tags$ol(
      tags$li(
        "The data source for the interactive tool is the ",
        external_link(
          "https://www.gov.uk/government/publications/sfa-ilr-standard-file-specifications-and-reference-data",
          "Individualised Learner Record"
        ),
        "."
      ),
      tags$li("Numbers are rounded to the nearest 10, with values of 0, 1, 2, 3 and 4 shown as 0, components therefore
              may not sum to totals."),
      tags$li("Age for apprenticeship starts and achievements is based on the learner's age at the start of their
              apprenticeship.  Age for enrolments is based on the learner's age at 31 August of the academic year."),
      tags$li(paste0(
        "Figures for ", footnote_most_recent_year, " are ", provisional_final, " and ", footnote_months,
        " Those for ", footnote_year_2, " and ", footnote_year_3, " are final and cover the full academic year (1 August to 31 July)."
      )),
      tags$li(
        "For more data and information on these statistics please refer to the department's main ",
        external_link(
          "https://explore-education-statistics.service.gov.uk/find-statistics/apprenticeships",
          "Apprenticeships publication"
        ),
        "."
      )
    ),
    h2("Geographical breakdowns"),
    tags$ol(
      start = "6",
      tags$li("Learner geography is based on the home postcode of the learner and delivery geography is based on the
               postcode declared by the provider, to indicate where the learning is taking place."),
      tags$li("Unless otherwise stated, geographical breakdowns are based on the postcode of the learner."),
      tags$li("Postcodes which are outside of England or not known are included in the 'Outside of England and unknown'
              category."),
      tags$li("The geographical breakdowns shown in the maps are based on the latest boundaries. Areas where boundaries
              have recently  been changed due to local-level reorganisation are therefore coloured grey for earlier
              years.Figures for earlier years are  available in the accompanying table.")
    ),
    h2("Standards"),
    tags$ol(
      start = "10",
      tags$li("Apprenticeship frameworks were withdrawn to new learners on 31 July 2020, however a small number of
              starts are recorded as frameworks after this date in situations where it has been agreed a learner
              can return to a framework after an extensive break. Furthermore, some aims and achievements may be
              on frameworks where the learner started their course on or before 31 July 2020.")
    )
  )
}
