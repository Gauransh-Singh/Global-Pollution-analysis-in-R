# Global Air Quality Analysis and Visualization Using R

<p align="center">
  <a href="https://gauransh-singh.github.io/Global-Pollution-analysis-in-R/">
    <img src="https://img.shields.io/badge/🌍_View_Live_Project-2ea44f?style=for-the-badge" alt="View Live Project" />
  </a>
</p>


**MCA Project | Data Analytics and Visualization**

This project analyzes the WHO Ambient Air Quality Database (Version 2026) using R. It includes data cleaning, descriptive statistics, country/city comparisons, annual trends, and pollutant relationship analysis.

## Project Overview

The project explores three key air pollutants:

- **PM2.5** — fine particulate matter
- **PM10** — particulate matter
- **NO₂** — nitrogen dioxide

The analysis generates summary tables, CSV outputs, visualizations, and an HTML report.

## Dataset

**Source:** World Health Organization (WHO), Ambient Air Quality Database, Version 2026  
https://www.who.int/data/gho/data/themes/air-pollution/who-air-quality-database

The supplied workbook stores CSV-formatted records in the first Excel column. The R script parses those records into separate columns before analysis.

## Technologies Used

- **R**
- **RStudio**
- `readxl`
- `dplyr`
- `tidyr`
- `ggplot2`
- `corrplot`

The R script installs missing packages automatically.

## How to Run

1. Clone or download this repository.
2. Open `air_quality_project.R` in RStudio.
3. Click **Source** to run the complete script.
4. When prompted, select the WHO Excel dataset.
5. Wait for the script to finish.
6. The script creates an `Air_Quality_Output` folder next to the selected dataset.

## Visualizations

The script generates these plots:

1. Annual pollution trends
2. Top cities by average PM2.5
3. Country comparison by average PM2.5
4. India annual air quality trends
5. PM2.5 versus PM10 scatter plot
6. Pollutant correlation heatmap
7. Average PM2.5 by WHO region

## Plot Gallery

<table>
  <tr>
    <td width="25%" valign="middle"><strong>Annual trends</strong></td>
    <td width="75%" align="center"><img width="600" alt="Annual pollution trends" src="https://github.com/user-attachments/assets/7f0908f3-ac8a-421a-8371-9b869746b6ef" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>Top cities by PM2.5</strong></td>
    <td align="center"><img width="600" alt="Top cities by PM2.5" src="https://github.com/user-attachments/assets/219d9d73-057c-4f0a-9277-1b9619984293" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>Country comparison</strong></td>
    <td align="center"><img width="600" alt="Country comparison" src="https://github.com/user-attachments/assets/24e5db11-2f16-4061-a4e7-883c23cf326f" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>India trends</strong></td>
    <td align="center"><img width="600" alt="India air quality trends" src="https://github.com/user-attachments/assets/ec6466f1-bb66-4554-9a5e-52240ebdbeae" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>PM2.5 vs PM10</strong></td>
    <td align="center"><img width="600" alt="PM2.5 versus PM10" src="https://github.com/user-attachments/assets/462ad196-d4b0-4a91-a44e-bf6d4abcf3a3" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>Correlation heatmap</strong></td>
    <td align="center"><img width="600" alt="Pollutant correlation heatmap" src="https://github.com/user-attachments/assets/9ee01a3b-89a0-405b-bd06-3d9596c7211f" /></td>
  </tr>
  <tr>
    <td valign="middle"><strong>WHO region comparison</strong></td>
    <td align="center"><img width="600" alt="WHO region comparison" src="https://github.com/user-attachments/assets/376a07d6-83a6-47fd-93c9-c43715679a8a" /></td>
  </tr>
</table>


## Output Files

The generated `Air_Quality_Output/` folder contains:

- `cleaned_air_quality.csv` — cleaned observations used in the analysis
- `descriptive_statistics.csv` — count, mean, median, standard deviation, minimum, and maximum
- `missing_value_summary.csv` — missing-value counts and percentages
- `annual_pollution_trends.csv` — annual mean pollutant values
- `top_cities_pm25.csv` — city-level PM2.5 comparison
- `country_comparison.csv` — country-level PM2.5 comparison
- `india_annual_analysis.csv` — annual pollutant summary for India
- `correlation_matrix.csv` — pollutant correlation matrix
- `region_analysis.csv` — PM2.5 comparison by WHO region
- `plots/` — generated chart images
- `project_report.html` — automatically generated HTML report

## Analysis Workflow

1. Import the Excel workbook.
2. Parse CSV-formatted records from the first column.
3. Convert year and pollutant columns to numeric values.
4. Treat negative pollutant measurements as missing.
5. Exclude rows without country/year and rows without any available pollutant value.
6. Calculate descriptive statistics.
7. Compare locations and visualize trends.
8. Export cleaned data, result tables, charts, and an HTML report.

## Limitations

- Data availability and monitoring coverage vary by location and year.
- Averages may not be directly comparable when observation counts or monitoring-station coverage differ.
- Missing values are not imputed.
- Correlation does not imply causation.
- Rankings are descriptive summaries of the records and are not definitive population-exposure estimates.

## Repository Structure

Use this structure in your GitHub repository:

```text
Air-Quality-Analysis-R/
├── air_quality_project.R
├── README.md
├── .gitattributes
├── who-ambient-air-quality-database-version-2026-v8.xlsx
├── plots/
│   ├── annual_trends.png
│   ├── top_cities_pm25.png
│   ├── country_comparison.png
│   ├── india_trends.png
│   ├── pm25_vs_pm10.png
│   ├── correlation_heatmap.png
│   └── region_comparison.png
└── Air_Quality_Output/
    ├── project_report.html
    ├── cleaned_air_quality.csv
    ├── descriptive_statistics.csv
    └── ...
```


## References

- World Health Organization (WHO), Ambient Air Quality Database, Version 2026: https://www.who.int/data/gho/data/themes/air-pollution/who-air-quality-database
- R Project: https://www.r-project.org/
- Tidyverse: https://www.tidyverse.org/
- ggplot2: https://ggplot2.tidyverse.org/

## Academic Details

- **Student Name:** Gauransh Singh
- **Programme:** MCA
