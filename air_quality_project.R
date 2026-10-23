packages <- c("readxl", "dplyr", "tidyr", "ggplot2", "corrplot")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(corrplot)

cat("Please select your WHO Air Quality Excel file.\n")

file_path <- file.choose()

excel_data <- read_excel(file_path, col_names = FALSE)

lines <- as.character(excel_data[[1]])
lines <- lines[!is.na(lines)]

if (length(lines) < 2) {
  stop("The selected file does not contain enough data.")
}

air <- read.csv(
  text = paste(lines, collapse = "\n"),
  header = TRUE,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = c("", "NA", "N/A"),
  strip.white = TRUE
)

names(air) <- trimws(names(air))

cat("\n========== DATASET LOADED ==========\n")
cat("Rows:", nrow(air), "\n")
cat("Columns:", ncol(air), "\n")
cat("\nColumn names:\n")
print(names(air))
cat("\nFirst six rows:\n")
print(head(air))

required_cols <- c(
  "who_region",
  "country_name",
  "city",
  "year",
  "pm10_concentration",
  "pm25_concentration",
  "no2_concentration"
)

missing_cols <- setdiff(required_cols, names(air))

if (length(missing_cols) > 0) {
  stop(
    "Missing columns: ",
    paste(missing_cols, collapse = ", "),
    ". Check that the first column was parsed correctly."
  )
}

numeric_cols <- intersect(
  c(
    "year",
    "pm10_concentration",
    "pm25_concentration",
    "no2_concentration",
    "pm10_tempcov",
    "pm25_tempcov",
    "no2_tempcov",
    "number_stations",
    "population",
    "latitude",
    "longitude"
  ),
  names(air)
)

for (col in numeric_cols) {
  air[[col]] <- suppressWarnings(
    as.numeric(as.character(air[[col]]))
  )
}

air <- air %>%
  mutate(
    country_name = trimws(as.character(country_name)),
    city = trimws(as.character(city)),
    who_region = trimws(as.character(who_region))
  ) %>%
  mutate(
