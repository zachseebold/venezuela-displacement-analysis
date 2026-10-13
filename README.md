# Temporal Borderlands: How Venezuelan Households Bridged Crisis and Displacement

Inspired by my internship with the International Rescue Committee's Assistance for Migrants Program, this project explores the temporal delay between macroeconomic collapse and forced displacement in Venezuela from 2006 to 2025 using UNHCR Refugee Data Finder statistics and World Bank Development Indicators in an ordinary least squares regression across dynamic lag horizons. It explores lagged associations between economic conditions and displacement patterns without making causal claims.

<img width="3600" height="1800" alt="economic_displacement_patchwork" src="https://github.com/user-attachments/assets/3b05308f-379d-440e-9e11-b1c6859bdb53" />

## **Key Findings**

* **The 2-Year Lag:** Concurrent GDP growth percentage accounts for only 14.4% of the variance in net annual change in displacement stock. Applying a two-year lag increases explanatory power to **65.5%**.
* **Anticipatory Policy Window:** An 18-to-24-month delay exists between macroeconomic shocks and peak displacement, providing humanitarian organizations and governments of host nations an early-warning window to prepare aid.
* **Legal Protection Shift:** UNHCR data highlights a structural transition away from formal refugee and asylum status toward temporary protection frameworks.

------------------------------------------------------------------------------

## **Repository Pipeline**

The analysis pipeline consists of four scripts:

* `01_clean_worldbank.R`: Cleans World Bank Development Indicators data (annual GDP growth, GDP per capita).
* `02_clean_unhcr.R`: Cleans UNHCR Refugee Data Finder data across legal status categories (refugees, asylum seekers, other protection, others of concern).
* `03_merge_visualize.R`: Merges datasets, executes dynamic OLS lag models, and generates visualizations.
* `04_clean_visualize_livelihood.R`: Cleans Premise Mobile open-source survey data, executes a pooled OLS and LPM with fixed effects, generates visualization.

------------------------------------------------------------------------------

## **Tech Stack & Dependencies**

This project is built in **R** using the following packages:

* `tidyverse`, `fixest`, `dotwhisker` (Data manipulation and visualization)
* `patchwork` (Visualization layout)
* `ggpmisc`, `ggrepel` (Plot and regression labeling)
* `janitor` (Data cleaning)

------------------------------------------------------------------------------

## **Data Sources**
* **World Bank Development Indicators:** Annual GDP growth and GDP per capita.
* **UNHCR Refugee Data Finder:** Population totals for individuals of concern of Venezuelan origin.
* **Premise Mobile open-source survey data** Qualitative data submitted by Venezuelans regarding food insecurity, livelihood, and demographics.

------------------------------------------------------------------------------

## **Reproduction**

### Prerequisites
* R (tested on version 2026.07.1-147)
* Packages: `tidyverse`, `patchwork`, `ggpmisc`, `ggrepel`, `janitor`, `fixest`, `dotwhisker`

### Execution
1. Clone this repository (inside terminal):
   ```bash
   git clone https://github.com/zachseebold/venezuela-displacement-analysis.git
   cd venezuela-displacement-analysis
   ```
   
2. Install dependencies (inside console):
   ```r
   install.packages(c("tidyverse", "patchwork", "ggpmisc", "ggrepel", "janitor", "fixest", "dotwhisker"))
   ```
   
3. Execution pipeline (inside terminal):
   ```bash
   Rscript 01_clean_worldbank.R
   Rscript 02_clean_unhcr.R
   Rscript 03_merge_visualize.R
   Rscript 04_clean_visualize_livelihood.R
   ```
