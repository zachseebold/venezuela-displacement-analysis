#------------------------------------------------------------------------------
#Script: 01_clean_worldbank.R
#
# Purpose:
# Clean World Bank World Development Indicators for Venezuela,
# reshape into tidy format, and save the processed dataset
#------------------------------------------------------------------------------

library(janitor)
library(tidyverse)

# World Bank exports include metadata before the header row,
# so import without headers and promote the first row to column names
worldbank_raw <- read.csv("data/raw/worldbank_venezuela_raw.csv", header = FALSE)

worldbank_clean <- worldbank_raw %>% 
  row_to_names(row_number = 1) %>%
  remove_empty(c("rows", "cols")) %>%
  clean_names()

# Pivoting to long, then wide
worldbank_clean <- worldbank_clean %>%
  pivot_longer(
    cols = -c(country_name, country_code, series_name, series_code),
    names_to = "year",
    values_to = "value"
  ) %>%
  filter(!is.na(series_name), series_name != "") %>% 
  mutate(year = parse_number(year)) %>%

  select(-series_code) %>%

  # Remove duplicate observations created during reshaping
  distinct(country_name, country_code, series_name, year, .keep_all = TRUE) %>%
  pivot_wider(
    names_from = series_name,
    values_from = value
  )

worldbank_clean <- worldbank_clean %>% 
  select(-country_name, -country_code)

# World Bank represents missing observations as "..";
# convert to NA before parsing numeric values
worldbank_clean <- worldbank_clean %>%
  mutate(across(
    c(
      `Net migration`, 
      `Population, total`, 
      `Inflation, consumer prices (annual %)`, 
      `Unemployment, total (% of total labor force) (national estimate)`, 
      `GDP growth (annual %)`, 
      `GDP per capita (current US$)`
    ), 
    ~ parse_number(na_if(as.character(.), ".."))
  ))

worldbank_clean <- worldbank_clean %>%
  rename(
    net_migration = `Net migration`,
    population = `Population, total`,
    inflation = `Inflation, consumer prices (annual %)`,
    unemployment = `Unemployment, total (% of total labor force) (national estimate)`,
    gdp_growth = `GDP growth (annual %)`,
    gdp_per_capita = `GDP per capita (current US$)`
  )

glimpse(worldbank_clean)
worldbank_clean %>%
  summarise(across(everything(), ~sum(is.na(.))))

saveRDS(worldbank_clean, "data/processed/worldbank_venezuela_clean.rds")