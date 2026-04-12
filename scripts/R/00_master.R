# ==============================================================================
# Master Script — Gen AI & Labor Markets in LAC
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Author:  Eric Torres (PUCP)
# Date:    2026-04-11
#
# This script runs the full analysis pipeline in order.
# Each numbered script is self-contained and can also run independently.
# ==============================================================================

# --- Packages -----------------------------------------------------------------
library(here)         # Project-relative paths
library(data.table)   # Fast data manipulation
library(fixest)       # TWFE, Sun-Abraham, clustered SEs
library(did)          # Callaway & Sant'Anna (2021), continuous treatment
library(modelsummary) # Publication-quality tables
library(ggplot2)      # Figures
library(rifreg)       # RIF / unconditional quantile regressions (Paper 2)
library(grf)          # Causal forests for heterogeneity
library(sensemakr)    # Oster-style sensitivity analysis
library(haven)        # Read Stata/SPSS survey files
library(survey)       # Survey-weighted estimation
library(readxl)       # Read O*NET Excel files

# --- Seed (for any stochastic element) ----------------------------------------
set.seed(20260411)

# --- Pipeline -----------------------------------------------------------------

# Step 1: Download / document survey data sources
# source(here("scripts", "R", "01_download_surveys.R"))

# Step 2: Harmonize employment surveys across 5 countries
# source(here("scripts", "R", "02_harmonize_surveys.R"))

# Step 3: Build exposure mapping (O*NET → SOC → ISCO-08)
# source(here("scripts", "R", "03_build_exposure.R"))

# Step 4: Merge exposure scores to survey microdata
# source(here("scripts", "R", "04_merge_exposure.R"))

# Step 5: Descriptive statistics and balance tables
# source(here("scripts", "R", "05_descriptive.R"))

# Step 6: Main DiD estimation (Paper 1)
# source(here("scripts", "R", "06_did_main.R"))

# Step 7: Event study / dynamic treatment effects
# source(here("scripts", "R", "07_event_study.R"))

# Step 8: Robustness (placebo, alt thresholds, alt estimators)
# source(here("scripts", "R", "08_robustness.R"))

# Step 9: Heterogeneity (gender, age, education, formal/informal, sector)
# source(here("scripts", "R", "09_heterogeneity.R"))

# Step 10: Distributional analysis — RIF regressions, quantile effects (Paper 2)
# source(here("scripts", "R", "10_distributional.R"))

# Step 11: Publication figures
# source(here("scripts", "R", "11_figures.R"))

cat("Pipeline complete.\n")
