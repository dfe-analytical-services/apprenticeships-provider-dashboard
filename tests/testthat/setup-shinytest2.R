# Load application support files into testing environment
shinytest2::load_app_env()

library(shinytest2)
library(rvest)

# Test utility functions to help test the different output objects
# These should eventually go into dfeshiny or somewhere else for reuse

# Get the text from a reactive text output
get_reactive_text <- function(object_name, app) {
  raw_html <- app$get_html(paste0("#", object_name))

  text <- raw_html |>
    rvest::read_html() |>
    html_element("div") |>
    html_text()

  return(text)
}

# Check a ggiraph plot has rendered content
check_ggiraph_rendered <- function(object_name, app) {
  # Save 1 if image exits, 0 if not
  plot_img_length <- app$get_html(paste0("#", object_name)) |>
    rvest::read_html() |>
    rvest::html_elements("svg") |> # ggiraph creates svg layers
    length()

  # Give a true if the image exists, a false if not
  return(as.logical(plot_img_length))
}

# Check that a ggplot2 or leaflet plot has rendered content
check_plot_rendered <- function(object_name, app) {
  # Save 1 if image exits, 0 if not
  plot_img_length <- app$get_html(paste0("#", object_error)) |>
    rvest::read_html() |>
    rvest::html_elements("img") |>
    length()

  # Give a true if the image exists, a false if not
  return(as.logical(plot_img_length))
}

# Check that a reactable table is present and return the count of rendered rows of data
check_reactable_rows <- function(object_name, app) {
  table_html <- app$get_html(paste0("#", object_name))

  if (is.null(table_html)) {
    stop(paste("The", object_name, "object could not be found."))
  }

  number_of_rendered_rows <- table_html |>
    rvest::read_html() |>
    rvest::html_elements("div.rt-tr-group") |>
    length()

  return(number_of_rendered_rows)
}

# Check that a rendertable table is present and return the count of rendered rows of data
check_rendertable_rows <- function(object_name, app) {
  table_html <- app$get_values(output = object_name)[[1]]

  # Return 0 as number of rows if there's an error
  # Table html has a length 1 if no error, will be a list of stuff if error is present
  if (length(table_html[[object_name]]) != 1) {
    return(0)
  }

  number_of_rendered_rows <- table_html |>
    unlist() |>
    rvest::read_html() |>
    rvest::html_elements("tr") |>
    length()

  return(number_of_rendered_rows)
}
