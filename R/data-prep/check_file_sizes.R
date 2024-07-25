# A quick script to check the potential file download sizes
#
# It's best practice to include file sizes in downloads, given how variable ours might be we're
# using this script to work out the maximums and then hard coding those in the app to give users

# Load data and dependencies
source("global.R")

# NPS data
if (!is.null(nps_parquet)) {
  # Create example files without any filters (so the maximum a user could download)
  openxlsx::write.xlsx(nps_parquet %>% collect(), "data/nps_full.xlsx", colWidths = "auto")
  data.table::fwrite(nps_parquet %>% collect(), "data/nps_full.csv")

  # Print the file sizes to console
  message("Max XLSX NPS file size: ", dfeR::pretty_filesize(file.size("data/nps_full.xlsx")))
  message("Max CSV NPS file size: ", dfeR::pretty_filesize(file.size("data/nps_full.csv")))

  # Clean up afterwards
  file.remove("data/nps_full.xlsx")
  file.remove("data/nps_full.csv")
}
