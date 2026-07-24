#=============================================================
#Script: 03_merge_visualize.R
#
# Purpose:
# Merge World Bank and UNHCR datasets,
# derive additional variables and prepare for analysis
# ============================================================

library(tidyverse)

# LOADING PROCESSED DATA
worldbank_clean <- read_rds("data/processed/worldbank_venezuela_clean.rds")
unhcr_clean <- read_rds("data/processed/unhcr_venezuela_clean.rds")

# MERGE BY YEAR
venezuela_clean <- worldbank_clean %>% 
  left_join(unhcr_clean, by = "year") %>% 
  mutate(
    year = as.integer(year),
    total_persons_of_concern = 
      refugees +
      asylum_seekers +
      other_protection +
      others_of_concern,   
    persons_of_concern_rate =
      total_persons_of_concern / 
      population * 100
  )

# PREVIEW
glimpse(venezuela_clean)
venezuela_clean %>% 
  summarise(across(everything(), ~sum(is.na(.))))

# SAVING PROCESSED DATASET
saveRDS(venezuela_clean, "data/processed/venezuela_clean.rds")

# VISUALIZE
