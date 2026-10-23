
# ==============================================================
# MCA PROJECT: GLOBAL AIR QUALITY ANALYSIS AND VISUALIZATION
# Dataset: WHO Ambient Air Quality Database, Version 2026
# ==============================================================

# 1. INSTALL AND LOAD PACKAGES

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

# 2. SELECT YOUR EXCEL FILE

cat("Please select your WHO Air Quality Excel file.\n")

file_path <- file.choose()

# 3. READ DATA STORED IN THE FIRST COLUMN

excel_data <- read_excel(file_path, col_names = FALSE)

lines <- as.character(excel_data[[1]])
lines <- lines[!is.na(lines)]

if (length(lines) < 2) {
  stop("The selected file does not contain enough data.")
}

# Each Excel cell contains one CSV record.
air <- read.csv(
  text = paste(lines, collapse = "\n"),
  header = TRUE,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = c("", "NA", "N/A"),
  strip.white = TRUE
)

# Remove accidental spaces from column names.
names(air) <- trimws(names(air))

cat("\n========== DATASET LOADED ==========\n")
cat("Rows:", nrow(air), "\n")
cat("Columns:", ncol(air), "\n")
cat("\nColumn names:\n")
print(names(air))
cat("\nFirst six rows:\n")
print(head(air))

# 4. VERIFY REQUIRED COLUMNS

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

# 5. CONVERT NUMERIC COLUMNS

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

# 6. CLEAN THE DATA

air <- air %>%
  mutate(
    country_name = trimws(as.character(country_name)),
    city = trimws(as.character(city)),
    who_region = trimws(as.character(who_region))
  ) %>%
  mutate(
    across(
      any_of(c(
        "pm10_concentration",
        "pm25_concentration",
        "no2_concentration"
      )),
      ~ replace(.x, .x < 0, NA_real_)
    )
  ) %>%
  filter(
    !is.na(country_name),
    !is.na(year)
  )

analysis_data <- air %>%
  filter(
    if_any(
      all_of(c(
        "pm10_concentration",
        "pm25_concentration",
        "no2_concentration"
      )),
      ~ !is.na(.x)
    )
  )

# Create output folders beside the selected Excel file.
output_dir <- file.path(dirname(file_path), "Air_Quality_Output")
plot_dir <- file.path(output_dir, "plots")

dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  analysis_data,
  file.path(output_dir, "cleaned_air_quality.csv"),
  row.names = FALSE
)

cat("\nCleaned records:", nrow(analysis_data), "\n")

# 7. MISSING VALUE ANALYSIS

missing_summary <- data.frame(
  Variable = names(air),
  Missing_Count = sapply(air, function(x) sum(is.na(x))),
  Missing_Percentage = round(
    sapply(air, function(x) mean(is.na(x)) * 100),
    2
  )
)

write.csv(
  missing_summary,
  file.path(output_dir, "missing_value_summary.csv"),
  row.names = FALSE
)

# 8. DESCRIPTIVE STATISTICS

pollutants <- c(
  "pm10_concentration",
  "pm25_concentration",
  "no2_concentration"
)

descriptive_stats <- bind_rows(
  lapply(pollutants, function(variable) {
    
    x <- analysis_data[[variable]]
    x <- x[is.finite(x)]
    
    data.frame(
      Pollutant = variable,
      Count = length(x),
      Mean = if (length(x) > 0) mean(x) else NA_real_,
      Median = if (length(x) > 0) median(x) else NA_real_,
      Standard_Deviation =
        if (length(x) > 1) sd(x) else NA_real_,
      Minimum = if (length(x) > 0) min(x) else NA_real_,
      Maximum = if (length(x) > 0) max(x) else NA_real_
    )
  })
)

write.csv(
  descriptive_stats,
  file.path(output_dir, "descriptive_statistics.csv"),
  row.names = FALSE
)

cat("\n========== DESCRIPTIVE STATISTICS ==========\n")
print(descriptive_stats)

# 9. ANNUAL POLLUTION TRENDS

annual_data <- analysis_data %>%
  group_by(year) %>%
  summarise(
    PM25 = if (all(is.na(pm25_concentration))) NA_real_
    else mean(pm25_concentration, na.rm = TRUE),
    PM10 = if (all(is.na(pm10_concentration))) NA_real_
    else mean(pm10_concentration, na.rm = TRUE),
    NO2 = if (all(is.na(no2_concentration))) NA_real_
    else mean(no2_concentration, na.rm = TRUE),
    .groups = "drop"
  )

write.csv(
  annual_data,
  file.path(output_dir, "annual_pollution_trends.csv"),
  row.names = FALSE
)

annual_long <- annual_data %>%
  pivot_longer(
    cols = c(PM25, PM10, NO2),
    names_to = "Pollutant",
    values_to = "Concentration"
  ) %>%
  filter(is.finite(Concentration))

p1 <- ggplot(
  annual_long,
  aes(year, Concentration, color = Pollutant)
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  labs(
    title = "Annual Air Pollution Trends",
    x = "Year",
    y = "Mean concentration (µg/m³)",
    color = "Pollutant"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "01_annual_trends.png"),
  p1, width = 10, height = 6
)

# 10. TOP 15 CITIES BY PM2.5

city_data <- analysis_data %>%
  filter(
    !is.na(city),
    !is.na(pm25_concentration)
  ) %>%
  group_by(city, country_name) %>%
  summarise(
    Average_PM25 = mean(pm25_concentration),
    Observations = n(),
    .groups = "drop"
  ) %>%
  filter(Observations >= 3) %>%
  slice_max(
    Average_PM25,
    n = 15,
    with_ties = FALSE
  ) %>%
  arrange(Average_PM25)

write.csv(
  city_data,
  file.path(output_dir, "top_cities_pm25.csv"),
  row.names = FALSE
)

p2 <- ggplot(
  city_data,
  aes(
    x = reorder(paste(city, country_name, sep = ", "),
                Average_PM25),
    y = Average_PM25
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 15 Cities by Average PM2.5",
    subtitle = "Minimum three records per city",
    x = "City",
    y = "Average PM2.5 (µg/m³)"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "02_top_cities.png"),
  p2, width = 10, height = 7
)

# 11. COUNTRY COMPARISON

country_data <- analysis_data %>%
  filter(!is.na(pm25_concentration)) %>%
  group_by(country_name) %>%
  summarise(
    Average_PM25 = mean(pm25_concentration),
    Observations = n(),
    .groups = "drop"
  ) %>%
  filter(Observations >= 5) %>%
  slice_max(
    Average_PM25,
    n = 15,
    with_ties = FALSE
  ) %>%
  arrange(Average_PM25)

write.csv(
  country_data,
  file.path(output_dir, "country_comparison.csv"),
  row.names = FALSE
)

p3 <- ggplot(
  country_data,
  aes(
    x = reorder(country_name, Average_PM25),
    y = Average_PM25
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Countries with Highest Average PM2.5",
    x = "Country",
    y = "Average PM2.5 (µg/m³)"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "03_country_comparison.png"),
  p3, width = 10, height = 7
)

# 12. INDIA AIR QUALITY ANALYSIS

india <- analysis_data %>%
  filter(grepl("India", country_name, ignore.case = TRUE))

india_yearly <- india %>%
  group_by(year) %>%
  summarise(
    PM25 = if (all(is.na(pm25_concentration))) NA_real_
    else mean(pm25_concentration, na.rm = TRUE),
    PM10 = if (all(is.na(pm10_concentration))) NA_real_
    else mean(pm10_concentration, na.rm = TRUE),
    NO2 = if (all(is.na(no2_concentration))) NA_real_
    else mean(no2_concentration, na.rm = TRUE),
    .groups = "drop"
  )

write.csv(
  india_yearly,
  file.path(output_dir, "india_annual_analysis.csv"),
  row.names = FALSE
)

india_long <- india_yearly %>%
  pivot_longer(
    cols = c(PM25, PM10, NO2),
    names_to = "Pollutant",
    values_to = "Concentration"
  ) %>%
  filter(is.finite(Concentration))

p4 <- ggplot(
  india_long,
  aes(year, Concentration, color = Pollutant)
) +
  geom_line(linewidth = 0.8) +
  geom_point() +
  labs(
    title = "Air Quality Trends in India",
    x = "Year",
    y = "Mean concentration (µg/m³)",
    color = "Pollutant"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "04_india_trends.png"),
  p4, width = 10, height = 6
)

# 13. PM2.5 VS PM10 SCATTER PLOT

scatter_data <- analysis_data %>%
  filter(
    is.finite(pm25_concentration),
    is.finite(pm10_concentration)
  )

p5 <- ggplot(
  scatter_data,
  aes(pm25_concentration, pm10_concentration)
) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Relationship Between PM2.5 and PM10",
    x = "PM2.5 (µg/m³)",
    y = "PM10 (µg/m³)"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "05_pm25_pm10_scatter.png"),
  p5, width = 8, height = 6
)

# 14. CORRELATION HEATMAP

cor_data <- analysis_data %>%
  select(
    pm10_concentration,
    pm25_concentration,
    no2_concentration
  )

cor_matrix <- cor(
  cor_data,
  use = "pairwise.complete.obs"
)

write.csv(
  cor_matrix,
  file.path(output_dir, "correlation_matrix.csv")
)

png(
  file.path(plot_dir, "06_correlation_heatmap.png"),
  width = 1000,
  height = 800
)

corrplot(
  cor_matrix,
  method = "color",
  type = "upper",
  addCoef.col = "black",
  tl.col = "black",
  tl.srt = 45,
  title = "Pollutant Correlation Matrix",
  mar = c(0, 0, 3, 0)
)

dev.off()

# 15. WHO REGION COMPARISON

region_data <- analysis_data %>%
  filter(
    !is.na(who_region),
    !is.na(pm25_concentration)
  ) %>%
  group_by(who_region) %>%
  summarise(
    Average_PM25 = mean(pm25_concentration),
    Observations = n(),
    .groups = "drop"
  ) %>%
  filter(Observations >= 5) %>%
  arrange(desc(Average_PM25))

write.csv(
  region_data,
  file.path(output_dir, "region_analysis.csv"),
  row.names = FALSE
)

p7 <- ggplot(
  region_data,
  aes(
    x = reorder(who_region, Average_PM25),
    y = Average_PM25
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Average PM2.5 by WHO Region",
    x = "WHO region",
    y = "Average PM2.5 (µg/m³)"
  ) +
  theme_minimal()

ggsave(
  file.path(plot_dir, "07_region_comparison.png"),
  p7, width = 9, height = 6
)

# 16. CREATE HTML REPORT

plot_files <- c(
  "01_annual_trends.png",
  "02_top_cities.png",
  "03_country_comparison.png",
  "04_india_trends.png",
  "05_pm25_pm10_scatter.png",
  "06_correlation_heatmap.png",
  "07_region_comparison.png"
)

plot_titles <- c(
  "Annual Pollution Trends",
  "Top Cities by PM2.5",
  "Country Comparison",
  "India Air Quality Trends",
  "PM2.5 and PM10 Relationship",
  "Pollutant Correlation Heatmap",
  "WHO Region Comparison"
)

html <- c(
  "<!DOCTYPE html>",
  "<html><head><meta charset='UTF-8'>",
  "<title>MCA Air Quality Analysis</title>",
  "<style>",
  "body{font-family:Arial;max-width:1000px;margin:35px auto;padding:0 20px;line-height:1.6}",
  "img{max-width:100%;height:auto}",
  "table{border-collapse:collapse}",
  "td,th{padding:8px;border:1px solid #ddd}",
  "</style></head><body>",
  "<h1>Global Air Quality Analysis and Visualization Using R</h1>",
  "<h2>Abstract</h2>",
  "<p>This project analyzes the WHO Ambient Air Quality Database",
  "using R. Data cleaning, descriptive statistics, comparisons,",
  "correlation analysis and visualization are used to study reported",
  "PM2.5, PM10 and NO2 concentrations.</p>",
  "<h2>Objectives</h2>",
  "<ul><li>Clean and prepare the dataset.</li>",
  "<li>Calculate descriptive statistics.</li>",
  "<li>Compare countries, cities and WHO regions.</li>",
  "<li>Study annual trends and pollutant relationships.</li></ul>",
  "<h2>Dataset Summary</h2>",
  paste0("<p>Records after cleaning: ", nrow(analysis_data), "</p>"),
  paste0("<p>Countries represented: ",
         n_distinct(analysis_data$country_name), "</p>"),
  paste0("<p>Year range: ",
         min(analysis_data$year, na.rm = TRUE), " to ",
         max(analysis_data$year, na.rm = TRUE), "</p>"),
  "<h2>Descriptive Statistics</h2>",
  paste(
    capture.output(print(descriptive_stats, row.names = FALSE)),
    collapse = "<br>"
  ),
  "<h2>Visualizations</h2>"
)

for (i in seq_along(plot_files)) {
  html <- c(
    html,
    paste0("<h3>", plot_titles[i], "</h3>"),
    paste0("<img src='plots/", plot_files[i],
           "' alt='", plot_titles[i], "'>")
  )
}

html <- c(
  html,
  "<h2>Conclusion</h2>",
  "<p>The analysis summarizes reported air pollution measurements",
  "and explores differences across locations and years. Results",
  "should be interpreted in light of differences in data coverage,",
  "monitoring stations and observation counts.</p>",
  "<h2>Limitations</h2>",
  "<p>Measurements vary by year, location and monitoring coverage.",
  "Averages from different locations or periods are not necessarily",
  "directly comparable. Correlation does not establish causation.</p>",
  "<h2>Reference</h2>",
  "<p>World Health Organization (WHO), Ambient Air Quality Database,",
  "Version 2026.</p>",
  "</body></html>"
)

writeLines(
  html,
  file.path(output_dir, "project_report.html")
)

# 17. FINAL OUTPUT

cat("\n====================================\n")
cat("AIR QUALITY PROJECT FINISHED\n")
cat("====================================\n")
cat("Output folder:", output_dir, "\n")
cat("Cleaned dataset: cleaned_air_quality.csv\n")
cat("Statistics: descriptive_statistics.csv\n")
cat("Charts folder: plots/\n")
cat("Report: project_report.html\n")

# Open report automatically when possible
browseURL(
  normalizePath(
    file.path(output_dir, "project_report.html"),
    winslash = "/",
    mustWork = TRUE
  )
)
