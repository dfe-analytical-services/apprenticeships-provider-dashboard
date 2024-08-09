# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is the helper functions file, full of helpful functions for reusing!
#
# It is commonly used as an R script to store custom functions used through the
# app to keep the rest of the app code easier to read.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# GSS colours =================================================================
# Current GSS colours for use in charts. These are taken from the current
# guidance here:
# https://analysisfunction.civilservice.gov.uk/policy-store/data-visualisation-colours-in-charts/
# Note the advice on trying to keep to a maximum of 4 series in a single plot
# AF colours package guidance here: https://best-practice-and-impact.github.io/afcolours/
suppressMessages(
  gss_colour_pallette <- afcolours::af_colours("categorical", colour_format = "hex", n = 4)
)


# Custom footer ===============================================================
# This is hardcoded from shinygovstyle
# The section lined off early on is the custom bit where links are set

custom_footer <- function() {
  shiny::tags$footer(
    class = "govuk-footer ",
    role = "contentinfo",
    shiny::div(
      class = "govuk-width-container ",
      shiny::div(
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Add custom links in
        shiny::div(
          class = "govuk-footer__meta-item govuk-footer__meta-item--grow",

          # Set a visually hidden title for accessibility
          shiny::h2(
            class = "govuk-visually-hidden",
            "Support links"
          ),
          shiny::tags$ul(
            class = "govuk-footer__inline-list",
            shiny::tags$li(
              class = "govuk-footer__inline-list-item",
              actionLink(
                class = "govuk-link govuk-footer__link",
                inputId = "footnotes",
                label = "Footnotes"
              )
            ),
            shiny::tags$li(
              class = "govuk-footer__inline-list-item",
              actionLink(
                class = "govuk-link govuk-footer__link",
                inputId = "support",
                label = "Support"
              )
            ),
            shiny::tags$li(
              class = "govuk-footer__inline-list-item",
              actionLink(
                class = "govuk-link govuk-footer__link",
                inputId = "cookies",
                label = "Cookies"
              )
            ),
            shiny::tags$li(
              class = "govuk-footer__inline-list-item",
              actionLink(
                class = "govuk-link govuk-footer__link",
                inputId = "accessibility",
                label = "Accessibility statement"
              )
            )
          )
        ),

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Back to copied code from shinyGovstyle
        shiny::div(
          class = "govuk-footer__meta",
          shiny::tagList(
            shiny::div(
              class = "govuk-footer__meta-item govuk-footer__meta-item--grow",
              shiny::tag("svg", list(
                role = "presentation",
                focusable = "false",
                class = "govuk-footer__licence-logo",
                xmlns = "http://www.w3.org/2000/svg",
                viewbox = "0 0 483.2 195.7",
                height = "17",
                width = "41",
                shiny::tag("path", list(
                  fill = "currentColor",
                  d = paste0(
                    "M421.5 142.8V.1l-50.7 32.3v161.1h112.4v-50.7",
                    "zm-122.3-9.6A47.12 47.12 0 0 1 221 97.8c0-26 21",
                    ".1-47.1 47.1-47.1 16.7 0 31.4 8.7 39.7 21.8l42.7",
                    "-27.2A97.63 97.63 0 0 0 268.1 0c-36.5 0-68.3 20.1",
                    "-85.1 49.7A98 98 0 0 0 97.8 0C43.9 0 0 43.9 0 97",
                    ".8s43.9 97.8 97.8 97.8c36.5 0 68.3-20.1 85.1-49.",
                    "7a97.76 97.76 0 0 0 149.6 25.4l19.4 22.2h3v-87.8",
                    "h-80l24.3 27.5zM97.8 145c-26 0-47.1-21.1-47.1-47",
                    ".1s21.1-47.1 47.1-47.1 47.2 21 47.2 47S123.8 145",
                    " 97.8 145"
                  )
                ))
              )),
              shiny::tags$span(
                class = "govuk-footer__licence-description",
                "All content is available under the",
                shiny::tags$a(
                  class = "govuk-footer__link",
                  href = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
                  rel = "license",
                  "Open Government Licence v3.0",
                  .noWS = "after"
                ),
                ", except where otherwise stated"
              )
            ),
            shiny::tags$div(
              class = "govuk-footer__meta-item",
              shiny::tags$a(
                class = "govuk-footer__link govuk-footer__copyright-logo",
                href =
                  paste0(
                    "https://www.nationalarchives.gov.uk/information-management/",
                    "re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/"
                  ),
                "\u00A9 Crown copyright"
              )
            )
          )
        )
      )
    )
  )
}

# dfe reactable ===============================================================
dfe_reactable <- function(data) {
  reactable(
    data,
    highlight = TRUE,
    borderless = TRUE,
    showSortIcon = FALSE,
    style = list(fontSize = "16px"),
    defaultColDef = colDef(headerClass = "bar-sort-header")
  )
}


# properly capitalise first letter of a string
firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}
