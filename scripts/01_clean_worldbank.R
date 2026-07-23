library(janitor)
library(tidyverse)

#LOADING WORLD BANK DATA
worldbank_venezuela_raw <- read.csv("data/raw/worldbank_venezuela_raw.csv", header = FALSE)

#CLEANING
worldbankdata_clean <- worldbank_venezuela_raw %>% 
  row_to_names(row_number = 1) %>%
  remove_empty(c("rows", "cols")) %>%
  clean_names()

# PIVOTING TO LONG, THEN WIDE
worldbankdata_clean <- worldbankdata_clean %>%
  pivot_longer(
    cols = -c(country_name, country_code, series_name, series_code),
    names_to = "Year",
    values_to = "value"
  ) %>%
  filter(!is.na(series_name), series_name != "") %>% 
  mutate(Year = parse_number(Year)) %>%

  select(-series_code) %>%

distinct(country_name, country_code, series_name, Year, .keep_all = TRUE) %>%
  pivot_wider(
    names_from = series_name,
    values_from = value
  )

worldbankdata_clean <- worldbankdata_clean %>% 
  select(everything(), -"country_name", -"country_code")

worldbankdata_clean <- worldbankdata_clean %>%
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

# PREVIEWING
view(worldbankdata_clean)

#SAVING PROCESSED DATASET
saveRDS(worldbankdata_clean, "data/processed/worldbank_venezuela_clean.rds")
