# -----------------------------------------------------------------------------
# This is the global file.
#
# Use it to store functions, library calls, source files etc.
#
# Moving these out of the server file and into here improves performance as the
# global file is run only once when the app launches and stays consistent
# across users whereas the server and UI files are constantly interacting and
# responsive to user input.
#
# Library calls ---------------------------------------------------------------
shhh <- suppressPackageStartupMessages # It's a library, so shhh!

# Core shiny and R packages
shhh(library(shiny))
shhh(library(bslib))

# Custom packages
shhh(library(dfeR))
shhh(library(dfeshiny))
shhh(library(shinyGovstyle))

# Creating charts and tables


# Data and string manipulation
shhh(library(dplyr))

# Shiny extensions
shhh(library(shinytitle))
shhh(library(metathis))

# Dependencies needed for testing or CI but not for the app -------------------
# Including them here keeps them in renv but avoids the app needlessly loading
# them, saving on load time.
if (FALSE) {
  # Automated testing
  shhh(library(shinytest2))
  shhh(library(testthat))

  # Code linting and styling
  shhh(library(lintr))
  shhh(library(styler))
}

# Source scripts --------------------------------------------------------------
#
# Source any scripts here. Scripts may be needed to process data before it gets
# to the server file or to hold custom functions to keep the main files shorter
#
# It's best to do this here instead of the server file, to improve performance.

# Source script for loading in data
source("R/read_data.R")

# Source custom functions script
source("R/utils.R")

# Source all files in the ui_panels folder
lapply(list.files("R/ui_panels/", full.names = TRUE), source)

# Set global variables --------------------------------------------------------
site_title <- "Apprenticeships provider dashboard" # name of app
parent_pub_name <- "Apprenticeships" # name of source publication
parent_publication <- # link to source publication
  "https://explore-education-statistics.service.gov.uk/find-statistics/apprenticeships"

team_email <- "fe.officialstatistics@education.gov.uk"
repo_name <- "https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard"
feedback_form_url <- "" # TODO

# Set the URLs that the site will be published to
site_primary <- "https://department-for-education.shinyapps.io/apprenticeships-provider-dashboard/"
site_overflow <- "https://department-for-education.shinyapps.io/apprenticeships-provider-dashboard-overflow/"
sites_list <- c(site_primary, site_overflow)

# Set the key for Google Analytics tracking
google_analytics_key <- "XXXXXXXXXX"

# End of global variables -----------------------------------------------------

# Read in the data ------------------------------------------------------------
