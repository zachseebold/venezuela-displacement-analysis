library(janitor)
library(tidyverse)

# LOADING UNHCR DATA
unhcr_venezuela_raw <- read.csv("data/raw/unhcr_venezuela_raw.csv", header = FALSE)

# CLEANING
unhcrdata_clean <- unhcr_venezuela_raw %>% 
  row_to_names(row_number = 1) %>% 
select(
  `Year`, 
  `Refugees`, 
  `Asylum-seekers`, 
  `Other people in need of international protection`, 
  `Others of concern`
) %>% 
  mutate(across(everything(), as.numeric))

# PREVIEWING
view(unhcrdata_clean)

#SAVING PROCESSED DATASET
saveRDS(unhcrdata_clean, "data/processed/unhcr_venezuela_clean.rds")