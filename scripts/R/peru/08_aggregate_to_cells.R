# ==============================================================================
# 08_aggregate_to_cells.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 8 (collapse worker-level panel to cells)
#
# Builds the (CIUO-08-4d, year-quarter) panel that the DiD estimator consumes.
# Within each cell, outcomes are weighted means using the harmonized survey
# weight (= original sampling weight x posterior imputation probability for
# the pre period; = original sampling weight for the post period).
#
# Outcomes:
#   employment       sum of harmonized weights     (level, in workers)
#   log_employment   log of the above              (proportional response)
#   mean_hours       weighted mean of weekly hours
#   mean_log_wage    weighted mean of log hourly wage (real, valid wages only)
#   share_formal     weighted share with seguro1 in {1,3}
#
# Treatment:
#   beta, alpha, zeta, gamma     constant per CIUO (Eloundou exposures)
#   post                          1 iff (year, quarter) >= (2023, 1)
#   yearqtr                       continuous quarter index for plots
#
# Cell filter: drop cells with n_workers < 10 (data.tex line 79; standard).
#
# Output:
#   data/cleaned/peru/cells_ciuo_quarter.rds
# ==============================================================================

library(here)
library(data.table)

out_dir <- here("data", "cleaned", "peru")

panel <- readRDS(file.path(out_dir, "epen_with_exposure.rds"))

cat(sprintf("Worker-level rows: %d\n", nrow(panel)))
cat(sprintf("Distinct CIUO codes: %d\n", uniqueN(panel$code_ciuo)))
cat(sprintf("Distinct (year, quarter): %d\n",
            uniqueN(panel[, .(year, quarter)])))

# --- Drop rows without valid exposure (cannot enter regression) --------------
panel_valid <- panel[!is.na(beta)]
cat(sprintf("\nRows with valid beta: %d (%.2f%%)\n",
            nrow(panel_valid), 100 * nrow(panel_valid) / nrow(panel)))

# --- Aggregate to cells -------------------------------------------------------
cells <- panel_valid[, .(
  n_workers      = .N,
  employment     = sum(weight_harmonized, na.rm = TRUE),
  mean_hours     = weighted.mean(hours,         w = weight_harmonized,
                                 na.rm = TRUE),
  mean_log_wage  = weighted.mean(log_wage_hour, w = weight_harmonized,
                                 na.rm = TRUE),
  share_formal   = weighted.mean(is_formal,     w = weight_harmonized,
                                 na.rm = TRUE),
  beta           = first(beta),
  alpha          = first(alpha),
  zeta           = first(zeta),
  gamma          = first(gamma)
), by = .(code_ciuo, year, quarter)]

cat(sprintf("\nCells before filter: %d\n", nrow(cells)))

# --- Cell filter: minimum sample size ----------------------------------------
MIN_N <- 10L
cells_dropped <- cells[n_workers < MIN_N]
cells_kept    <- cells[n_workers >= MIN_N]

cat(sprintf("Cells dropped (n_workers < %d): %d\n", MIN_N, nrow(cells_dropped)))
cat(sprintf("Cells kept:                       %d\n", nrow(cells_kept)))
cat(sprintf("Distinct CIUO in kept cells:      %d\n",
            uniqueN(cells_kept$code_ciuo)))

# --- Add time and treatment variables ----------------------------------------
cells_kept[, yearqtr := year + (quarter - 1) / 4]
cells_kept[, t_index := as.integer((year - 2021) * 4 + quarter)]   # 1..20
cells_kept[, post    := as.integer(yearqtr >= 2023)]
cells_kept[, t_star  := 9L]   # 2022Q4 = quarter 8 (1-indexed); treatment from t=9

# --- Sanity: balanced panel? --------------------------------------------------
cat("\nPanel balance check (before second filter):\n")
balance <- cells_kept[, .(n_quarters = .N,
                          n_pre  = sum(yearqtr <  2023),
                          n_post = sum(yearqtr >= 2023)), by = code_ciuo]
cat(sprintf("  CIUO codes total: %d\n", nrow(balance)))
cat(sprintf("  CIUO with all 20 quarters:        %d\n", sum(balance$n_quarters == 20)))
cat(sprintf("  CIUO with >=1 pre AND >=1 post:   %d\n",
            sum(balance$n_pre >= 1 & balance$n_post >= 1)))
cat(sprintf("  CIUO with only pre (no post):     %d\n",
            sum(balance$n_pre >= 1 & balance$n_post == 0)))
cat(sprintf("  CIUO with only post (no pre):     %d\n",
            sum(balance$n_pre == 0 & balance$n_post >= 1)))

# --- Second filter: keep codes with at least one pre AND one post quarter ----
codes_keep <- balance[n_pre >= 1 & n_post >= 1, code_ciuo]
cells_kept <- cells_kept[code_ciuo %in% codes_keep]
cat(sprintf("\nAfter balance filter (pre>=1, post>=1):\n"))
cat(sprintf("  Cells kept: %d  | CIUO codes: %d\n",
            nrow(cells_kept), uniqueN(cells_kept$code_ciuo)))

# --- Sanity: no NA in essential columns ---------------------------------------
nas <- sapply(cells_kept[, .(employment, mean_hours, mean_log_wage,
                             share_formal, beta)], function(x) sum(is.na(x)))
cat("\nNA counts in essential columns:\n")
print(nas)

# --- Quarterly totals (sanity vs panel) --------------------------------------
cat("\nQuarterly totals from cell panel:\n")
qtot <- cells_kept[, .(
  n_cells        = .N,
  total_workers  = sum(n_workers),
  total_employed = sum(employment)
), by = .(year, quarter)][order(year, quarter)]
print(qtot)

# --- Save ---------------------------------------------------------------------
saveRDS(cells_kept, file.path(out_dir, "cells_ciuo_quarter.rds"))

cat(sprintf("\n[DONE] Cell panel saved: %s\n",
            file.path(out_dir, "cells_ciuo_quarter.rds")))
cat(sprintf("       Rows: %d  | CIUO codes: %d  | Quarters: %d\n",
            nrow(cells_kept), uniqueN(cells_kept$code_ciuo),
            uniqueN(cells_kept$t_index)))
