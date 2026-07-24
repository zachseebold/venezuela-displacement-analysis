#=============================================================
#Script: 03_merge_visualize.R
#
# Purpose:
# Merge World Bank and UNHCR datasets,
# derive additional variables and prepare for analysis
# ============================================================

library(tidyverse)
library(scales)

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
# First visual: stacked area chart for composition of persons of concern by legal status
#
# Gather data, pivot long to format data for ggplot
migrant_composition <- venezuela_clean %>%
  select(year, refugees, asylum_seekers, 
         other_protection, others_of_concern) %>%
  pivot_longer(cols = -year, names_to = "legal_status", values_to = "count")

migrant_composition <- migrant_composition %>%
  mutate(
    legal_status = recode(
      legal_status,
      refugees = "Refugees",
      asylum_seekers = "Asylum Seekers",
      other_protection = "Other Protection",
      others_of_concern = "Others of Concern"
    ),
    legal_status = factor(
      legal_status,
      levels = c(
        "Refugees",
        "Asylum Seekers",
        "Other Protection",
        "Others of Concern"
      )
    )
  )

# Zooming to 2016-2025 as no significant visible changes occur prior to 2016 and
# relative to 2016-2025
ggplot(
  migrant_composition %>% 
    filter(year >= 2016),
  aes(
    x = year,
    y = count,
    fill = legal_status
  )
) +
geom_area() +
scale_fill_manual(
  values = c(
    "Refugees" = "#525174",
    "Asylum Seekers" = "#348aa7",
    "Other Protection" = "#5dd39e",
    "Others of Concern" = "#bce784"
  )
) +
scale_y_continuous(
  labels = scales::label_number(scale = 1e-6, suffix = "M"),
  breaks = seq(0, 10e6, by = 2e6)
) +
scale_x_continuous(
  breaks = 2016:2025
) +
theme_minimal(base_size = 13) +
theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
) +
labs(
  title = "Composition of Persons of Concern by Legal Status",
  subtitle = "UNHCR persons of concern of Venezuelan origin, 2016-2025",
  x = "Year",
  y = "Number of People",
  fill = "Legal Status",
  caption = "Source: UNHCR Refugee Data Finder. Author's calculations."
)