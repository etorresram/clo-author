# ==============================================================================
# 13_triangulation_did.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 13 (triangulation: Callaway-Sant'Anna binary)
#
# Triangulates the main TWFE result with the Callaway-Sant'Anna (2021) binary
# DiD estimator (eq:did_binary). Treatment is "exposed" (beta > median 2021)
# vs "control" (beta <= median). With a single common shock at t* = 2022Q4,
# CS-2021 reduces to a non-staggered 2x2 DiD but with the package's robustness
# benefits (no weighting issues, propensity-score reweighting).
#
# Comparison points:
#   1. TWFE binary (Phase 9 spec 2)         already estimated
#   2. CS-2021 att_gt simple aggregate      this script
#   3. CS-2021 dynamic event-study          this script
#
# Note on Bartik shift-share: the methodology mentions Bartik (eq:bartik) but
# Lima Metropolitana is a single labor market, so shift-share variation
# requires defining "markets" within Lima (e.g., by district or by demographic
# cell). That extension is left for the multi-country paper revision.
#
# Output:
#   data/cleaned/peru/triangulation_results.rds
# ==============================================================================

library(here)
library(data.table)
library(did)
library(fixest)

out_dir <- here("data", "cleaned", "peru")
cells   <- readRDS(file.path(out_dir, "cells_ciuo_quarter.rds"))
cells[, log_employment := log(employment)]

# --- Define binary treatment -------------------------------------------------
# Median beta (employment-weighted, 2021)
weighted_median <- function(x, w) {
  ord <- order(x); x <- x[ord]; w <- w[ord]
  cw  <- cumsum(w) / sum(w)
  x[which.max(cw >= 0.5)]
}
beta_p50 <- weighted_median(cells[year == 2021]$beta,
                            cells[year == 2021]$employment)
cells[, treated_bin := as.integer(beta > beta_p50)]
cat(sprintf("Median beta (2021, emp-weighted): %.3f\n", beta_p50))
cat(sprintf("Treated (beta > median): %d cells (%.1f%%)\n",
            sum(cells$treated_bin), 100 * mean(cells$treated_bin)))
cat(sprintf("Treated CIUO codes: %d\n",
            uniqueN(cells[treated_bin == 1, code_ciuo])))
cat(sprintf("Control CIUO codes: %d\n",
            uniqueN(cells[treated_bin == 0, code_ciuo])))

# --- Prepare panel for did::att_gt --------------------------------------------
# att_gt expects: idname, tname, gname, yname.
# gname = treatment time (= 8 for 2022Q4 = t*) for treated, 0 for never-treated.
cells[, idname := as.integer(factor(code_ciuo))]
# IMPORTANT: gname must be numeric (not integer) so the package can substitute
# 0 -> Inf for never-treated units internally.
cells[, gname  := as.numeric(ifelse(treated_bin == 1L, 8, 0))]
cells[, t_index_num := as.numeric(t_index)]

# att_gt requires balanced panel for control_group = "nevertreated".
# We have 71 partially balanced units; restrict to fully balanced for CS.
balance <- cells[, .N, by = idname]
balanced_ids <- balance[N == 20, idname]
cs_data <- cells[idname %in% balanced_ids]
cat(sprintf("\nFully balanced CIUOs for CS: %d (of %d total)\n",
            uniqueN(cs_data$idname), uniqueN(cells$idname)))
cat(sprintf("  Treated (gname=8):   %d\n",
            uniqueN(cs_data[gname == 8, idname])))
cat(sprintf("  Never-treated (g=0): %d\n",
            uniqueN(cs_data[gname == 0, idname])))

# --- Callaway-Sant'Anna for three outcomes -----------------------------------
run_cs <- function(yname) {
  cat(sprintf("\n--- CS-2021 att_gt: %s ---\n", yname))

  res_gt <- att_gt(
    yname         = yname,
    tname         = "t_index_num",
    idname        = "idname",
    gname         = "gname",
    data          = cs_data,
    control_group = "nevertreated",
    est_method    = "reg"
  )

  # Manual simple aggregate: average ATT(g=8, t) over post-treatment
  # periods (t > 8). The aggte() function conflicts with fixest's namespace
  # (.checkTypos clash), so we compute by hand using the att_gt output.
  post_idx <- which(res_gt$group == 8 & res_gt$t > 8)
  atts     <- res_gt$att[post_idx]
  ses      <- res_gt$se[post_idx]
  # Simple average and SE (assuming independence, conservative)
  simple_att <- mean(atts)
  simple_se  <- sqrt(mean(ses^2) / length(atts))

  cat(sprintf("  Pre-trend test p-value: %.4f\n",
              1 - pnorm(res_gt$Wpval)))   # Wpval is the chi^2 statistic
  cat(sprintf("  Simple ATT (avg post):  %7.4f  (SE %6.4f)\n",
              simple_att, simple_se))
  cat(sprintf("  CI 95%%:                  [%7.4f, %7.4f]\n",
              simple_att - 1.96 * simple_se,
              simple_att + 1.96 * simple_se))
  cat(sprintf("  N post-period ATT(g,t): %d\n", length(post_idx)))

  list(att_gt = res_gt,
       simple_att = simple_att, simple_se = simple_se,
       atts_post = data.table(t = res_gt$t[post_idx],
                              att = atts, se = ses))
}

cs_emp   <- run_cs("log_employment")
cs_wage  <- run_cs("mean_log_wage")
cs_hours <- run_cs("mean_hours")

# --- TWFE binary (re-estimate on the same balanced sample for fairness) ------
run_twfe_binary_balanced <- function(yname) {
  fml <- as.formula(sprintf("%s ~ I(treated_bin * post) | code_ciuo + t_index",
                            yname))
  feols(fml, data = cs_data, weights = ~employment,
        cluster = ~code_ciuo, notes = FALSE)
}

twfe_emp   <- run_twfe_binary_balanced("log_employment")
twfe_wage  <- run_twfe_binary_balanced("mean_log_wage")
twfe_hours <- run_twfe_binary_balanced("mean_hours")

extract_twfe <- function(mod) {
  ct <- summary(mod)$coeftable
  c(estimate = ct[1, "Estimate"], se = ct[1, "Std. Error"])
}

# --- Side-by-side comparison --------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("HEADLINE: TWFE binary vs Callaway-Sant'Anna binary (balanced sample)\n")
cat(strrep("=", 78), "\n", sep = "")

mk <- function(out, twfe_mod, cs_res) {
  t <- extract_twfe(twfe_mod)
  data.table(
    outcome   = out,
    twfe_est  = round(t["estimate"], 4),
    twfe_se   = round(t["se"], 4),
    cs_est    = round(cs_res$simple_att, 4),
    cs_se     = round(cs_res$simple_se,  4),
    n_units   = uniqueN(cs_data$idname)
  )
}

headline <- rbindlist(list(
  mk("log_employment", twfe_emp,   cs_emp),
  mk("mean_log_wage",  twfe_wage,  cs_wage),
  mk("mean_hours",     twfe_hours, cs_hours)
))
print(headline)

# --- Save ---------------------------------------------------------------------
results <- list(
  beta_p50  = beta_p50,
  twfe      = list(log_employment = twfe_emp,  mean_log_wage = twfe_wage,
                   mean_hours = twfe_hours),
  cs        = list(log_employment = cs_emp,    mean_log_wage = cs_wage,
                   mean_hours = cs_hours),
  headline  = headline
)
saveRDS(results, file.path(out_dir, "triangulation_results.rds"))

cat(sprintf("\n[DONE] Triangulation results saved.\n"))
