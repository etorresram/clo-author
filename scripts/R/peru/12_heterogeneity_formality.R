# ==============================================================================
# 12_heterogeneity_formality.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 12 (heterogeneity by baseline formality)
#
# Tests whether the (null) main effects mask formal-informal heterogeneity,
# the central preregistered margin of the paper. Two complementary designs:
#
#   Design 1 — Interaction within a single regression (eq:formality_interaction)
#     Y_ot = tau_F * (beta * Post * F_o^2021)
#          + tau_I * (beta * Post * (1 - F_o^2021))
#          + alpha_o + alpha_t + eps
#     where F_o^2021 is the employment-weighted share of formal workers in
#     CIUO o averaged over the four 2021 quarters (occupation-level baseline,
#     fixed in time, predetermined w.r.t. ChatGPT).
#
#   Design 2 — Sub-sample DiD by baseline formality
#     Split CIUOs into high-formality vs low-formality at the median F_o^2021
#     (employment-weighted). Estimate the main DiD on each subset.
#     Easier to interpret, useful for direct narrative reporting.
#
# Outputs:
#   data/cleaned/peru/heterogeneity_formality.rds
# ==============================================================================

library(here)
library(data.table)
library(fixest)

out_dir <- here("data", "cleaned", "peru")
cells   <- readRDS(file.path(out_dir, "cells_ciuo_quarter.rds"))
cells[, log_employment := log(employment)]

# --- Step 1: compute F_o^2021 ------------------------------------------------
# Employment-weighted average of the cell-level share_formal across 2021 quarters.
F_o <- cells[year == 2021, .(
  F_o_2021 = weighted.mean(share_formal, w = employment, na.rm = TRUE)
), by = code_ciuo]

cat(sprintf("CIUOs with F_o^2021: %d / %d\n",
            nrow(F_o), uniqueN(cells$code_ciuo)))
cat(sprintf("F_o^2021 distribution: min=%.3f  p25=%.3f  med=%.3f  p75=%.3f  max=%.3f\n",
            min(F_o$F_o_2021),    quantile(F_o$F_o_2021, 0.25),
            median(F_o$F_o_2021), quantile(F_o$F_o_2021, 0.75),
            max(F_o$F_o_2021)))

# Merge back; drop CIUOs without 2021 (rare given balance filter)
cells <- merge(cells, F_o, by = "code_ciuo")
cat(sprintf("Cells with F_o^2021: %d (%.1f%%)\n",
            nrow(cells), 100 * nrow(cells) / 2139))

# --- Design 1: Interaction within a single regression -----------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("DESIGN 1 — Interaction with F_o^2021 (eq:formality_interaction)\n")
cat(strrep("=", 78), "\n", sep = "")

cells[, x_F := beta * post * F_o_2021]
cells[, x_I := beta * post * (1 - F_o_2021)]

run_interaction <- function(outcome) {
  fml <- as.formula(sprintf("%s ~ x_F + x_I | code_ciuo + t_index", outcome))
  feols(fml, data = cells, weights = ~employment,
        cluster = ~code_ciuo, notes = FALSE)
}

int_emp   <- run_interaction("log_employment")
int_wage  <- run_interaction("mean_log_wage")
int_hours <- run_interaction("mean_hours")

etable(list("log empleo" = int_emp,
            "log salario" = int_wage,
            "horas" = int_hours),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4,
       dict = c(x_F = "beta x Post x F_o (formal channel)",
                x_I = "beta x Post x (1-F_o) (informal channel)"))

# Test of equality tau_F = tau_I within each outcome
# Manual Wald test: (b1 - b2)^2 / Var(b1 - b2) ~ chi^2(1)
test_equality <- function(mod) {
  b  <- coef(mod)
  V  <- vcov(mod)
  d  <- b["x_F"] - b["x_I"]
  vd <- V["x_F", "x_F"] + V["x_I", "x_I"] - 2 * V["x_F", "x_I"]
  z  <- d / sqrt(vd)
  list(diff = d, se = sqrt(vd), z = z, p = 2 * pnorm(-abs(z)))
}

cat("\nTest H0: tau_F = tau_I (manual Wald using normal approximation):\n")
for (lab in c("log_employment", "mean_log_wage", "mean_hours")) {
  mod <- get(c("log_employment" = "int_emp",
               "mean_log_wage"  = "int_wage",
               "mean_hours"     = "int_hours")[lab])
  t <- test_equality(mod)
  cat(sprintf("  %-20s  diff = %7.4f (SE %5.4f)  z = %5.2f  p = %.4f\n",
              lab, t$diff, t$se, t$z, t$p))
}

# --- Design 2: Sub-sample DiD by baseline formality -------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("DESIGN 2 — Subsample DiD: high-F vs low-F CIUOs\n")
cat(strrep("=", 78), "\n", sep = "")

# Median F_o^2021 weighted by 2021 employment
f_2021_emp <- cells[year == 2021, .(F_o_2021 = first(F_o_2021),
                                    emp = sum(employment)),
                    by = code_ciuo]
weighted_median <- function(x, w) {
  ord <- order(x); x <- x[ord]; w <- w[ord]
  cw  <- cumsum(w) / sum(w)
  x[which.max(cw >= 0.5)]
}
F_med <- weighted_median(f_2021_emp$F_o_2021, f_2021_emp$emp)
cat(sprintf("\nMedian F_o^2021 (employment-weighted): %.3f\n", F_med))

cells[, high_formal := as.integer(F_o_2021 > F_med)]
cat("Cells per stratum:\n")
print(cells[, .N, by = high_formal])

run_subsample <- function(stratum_label, subset_expr) {
  sub <- cells[eval(parse(text = subset_expr))]
  list(
    log_employment = feols(log_employment ~ I(beta * post) | code_ciuo + t_index,
                           data = sub, weights = ~employment,
                           cluster = ~code_ciuo, notes = FALSE),
    mean_log_wage  = feols(mean_log_wage ~ I(beta * post) | code_ciuo + t_index,
                           data = sub, weights = ~employment,
                           cluster = ~code_ciuo, notes = FALSE),
    mean_hours     = feols(mean_hours ~ I(beta * post) | code_ciuo + t_index,
                           data = sub, weights = ~employment,
                           cluster = ~code_ciuo, notes = FALSE)
  )
}

high_F <- run_subsample("high_F", "high_formal == 1")
low_F  <- run_subsample("low_F",  "high_formal == 0")

cat("\nHIGH-FORMALITY CIUOs (F_o^2021 > median):\n")
etable(high_F, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

cat("\nLOW-FORMALITY CIUOs (F_o^2021 <= median):\n")
etable(low_F, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

# --- Headline summary table --------------------------------------------------
extract <- function(mod) {
  ct <- summary(mod)$coeftable
  c(estimate = ct[1, "Estimate"], se = ct[1, "Std. Error"],
    p = ct[1, "Pr(>|t|)"])
}

cat("\n", strrep("=", 78), "\n", sep = "")
cat("HEADLINE — tau by formality stratum\n")
cat(strrep("=", 78), "\n", sep = "")

headline <- rbindlist(list(
  data.table(outcome = "log_employment", spec = "high-F",
             t(extract(high_F$log_employment))),
  data.table(outcome = "log_employment", spec = "low-F",
             t(extract(low_F$log_employment))),
  data.table(outcome = "mean_log_wage", spec = "high-F",
             t(extract(high_F$mean_log_wage))),
  data.table(outcome = "mean_log_wage", spec = "low-F",
             t(extract(low_F$mean_log_wage))),
  data.table(outcome = "mean_hours", spec = "high-F",
             t(extract(high_F$mean_hours))),
  data.table(outcome = "mean_hours", spec = "low-F",
             t(extract(low_F$mean_hours)))
))
print(headline)

# --- Save ---------------------------------------------------------------------
results <- list(
  F_o_2021 = F_o,
  F_med = F_med,
  interaction = list(log_employment = int_emp, mean_log_wage = int_wage,
                     mean_hours = int_hours),
  subsample_high = high_F,
  subsample_low  = low_F,
  headline = headline
)
saveRDS(results, file.path(out_dir, "heterogeneity_formality.rds"))

cat(sprintf("\n[DONE] Heterogeneity results saved.\n"))
