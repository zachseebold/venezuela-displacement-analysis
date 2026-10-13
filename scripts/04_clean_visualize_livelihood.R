#------------------------------------------------------------------------------
# Script: 04_clean_visualize_livelihood.R
#
# Purpose:
# Clean Premise Data survey dataset,
# derive dummies and prepare for analysis
#------------------------------------------------------------------------------
library(tidyverse)
library(fixest)
library(dotwhisker)

#------------------------------------------------------------------------------
# Create plotting theme
#------------------------------------------------------------------------------
plot_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

livelihood_raw <- read.csv("data/raw/livelihood_venezuela_raw.csv")

#------------------------------------------------------------------------------
# Clean dataset
#------------------------------------------------------------------------------
# Separate core explanatory variables into binaries for regression
livelihood_clean <- livelihood_raw %>%
  rename(household_migration = has_someone_in_family_moved_outside_of_venezuela) %>%
  filter(household_migration %in% c("Yes", "No,")) %>% 
  mutate(
    household_migration = case_when(
    household_migration == "Yes" ~ 1L,
    household_migration == "No," ~ 0L
    ) 
  ) %>% 
  select(household_migration, financial_situation, portion_of_financial_aid_from_family_outside_of_venezuela_spent_on_food, had_opportunity_to_purchase_clap_food_boxes, opinion_on_clap_boxes_containing_enough_food_for_family, have_received_food_in_poor_condition_in_clap_food_boxes, employment_status, geography, gender, age, education, what_is_the_employment_situation_of_the_head_of_household, submission_state, submission_date) %>% 
  rename(food_insecure = financial_situation) %>% 
  mutate(
    food_insecure = case_when(
      food_insecure == "I cannot afford enough food for my family" ~ 1L,
      TRUE ~ 0L
    )
  ) %>% 
  rename(aid_100_food = portion_of_financial_aid_from_family_outside_of_venezuela_spent_on_food) %>% 
  mutate(
    aid_100_food = case_when(
      aid_100_food == "All of it (100%)" ~ 1L,
      aid_100_food %in% c("I'm not sure", "I prefer not to answer") ~ NA_integer_,
      is.na(aid_100_food) ~ 0L,
      TRUE ~ 0L
    )
  ) %>% 
  rename(clap_insufficient = opinion_on_clap_boxes_containing_enough_food_for_family) %>% 
  mutate(
    clap_insufficient = case_when(
      clap_insufficient == "No" ~ 1L,
      clap_insufficient == "Yes" ~ 0L,
      had_opportunity_to_purchase_clap_food_boxes == "No" ~ 0L,
      is.na(clap_insufficient) ~ 0L,
      TRUE ~ NA_integer_
    )
  ) %>% 
  rename(clap_spoiled = have_received_food_in_poor_condition_in_clap_food_boxes) %>% 
  mutate(
    clap_spoiled = case_when(
      clap_spoiled %in% c("Yes, two or more time", "Yes, one time") ~ 1L,
      TRUE ~ 0L
    )
  )

# Recode demographic dummies
livelihood_clean <- livelihood_clean %>% 
  mutate(
    is_rural      = if_else(geography == "Rural", 1L, 0L),
    is_periurban  = if_else(geography == "Suburban/Peri-urban", 1L, 0L),
    is_unemployed = if_else(employment_status %in% c("I am unemployed", "Unemployed"), 1L, 0L),
    is_female     = if_else(gender == "Female", 1L, 0L)
  )
    
# Format fixed identifiers
livelihood_clean <- livelihood_clean %>% 
  mutate(
    state_fe      = as.factor(submission_state),
    month_fe      = as.factor(format(as.Date(submission_date), "%Y-%m"))
  )

# Recode demographic brackets
livelihood_clean <- livelihood_clean %>% 
  mutate(
    education_level = case_when(
      str_detect(education, "(?i)primary|no formal") ~ "Primary or Less",
      str_detect(education, "(?i)secondary|high school") ~ "Secondary",
      str_detect(education, "(?i)technical|polytechnic") ~ "Technical",
      str_detect(education, "(?i)university|college|post") ~ "Tertiary",
      TRUE ~ NA_character_
    ),
    # Set Secondary as the baseline reference category
    education_level = fct_relevel(as.factor(education_level), "Secondary"),
    age_bracket = case_when(
      str_detect(age, "18 to 25") ~ "18 to 25 years old",
      str_detect(age, "26 to 35") ~ "26 to 35 years old",
      str_detect(age, "36 to 45") ~ "36 to 45 years old",
      str_detect(age, "Over 45")  ~ "Over 45 years old",
      TRUE ~ NA_character_
    ),
    # Set youngest adult cohort as the baseline reference category
    age_bracket = fct_relevel(as.factor(age_bracket), "18 to 25 years old")
  )

# Select observations
livelihood_clean <- livelihood_clean %>% 
  select(
    # Dependent variable
    household_migration,
    
    # Core explanatory variables
    food_insecure,
    aid_100_food,
    clap_insufficient,
    clap_spoiled,
    
    # Recoded demographic observations
    is_rural,
    is_periurban,
    is_unemployed,
    is_female,
    age_bracket,
    education_level,
    
    # Fixed effects
    state_fe,
    month_fe
  )

glimpse(livelihood_clean)

saveRDS(livelihood_clean, "data/processed/livelihood_venezuela_clean.rds")

#------------------------------------------------------------------------------
# Fifth visual: box and whisker plot with regression
# for micro-level drivers of emigration
#------------------------------------------------------------------------------
# Model pooled ordinary least squares regression
p3 <- feols(
  household_migration ~ food_insecure + aid_100_food + clap_insufficient + clap_spoiled +
    is_rural + is_periurban + is_unemployed + is_female + 
    age_bracket + education_level,
  data = livelihood_clean,
  # Heteroskedasticity-robust standard errors
  vcov = "hetero"
)

# Model primary linear probability model regression with fixed effects
p4 <- feols(
  household_migration ~ food_insecure + aid_100_food + clap_insufficient + clap_spoiled +
    is_rural + is_periurban + is_unemployed + is_female + 
    age_bracket + education_level | 
    state_fe + month_fe,
  data = livelihood_clean,
  # Clustered standard errors by state
  cluster = ~state_fe
)

etable(
  p3, p4,
  headers = c("Pooled OLS", "LPM with fixed effects"),
  order = c("food_insecure", "aid_100_food", "clap_insufficient", "clap_spoiled"),
  se.below = TRUE,
  digits = 3
)

p4_dataframe <- as.data.frame(coeftable(p4)) %>% 
  tibble::rownames_to_column(var = "term") %>% 
  rename(estimate = Estimate, std.error = `Std. Error`) %>% 
  filter(term %in% c("food_insecure", "aid_100_food", "clap_insufficient", "clap_spoiled", "is_unemployed")) %>% 
  mutate(
    term = recode_values(
      term,
      "food_insecure"     ~ "Facing Severe Food Insecurity",
      "aid_100_food"      ~ "100% of Remittance Spent on Food",
      "clap_insufficient" ~ "Quantity of Food from CLAP Box Insufficient",
      "clap_spoiled"      ~ "Has Received Spoiled Food from CLAP Box",
      "is_unemployed"     ~ "Head of Household is Unemployed"
    ),
  model = term
  )

driver_colors <- c(
  "Facing Severe Food Insecurity" = "#513b56",
  "100% of Remittance Spent on Food" = "#525174",
  "Quantity of Food from CLAP Box Insufficient" = "#348aa7",
  "Has Received Spoiled Food from CLAP Box" = "#5dd39e",
  "Head of Household is Unemployed" = "#bce784"
)

micro_drivers_plot <- dwplot(
    p4_dataframe,
    dot_args = list(size = 2.5),
    whisker_args = list()
  ) +
  geom_vline(xintercept = 0, color = "gray40", linetype = "dashed", linewidth = 0.8) +
  scale_x_continuous(
    labels = scales::label_percent(accuracy = 1),
    breaks = seq(-0.10, 0.70, by = 0.10)
  ) +
  plot_theme +
  theme(legend.position = "none") +
  aes(color = term) +
  scale_color_manual(values = driver_colors) +
  labs(
    title = "Micro-Level Drivers of Venezuelan Emigration",
    subtitle = "Linear Probability Model with State & Survey Month Fixed Effects",
    x = "Percentage Point Change in Probability of a Family Member Having Emigrated",
    caption = "Source: Premise Mobile open-source survey (Dec 2020 – Mar 2021). Standard errors clustered at state level."
  )

# Check the actual number of observations used in the models
cat("Cleaned Dataset Rows: ", nrow(livelihood_clean), "\n",
    "Model 1 (Pooled OLS) Rows: ", nobs(p3), "\n",
    "Model 2 (Fixed Effects) Rows: ", nobs(p4), "\n", sep = "")

# NA values account for the difference in number of observations
livelihood_clean %>%
  summarize(across(everything(), ~sum(is.na(.))))

ggsave(
  filename = "figures/micro_drivers.png",
  width = 12,
  height = 6,
  dpi = 300,
  plot = micro_drivers_plot
)
