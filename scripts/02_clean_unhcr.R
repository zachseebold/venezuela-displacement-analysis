#------------------------------------------------------------------------------
#Script: 02_clean_unhcr.R
#
# Purpose:
# Clean UNHCR Refugee Data Finder statistics for Venezuela and save the processed dataset
#------------------------------------------------------------------------------

library(janitor)
library(tidyverse)

# UNHCR export includes the header as the first row,
# so import without headers and promote the first row to column names
unhcr_raw <- read.csv("data/raw/unhcr_venezuela_raw.csv", header = FALSE)

unhcr_clean <- unhcr_raw %>% 
  row_to_names(row_number = 1) %>% 
  select(
    `Year`, 
    `Refugees`, 
    `Asylum-seekers`, 
    `Other people in need of international protection`, 
    `Others of concern`
  ) %>% 
  mutate(across(everything(), as.numeric)) %>% 
  rename(
    year = Year,
    refugees = Refugees,
    asylum_seekers = `Asylum-seekers`,
    other_protection = `Other people in need of international protection`,
    others_of_concern = `Others of concern`
  )

glimpse(unhcr_clean)
unhcr_clean %>%
  summarise(across(everything(), ~sum(is.na(.))))

saveRDS(unhcr_clean, "data/processed/unhcr_venezuela_clean.rds")