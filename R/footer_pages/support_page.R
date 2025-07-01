support_page <- function() {
  # Set up column layout to center it -----------------------------------------
  layout_columns(
    col_widths = c(-2, 8, -2),

    # Add in back link
    actionLink(class = "govuk-back-link", style = "margin: 0", "support_to_dashboard", "Back to dashboard"),

    # Main text content -------------------------------------------------------
    h1("Support and feedback"),
    h2("Give us feedback"),
    support_panel(
      "This provider-focussed dashboard is a new service that we are developing.
      It is a prototype, designed to supplement the main apprenticeships visualisation tool and table tool,
      and to replace the current provider-focussed interactive tool."
    ),
    support_panel(
      "If you have any feedback or suggestions for improvements, please submit them using our ",
      a(href = feedback_form_url, "feedback form", .noWS = c("after")), "."
    ),
    support_panel("Alternatively, if you spot any errors or bugs while using this dashboard, please screenshot and email them
          to ", a(href = paste0("mailto:", team_email), team_email, .noWS = c("after")), "."),
    h2("Find more information on the data"),
    support_panel(
      "The parent statistical release of this dashboard, along with methodological information, is available at",
      a(href = parent_publication, "Explore education statistics: Apprenticeships", .noWS = c("after")),
      ". The statistical release provides additional ",
      a(href = paste0(parent_publication, "/data-guidance"), "data guidance", .noWS = c("after")),
      " and ",
      a(
        href = paste0(parent_publication, "#explore-data-and-files"),
        "tools to access and interogate the underlying data",
        .noWS = c("after")
      ),
      " contained in this dashboard."
    ),
    h2("Contact us"),
    support_panel(
      "If you have questions about the dashboard or data within it, please contact us at ",
      a(href = paste0("mailto:", team_email), team_email, .noWS = c("after")), "."
    ),
    h2("See the source code"),
    support_panel(
      "The source code for this dashboard is available in our ",
      a(href = paste0(repo_name), "GitHub repository", .noWS = c("after")), "."
    )
  )
}
