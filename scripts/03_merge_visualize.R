#------------------------------------------------------------------------------
# Script: 03_merge_visualize.R
#
# Purpose:
# Merge World Bank and UNHCR datasets,
# derive additional variables and prepare for analysis
#------------------------------------------------------------------------------

library(tidyverse)
library(scales)
library(ggrepel)
library(ggpmisc)
library(patchwork)

#------------------------------------------------------------------------------
# Create plotting theme
#------------------------------------------------------------------------------

status_colors <- c(
  "Refugees" = "#525174",
  "Asylum Seekers" = "#348aa7",
  "Other Protection" = "#5dd39e",
  "Others of Concern" = "#bce784"
)

plot_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

#------------------------------------------------------------------------------
# Merge datasets
#------------------------------------------------------------------------------
worldbank_clean <- read_rds("data/processed/worldbank_venezuela_clean.rds")
unhcr_clean <- read_rds("data/processed/unhcr_venezuela_clean.rds")

venezuela_clean <- worldbank_clean %>% 
  left_join(unhcr_clean, by = "year") %>% 
  mutate(
    year = as.integer(year),
    total_persons_of_concern = refugees + asylum_seekers + other_protection + others_of_concern,   
    persons_of_concern_change = total_persons_of_concern - lag(total_persons_of_concern)
  )

glimpse(venezuela_clean)
venezuela_clean %>% 
  summarise(across(everything(), ~sum(is.na(.))))

saveRDS(venezuela_clean, "data/processed/venezuela_clean.rds")

#------------------------------------------------------------------------------
# First visual: stacked area chart for composition of persons of concern
# by legal status
#------------------------------------------------------------------------------
# Gather data, pivot long to format data for ggplot
migrant_composition <- venezuela_clean %>%
  select(year, refugees, asylum_seekers, other_protection, others_of_concern) %>%
  pivot_longer(
    cols = -year,
    names_to = "legal_status",
    values_to = "count"
  ) %>%
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
composition_plot <- ggplot(
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
    values = status_colors
  ) +
  scale_y_continuous(
    labels = scales::label_number(scale = 1e-6, suffix = "M"),
    breaks = seq(0, 10e6, by = 2e6)
  ) +
  scale_x_continuous(
    breaks = 2016:2025
  ) +
  plot_theme +
  labs(
    title = "Composition of Persons of Concern by Legal Status",
    subtitle = "UNHCR persons of concern of Venezuelan origin, 2016-2025",
    x = "Year",
    y = "Number of People",
    fill = "Legal Status",
    caption = "Source: UNHCR Refugee Data Finder. Author's calculations."
  )

ggsave(
  filename = "figures/migrant_composition.png",
  width = 8,
  height = 6,
  dpi = 300,
  plot = composition_plot
)

#------------------------------------------------------------------------------
# Second visual: 100% stacked area chart for composition of
# persons of concern by legal status
#------------------------------------------------------------------------------
composition_percentage_plot <- ggplot(
  migrant_composition,
    aes(
      x = year,
      y = count,
      fill = legal_status
    )
  ) +
  geom_area(position = "fill") +
  scale_fill_manual(
    values = status_colors
  ) +
  scale_y_continuous(
    labels = scales::percent
  ) +
  scale_x_continuous(
    breaks = seq(2006, 2025, by = 2) 
  ) +
  plot_theme +
  labs(
    title = "Composition of Persons of Concern by Legal Status",
    subtitle = "UNHCR persons of concern of Venezuelan origin, 2006-2025",
    x = "Year",
    y = "% of Persons of Concern",
    fill = "Legal Status",
    caption = "Source: UNHCR Refugee Data Finder. Author's calculations."
  )

ggsave(
  filename = "figures/migrant_composition_percentage.png",
  width = 8,
  height = 6,
  dpi = 300,
  plot = composition_percentage_plot
)

#------------------------------------------------------------------------------
# Third visual: scatter plot with regression for relationship between
# persons of concern and GDP per capita
#------------------------------------------------------------------------------
# Gather data
economic_decline <- venezuela_clean %>%
  select(persons_of_concern_change, gdp_growth, year)

economic_decline <- economic_decline %>% 
  filter(!is.na(persons_of_concern_change))

p1 <- ggplot(
  economic_decline, 
  aes(
    x = gdp_growth,
    y = persons_of_concern_change
  )
) +
geom_point(
  size = 3,
  alpha = 0.8
) +
geom_smooth(method = "lm", se = TRUE, color = "#5dd39e", fill = "#bce784", linewidth = 1.2
) +
stat_poly_eq(
  aes(
    label = after_stat(rr.label)
  ),
  formula = y ~ x,
  parse = TRUE,
  label.x = "right",
  label.y = "top",
  size = 4
) +
scale_y_continuous(
  labels = scales::label_number(
    scale = 1e-6,
    suffix = "M"
  ),
  limits = c(-4e6, 5e6), 
  breaks = seq(-2e6, 3e6, by = 1e6) 
) +
scale_x_continuous(
  labels = scales::label_number(big.mark = ",")
) +
geom_text_repel(
  aes(label = year),
  size = 3,
  max.overlaps = Inf,
  box.padding = 0.4,
  point.padding = 0.2,
  segment.color = "gray60"
) +
theme_minimal() +
theme(
  plot.title    = element_text(face = "bold", size = 12), 
  plot.subtitle = element_text(size = 9, color = "gray30"),
  axis.title    = element_text(face = "bold", size = 10),
  panel.grid.minor = element_blank() 
) +
labs(
  title = "Concurrent Forced Displacement and Economic Decline",
  subtitle = "UNHCR persons of concern of Venezuelan origin, 2007-2025",
  x = "GDP Growth (Annual %)",
  y = "Δ Number of People"
)

# Very low correlation, so calculating whether correlation
# would be greater with a lagged GDP growth, as displacement may be delayed
# as resources deplete and systems fail
lag_results <- tibble(
  lag = 0:5
) %>%
  mutate(
    model = map(
      lag,
      ~ lm(
        persons_of_concern_change ~ lag(gdp_growth, .x),
        data = economic_decline
      )
    ),
    r_squared = map_dbl(
      model,
      ~ summary(.x)$r.squared
    )
  )

# A lag of two years produces an R^2 of 0.655
lag_results

# Plotting regression with lagged GDP growth
economic_lagged_2 <- economic_decline %>%
  arrange(year) %>%
    mutate(
      gdp_growth_lag2 = lag(gdp_growth, 2)
    ) %>%
      filter(!is.na(gdp_growth_lag2))

p2 <- ggplot(
  economic_lagged_2, 
  aes(
    x = gdp_growth_lag2,
    y = persons_of_concern_change
  )
) +
geom_point(
  size = 3,
  alpha = 0.8
) +
geom_smooth(method = "lm", se = TRUE, color = "#5dd39e", fill = "#bce784", linewidth = 1.2
) +
stat_poly_eq(
  aes(
    label = after_stat(rr.label)
  ),
  formula = y ~ x,
  parse = TRUE,
  label.x = "right",
  label.y = "top",
  size = 4
) +
scale_y_continuous(
  labels = scales::label_number(
    scale = 1e-6,
    suffix = "M"
  ),
  limits = c(-4e6, 5e6), 
  breaks = seq(-2e6, 3e6, by = 1e6) 
) +
scale_x_continuous(
  labels = scales::label_number(big.mark = ",")
) +
geom_text_repel(
  aes(label = year),
  size = 3,
  max.overlaps = Inf,
  box.padding = 0.4,
  point.padding = 0.2,
  segment.color = "gray60"
) +
theme_minimal() +
theme(
  plot.title    = element_text(face = "bold", size = 12), 
  plot.subtitle = element_text(size = 9, color = "gray30"),
  axis.title    = element_text(face = "bold", size = 10),
  panel.grid.minor = element_blank(),
  axis.text.y   = element_blank()
) +
labs(    
  title = "Delayed Forced Displacement and Economic Decline",
  subtitle = "UNHCR persons of concern of Venezuelan origin, 2009-2025",
  x = "GDP Growth (Annual %) with Two-Year Lag",
  y = NULL
)

# Plotting a side-by-side comparison of the concurrent and delayed regressions
economic_decline_plot <- p1 + p2 +
  plot_annotation(
    title = "Forced Displacement and Economic Decline",
    subtitle = "Comparing immediate year-over-year changes against a 2-year lag window",
    caption = "Sources: World Bank Development Indicators, UNHCR Refugee Data Finder. Author's calculations.",
    theme = theme(
      plot.title    = element_text(face = "bold", size = 15, hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray20", margin = margin(b = 10)),
      plot.caption  = element_text(size = 8, color = "gray40", hjust = 0)
    )
  )

ggsave(
  filename = "figures/economic_displacement_patchwork.png",
  plot = economic_decline_plot,
  width = 12,
  height = 6,
  dpi = 300
)

#------------------------------------------------------------------------------
# Fourth visual: cumulative economic loss relative to pre-collapse GDP
# per capita baseline
#------------------------------------------------------------------------------
# Define baseline (2013) GDP per capita
baseline_2013 <- venezuela_clean %>%
  filter(year == 2013) %>%
    pull(gdp_per_capita)

# Gather data
venezuela_indexed <- venezuela_clean %>%
  mutate(
    # Set 2013 as baseline index = 100
    gdp_index = (gdp_per_capita / baseline_2013) * 100,
    # Cumulative percentage loss relative to 2013 peak
    cum_loss_pct = ((gdp_per_capita - baseline_2013) / baseline_2013) * 100
  )

cumulative_loss_plot <- ggplot(
  venezuela_indexed,
  aes(
    x = year,
    y = gdp_index
  )
) +
geom_hline(yintercept = 100, linetype = "dashed", color = "gray40", linewidth = 0.8) +
geom_ribbon(aes(ymin = gdp_index, ymax = 100), fill = "#bce784", alpha = 0.25) +
geom_line(color = "#5dd39e", linewidth = 1.2) +
geom_point(color = "#5dd39e", size = 2.5) +
annotate(
  "text", x = 2013.5, y = 104, label = "Pre-Collapse Peak (2013 = 100)", 
  hjust = 0, size = 3.5, fontface = "italic", color = "gray30"
) +
scale_y_continuous(
  labels = function(x) paste0(x, "%"), limits = c(0, 110)
) +
scale_x_continuous(breaks = 2006:2025) +
plot_theme +
theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
) +
labs(
  title = "Cumulative Loss in GDP Per Capita",
  subtitle = "Venezuela's GDP per capita relative to pre-collapse baseline (2013 = 100), 2006-2025",
  x = "Year",
  y = "GDP Per Capita Index (2013 = 100)",
  caption = "Source: World Bank Development Indicators. Author's calculations."
)

ggsave(
  filename = "figures/cumulative_loss.png",
  width = 12,
  height = 6,
  dpi = 300,
  plot = cumulative_loss_plot
)
