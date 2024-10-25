# Connect to SQL server - for where need to run ur code
# now on new server

con_T1PRANMSQL <- DBI::dbConnect(odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  server = "T1PRANMSQL\\SQLPROD,60125",
  database = "dwh_pl",
  UID = "",
  PWD = "",
  trusted_connection = "Yes"
)


# Get SQL code and tidy it up so it can run-------------------

getSQL <- function(filepath) {
  con <- file(filepath, "r")
  sql.string <- ""

  while (TRUE) {
    line <- readLines(con, n = 1)

    if (length(line) == 0) {
      break
    }

    line <- gsub("\\t", " ", line)
    line <- gsub("\\n", " ", line)

    if (grepl("--", line) == TRUE) {
      line <- paste(sub("--", "/*", line), "*/")
    }

    sql.string <- paste(sql.string, line)
  }

  close(con)
  return(sql.string)
}



# Clean SQL code---------------------------------------------
cleanSQL <- function(code) {
  code <- gsub("ï»¿", " ", code) # clean up SQL - remove weird sign that appears sometimes when reading data in
}

# Get data
apps_code <- getSQL("sql/apprenticeships_data.sql") # get generic code - has variable for year,snapshot


# run sql code
apps_data <- DBI::dbGetQuery(con_T1PRANMSQL, apps_code)

write.csv(apps_data, "data/apprenticeships_data.csv")
