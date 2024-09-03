# A quick script to check the potential file download sizes
#
# It's best practice to include file sizes in downloads, given how variable ours might be we're
# using this script to work out the maximums and then hard coding those in the app to give users

# Load data and dependencies
source("global.R")


# 2. LAD data
if (!is.null(lad_map_parquet)) {
  # Doing this filtered by each year to work out the maximum as otherwise we'd get ~ 3x the actual max size

  # Create example files without any filters (so the maximum a user could download)
  openxlsx::write.xlsx(
    lad_map_parquet %>%
      filter(year == "2021/22") %>%
      collect(),
    "data/test.xlsx",
    colWidths = "auto"
  )
  data.table::fwrite(lad_map_parquet %>% filter(year == "2021/22") %>% collect(), "data/test.csv")

  # Print the file sizes to console
  message("Max XLSX LAD file size: ", dfeR::pretty_filesize(file.size("data/test.xlsx")))
  message("Max CSV LAD file size: ", dfeR::pretty_filesize(file.size("data/test.csv")))

  # Clean up afterwards
  file.remove("data/test.xlsx")
  file.remove("data/test.csv")

  # Create example files without any filters (so the maximum a user could download)
  openxlsx::write.xlsx(
    lad_map_parquet %>%
      filter(year == "2022/23") %>%
      collect(),
    "data/test.xlsx",
    colWidths = "auto"
  )
  data.table::fwrite(lad_map_parquet %>% filter(year == "2022/23") %>% collect(), "data/test.csv")

  # Print the file sizes to console
  message("Max XLSX LAD file size: ", dfeR::pretty_filesize(file.size("data/test.xlsx")))
  message("Max CSV LAD file size: ", dfeR::pretty_filesize(file.size("data/test.csv")))

  # Clean up afterwards
  file.remove("data/test.xlsx")
  file.remove("data/test.csv")

  # Create example files without any filters (so the maximum a user could download)
  openxlsx::write.xlsx(
    lad_map_parquet %>%
      filter(year == "2023/24 (Q3 Aug to Apr)") %>%
      collect(),
    "data/test.xlsx",
    colWidths = "auto"
  )
  data.table::fwrite(lad_map_parquet %>% filter(year == "2023/24 (Q3 Aug to Apr)") %>% collect(), "data/test.csv")

  # Print the file sizes to console
  message("Max XLSX LAD file size: ", dfeR::pretty_filesize(file.size("data/test.xlsx")))
  message("Max CSV LAD file size: ", dfeR::pretty_filesize(file.size("data/test.csv")))

  # Clean up afterwards
  file.remove("data/test.xlsx")
  file.remove("data/test.csv")
}

# 4. Demographics data
if (!is.null(chars_parquet)) {
  # Create example files without any filters (so the maximum a user could download)
  openxlsx::write.xlsx(chars_parquet %>% collect(), "data/chars_full.xlsx", colWidths = "auto")
  data.table::fwrite(chars_parquet %>% collect(), "data/chars_full.csv")

  # Print the file sizes to console
  message("Max XLSX characteristics file size: ", dfeR::pretty_filesize(file.size("data/chars_full.xlsx")))
  message("Max CSV characteristics file size: ", dfeR::pretty_filesize(file.size("data/chars_full.csv")))

  # Clean up afterwards
  file.remove("data/chars_full.xlsx")
  file.remove("data/chars_full.csv")
}

# 5. NPS data
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
