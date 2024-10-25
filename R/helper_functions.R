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

dfe_footer <- function(links_list) {
  # Add the HTML around the link and make an id by snake casing
  create_footer_link <- function(link_text) {
    shiny::tags$li(
      class = "govuk-footer__inline-list-item",
      actionLink(
        class = "govuk-link govuk-footer__link",
        inputId = tolower(gsub(" ", "_", link_text)),
        label = link_text
      )
    )
  }

  # The HTML div to be returned
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

            # Generate as many links as needed
            lapply(links_list, create_footer_link)
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
dfe_reactable <- function(data, on_click = NULL, selection = NULL,
                          row_style = NULL, searchable = FALSE,
                          default_page_size = 10) {
  reactable(
    data,

    # DfE styling
    highlight = TRUE,
    borderless = TRUE,
    showSortIcon = FALSE,
    style = list(fontSize = "16px", display = "block"),
    defaultColDef = colDef(headerClass = "bar-sort-header"),

    # Customiseable settings
    # TODO: think about the best way to set this out for dfeshiny to allow flexibility while keeping defaults we want
    defaultPageSize = default_page_size,
    rowStyle = row_style,
    onClick = on_click,
    selection = selection,
    searchable = searchable
  )
}

# left nav ====================================================================
dfe_contents_links <- function(links_list) {
  # Add the HTML around the link and make an id by snake casing
  create_sidelink <- function(link_text) {
    tags$li("—", actionLink(tolower(gsub(" ", "_", link_text)), link_text, class = "contents_link"))
  }

  # The HTML div to be returned
  tags$div(
    style = "position: sticky; top: 0.5rem; padding: 0.25rem;", # Make it stick!
    h2("Contents"),
    tags$ol(
      style = "list-style-type: none; padding-left: 0; font-size: 1rem;", # remove the circle bullets
      lapply(links_list, create_sidelink)
    )
  )
}

# properly capitalise first letter of a string ================================
firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

# Put first letter of a string to lower case, as in a variable ================
# This reverses firstup, so can use to refer to a column name
# that is capitalised in the input
firstlow <- function(x) {
  substr(x, 1, 1) <- tolower(substr(x, 1, 1))
  x
}

# Add a map reset button to a Leaflet map object, using some additional JavaScript
# @param leaf A Leaflet map object
# @param selectize_input_id The ID of the input you want the reset button to clear
#
# Note that if you're working inside a module, you will need to wrap the inputId in the NS function
add_map_reset_button <- function(leaf, selectize_input_id = NULL) {
  leaf %>%
    # Add a button into the map
    addEasyButton(
      easyButton(
        icon = "ion-refresh",
        title = "Reset View",
        # When clicking the button, reset the view of the map and clear the selectizeInput
        onClick = JS(
          # Use of a random number ensures that shiny will always recognise every button click
          # without it multiple clicks in quick succession might not be registered / recognised
          sprintf(
            "function(btn, map){
              map.setView(map._initialCenter, map._initialZoom);
              if ('%s' !== 'null') {
                Shiny.setInputValue('%s_reset', Math.random());
              }
            }",
            selectize_input_id, selectize_input_id
          )
        )
      )
    ) %>%
    # When the map loads, grab its initial centre point values
    htmlwidgets::onRender(
      JS(
        "
function(el, x){
  var map = this;
  map.whenReady(function(){
    map._initialCenter = map.getCenter();
    map._initialZoom = map.getZoom();
  });
}"
      )
    )
}

# Create a map ================================================================
dfe_lad_map <- function(data, measure, input_id) {
  # Set the color scheme and scale
  pal_fun <- colorNumeric(
    "Blues",
    domain = c(
      min(data$`Number of apprenticeships`),
      max(data$`Number of apprenticeships`)
    )
  )




  # Set a pop up
  hover_labels <- paste0(
    "<strong>", data$lad_name, "</strong><br/>",
    lapply(data$`Number of apprenticeships`, dfeR::pretty_num), " ", measure
  ) %>% lapply(htmltools::HTML)

  # Create the map
  map <- leaflet(
    data,
    # Take off annoying scrolling, personal preference
    options = leafletOptions(scrollWheelZoom = FALSE)
  ) %>%
    # Set the basemap (this is a good neutral one)
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    # Add the shaded regions
    addPolygons(
      color = "black",
      weight = 1,
      fillColor = pal_fun(data[["Number of apprenticeships"]]),
      fillOpacity = 1,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#666",
        fillOpacity = 0.7,
        bringToFront = TRUE
      ),
      label = hover_labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto",
        bringToFront = TRUE
      ),
      layerId = ~lad_name # this is what value is returned when a user clicks on a polygon
    ) %>%
    # Add a legend to the map
    addLegend("topright",
      pal = pal_fun,
      values = ~ data[["Number of apprenticeships"]],
      title = firstup(measure)
    ) %>%
    add_map_reset_button(selectize_input_id = input_id) # add a reset button

  return(map)
}

# Region map =================
dfe_region_map <- function(data, measure, input_id) {
  # Set the color scheme and scale
  pal_fun <- colorNumeric(
    "Blues",
    domain = c(
      min(data$`Number of apprenticeships`),
      max(data$`Number of apprenticeships`)
    )
  )




  # Set a pop up
  hover_labels <- paste0(
    "<strong>", data$region_name, "</strong><br/>",
    lapply(data$`Number of apprenticeships`, dfeR::pretty_num), " ", measure
  ) %>% lapply(htmltools::HTML)

  # Create the map
  map <- leaflet(
    data,
    # Take off annoying scrolling, personal preference
    options = leafletOptions(scrollWheelZoom = FALSE)
  ) %>%
    # Set the basemap (this is a good neutral one)
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    # Add the shaded regions
    addPolygons(
      color = "black",
      weight = 1,
      fillColor = pal_fun(data[["Number of apprenticeships"]]),
      fillOpacity = 1,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#666",
        fillOpacity = 0.7,
        bringToFront = TRUE
      ),
      label = hover_labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto",
        bringToFront = TRUE
      ),
      layerId = ~region_name # this is what value is returned when a user clicks on a polygon
    ) %>%
    # Add a legend to the map
    addLegend("topright",
      pal = pal_fun,
      values = ~ data[["Number of apprenticeships"]],
      title = firstup(measure)
    ) %>%
    add_map_reset_button(selectize_input_id = input_id) # add a reset button

  return(map)
}


# eda map =================
dfe_eda_map <- function(data, measure, input_id) {
  # Set the color scheme and scale
  pal_fun <- colorNumeric(
    "Blues",
    domain = c(
      min(data$`Number of apprenticeships`),
      max(data$`Number of apprenticeships`)
    )
  )
  
  
  
  
  # Set a pop up
  hover_labels <- paste0(
    "<strong>", data$eda_name, "</strong><br/>",
    lapply(data$`Number of apprenticeships`, dfeR::pretty_num), " ", measure
  ) %>% lapply(htmltools::HTML)
  
  # Create the map
  map <- leaflet(
    data,
    # Take off annoying scrolling, personal preference
    options = leafletOptions(scrollWheelZoom = FALSE)
  ) %>%
    # Set the basemap (this is a good neutral one)
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    # Add the shaded regions
    addPolygons(
      color = "black",
      weight = 1,
      fillColor = pal_fun(data[["Number of apprenticeships"]]),
      fillOpacity = 1,
      highlightOptions = highlightOptions(
        weight = 5,
        color = "#666",
        fillOpacity = 0.7,
        bringToFront = TRUE
      ),
      label = hover_labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto",
        bringToFront = TRUE
      ),
      layerId = ~eda_name # this is what value is returned when a user clicks on a polygon
    ) %>%
    # Add a legend to the map
    addLegend("topright",
              pal = pal_fun,
              values = ~ data[["Number of apprenticeships"]],
              title = firstup(measure)
    ) %>%
    add_map_reset_button(selectize_input_id = input_id) # add a reset button
  
  return(map)
}


# Create options lists for use in the dropdowns ===============================
data_choices <- function(data, column) {
  data %>%
    distinct(!!sym(column)) %>% # adding the !!sym() to convert string to column name
    collect() %>%
    pull()
}
