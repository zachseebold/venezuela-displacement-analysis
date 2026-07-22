library(janitor)
library(tidyverse)

#HANDLING WORLD BANK DATA
#CLEANING
worldbankdata_clean <- ffe41b00.ba54.456b.912e.6d9dad87ecfc_Data %>% 
  row_to_names(row_number = 1) %>%
  remove_empty(c("rows", "cols")) %>%
  clean_names()

# PIVOTING TO LONG, THEN WIDE
worldbankdata_final <- worldbankdata_clean %>%
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

worldbankdata_final <- worldbankdata_final %>% 
  select(everything(), -"country_name", -"country_code")

worldbankdata_final <- worldbankdata_final %>%
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
view(worldbankdata_final)

#HANDLING UNHCR DATA