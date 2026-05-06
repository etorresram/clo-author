# ==============================================================================
# 09_estimate_main_did.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 9 (main DiD estimation)
#
# Estimates the primary DiD specification of the methodology (eq:did_main):
#
#   Y_{ot} = tau * (beta_o * Post_t) + alpha_o + alpha_t + eps_{ot}
#
# at the (CIUO-08-4d, year-quarter) cell level for Lima Metropolitana.
#
# Outcomes (in order of importance):
#   log_employment   log of expanded employment in the cell  (extensive margin)
#   mean_log_wage    weighted mean of log hourly wage         (price)
#   mean_hours       weighted mean of weekly hours            (intensive margin)
#
# Two specifications:
#   1. Continuous TWFE via fixest::feols (primary)
#      - Cluster-robust SEs at CIUO-08-4d (Abadie-Athey-Imbens-Wooldridge 2023)
#      - Cell weights = employment (Solon-Haider-Wooldridge 2015)
#      - Reports unweighted as a robustness column
#
#   2. Binary-cutoff DiD as triangulation
#      - Treated = beta_o > median (employment-weighted, computed in 2021)
#      - Same FE structure
#      - This is the spec used by Hartley 2024, Hui 2024, Liu 2025
#
# Output:
#   data/cleaned/peru/main_did_results.rds  (named list with coefficients,
#                                             SEs, model objects)
# ==============================================================================

library(here)
library(data.table)
library(fixest)

out_dir <- here("data", "cleaned", "peru")
cells   <- readRDS(file.path(out_dir, "cells_ciuo_quarter.rds"))

cat(sprintf("Cell panel: %d rows | %d CIUO codes | %d quarters\n",
            nrow(cells), uniqueN(cells$code_ciuo), uniqueN(cells$t_index)))

# --- Construct outcomes -------------------------------------------------------
cells[, log_employment := log(employment)]

# Verify outcomes
cat("\nOutcome summaries:\n")
print(cells[, .(
  log_emp_mean   = mean(log_employment),
  log_emp_sd     = sd(log_employment),
  hours_mean     = mean(mean_hours),
  hours_sd       = sd(mean_hours),
  log_wage_mean  = mean(mean_log_wage),
  log_wage_sd    = sd(mean_log_wage)
)])

# --- Cluster-weighted median for binary cutoff (in 2021, pre-shock) ----------
# Pooled across 2021 quarters, weighted by employment.
beta_2021 <- cells[year == 2021]
beta_med <- weighted.mean(beta_2021$beta, w = beta_2021$employment)  # placeholder
# Actually need a proper weighted median:
weighted_median <- function(x, w) {
  ord <- order(x); x <- x[ord]; w <- w[ord]
  cw <- cumsum(w) / sum(w)
  x[which.max(cw >= 0.5)]
}
beta_p50 <- weighted_median(beta_2021$beta, beta_2021$employment)
cells[, treated_bin := as.integer(beta > beta_p50)]
cat(sprintf("\nEmployment-weighted median beta (2021):  %.3f\n", beta_p50))
cat(sprintf("Cells with treated_bin = 1: %d (%.1f%%)\n",
            sum(cells$treated_bin), 100 * mean(cells$treated_bin)))

# --- Specification 1: Continuous TWFE ----------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("SPECIFICATION 1: Continuous TWFE (primary)\n")
cat(strrep("=", 78), "\n", sep = "")

run_twfe_continuous <- function(outcome, weighted = TRUE) {
  fml <- as.formula(sprintf("%s ~ I(beta * post) | code_ciuo + t_index", outcome))
  if (weighted) {
    feols(fml, data = cells, weights = ~employment,
          cluster = ~code_ciuo, notes = FALSE)
  } else {
    feols(fml, data = cells, cluster = ~code_ciuo, notes = FALSE)
  }
}

twfe_w <- list(
  log_employment = run_twfe_continuous("log_employment", weighted = TRUE),
  mean_log_wage  = run_twfe_continuous("mean_log_wage",  weighted = TRUE),
  mean_hours     = run_twfe_continuous("mean_hours",     weighted = TRUE)
)
twfe_uw <- list(
  log_employment = run_twfe_continuous("log_employment", weighted = FALSE),
  mean_log_wage  = run_twfe_continuous("mean_log_wage",  weighted = FALSE),
  mean_hours     = run_twfe_continuous("mean_hours",     weighted = FALSE)
)

cat("\nWEIGHTED (employment) — primary:\n")
etable(twfe_w, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

cat("\nUNWEIGHTED (robustness):\n")
etable(twfe_uw, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

# --- Specification 2: Binary cutoff at median ---------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("SPECIFICATION 2: Binary cutoff at employment-weighted 2021 median\n")
cat(strrep("=", 78), "\n", sep = "")

run_twfe_binary <- function(outcome, weighted = TRUE) {
  fml <- as.formula(sprintf("%s ~ I(treated_bin * post) | code_ciuo + t_index",
                            outcome))
  if (weighted) {
    feols(fml, data = cells, weights = ~employment,
          cluster = ~code_ciuo, notes = FALSE)
  } else {
    feols(fml, data = cells, cluster = ~code_ciuo, notes = FALSE)
  }
}

bin_w <- list(
  log_employment = run_twfe_binary("log_employment", weighted = TRUE),
  mean_log_wage  = run_twfe_binary("mean_log_wage",  weighted = TRUE),
  mean_hours     = run_twfe_binary("mean_hours",     weighted = TRUE)
)

cat("\nBINARY CUTOFF — weighted (employment):\n")
etable(bin_w, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

# --- Headline summary table --------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("HEADLINE: tau_Peru point estimates (continuous, weighted)\n")
cat(strrep("=", 78), "\n", sep = "")

extract_tau <- function(mod) {
  ct <- summary(mod)$coeftable
  list(estimate = ct[1, "Estimate"],
       std_error = ct[1, "Std. Error"],
       t_stat    = ct[1, "t value"],
       p_value   = ct[1, "Pr(>|t|)"])
}

mk_row <- function(name, mod) {
  e <- extract_tau(mod)
  data.table(outcome = name,
             estimate = e$estimate, std_error = e$std_error,
             t_stat = e$t_stat, p_value = e$p_value)
}

headline <- rbindlist(list(
  mk_row("log_employment", twfe_w$log_employment),
  mk_row("mean_log_wage",  twfe_w$mean_log_wage),
  mk_row("mean_hours",     twfe_w$mean_hours)
))
print(headline)

# --- Save ---------------------------------------------------------------------
results <- list(
  twfe_continuous_weighted   = twfe_w,
  twfe_continuous_unweighted = twfe_uw,
  twfe_binary_weighted       = bin_w,
  beta_p50_2021              = beta_p50,
  headline                   = headline
)
saveRDS(results, file.path(out_dir, "main_did_results.rds"))

cat(sprintf("\n[DONE] Results saved: %s\n",
            file.path(out_dir, "main_did_results.rds")))
