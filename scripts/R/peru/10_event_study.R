# ==============================================================================
# 10_event_study.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 10 (event study — pre-trends + dynamics)
#
# Estimates the dynamic event-study specification of the methodology
# (eq:event_study):
#
#   Y_{ot} = sum_{k != -1} theta_k * (beta_o * 1[t - t* = k]) + alpha_o + alpha_t + eps
#
# where t* = 2022Q4 (the buffer trimester, dropped from the main DiD per
# methodology). Reference period is k = -1 (2022Q3, last clean pre-shock).
#
# Window relative to t*:
#   Pre  : k in [-7, -2]   (2021Q1 .. 2022Q2)
#   Ref  : k = -1          (2022Q3)
#   Drop : k =  0          (2022Q4, buffer)
#   Post : k in [+1, +12]  (2023Q1 .. 2025Q4)
#
# Three outcomes (matching Phase 9):
#   log_employment, mean_log_wage, mean_hours
#
# Output:
#   data/cleaned/peru/event_study_results.rds        (named list of models)
#   paper/figures/peru/event_study_<outcome>.pdf     (one fig per outcome)
# ==============================================================================

library(here)
library(data.table)
library(fixest)
library(ggplot2)

out_dir   <- here("data", "cleaned", "peru")
fig_dir   <- here("paper", "figures", "peru")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cells <- readRDS(file.path(out_dir, "cells_ciuo_quarter.rds"))
cells[, log_employment := log(employment)]

# --- Define event-time relative to t* = 2022Q4 -------------------------------
# t_index in the panel: 1=2021Q1, 2=2021Q2, ..., 8=2022Q4, ..., 20=2025Q4
# Set t_rel so that t_rel = -1 corresponds to 2022Q3 (last pre-shock).
# That makes t_rel = 0 the buffer (2022Q4) and t_rel = 1 the first post.
cells[, t_rel := t_index - 8L]

# Drop buffer trimester from primary event study (per methodology)
es_data <- cells[t_rel != 0]
cat(sprintf("Cells used in event study (excluding buffer): %d\n", nrow(es_data)))
cat("Distribution of cells across event time:\n")
print(es_data[, .N, by = t_rel][order(t_rel)])

# --- Helper: estimate one event study ----------------------------------------
run_event_study <- function(outcome) {
  fml <- as.formula(sprintf(
    "%s ~ i(t_rel, beta, ref = -1) | code_ciuo + t_index", outcome))
  feols(fml, data = es_data, weights = ~employment,
        cluster = ~code_ciuo, notes = FALSE)
}

# --- Estimate three outcomes -------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("EVENT STUDY: three outcomes\n")
cat(strrep("=", 78), "\n", sep = "")

es_log_emp  <- run_event_study("log_employment")
es_log_wage <- run_event_study("mean_log_wage")
es_hours    <- run_event_study("mean_hours")

# --- Joint pre-trend test (Wald) ---------------------------------------------
test_pretrend <- function(mod) {
  # All coefficients with t_rel < -1 should be zero
  cn   <- names(coef(mod))
  pre  <- cn[grepl("^t_rel::-[2-9]:beta$|^t_rel::-1[0-9]+:beta$", cn)]
  if (length(pre) == 0) return(list(F = NA, p = NA, k = 0))
  w    <- wald(mod, pre, print = FALSE)
  list(F = w$stat, p = w$p, k = length(pre))
}

cat("\nJoint Wald test of pre-trends (H0: theta_k = 0 for all k <= -2):\n")
for (label in c("log_employment", "mean_log_wage", "mean_hours")) {
  mod <- get(c("log_employment" = "es_log_emp",
               "mean_log_wage"  = "es_log_wage",
               "mean_hours"     = "es_hours")[[label]])
  pt  <- test_pretrend(mod)
  cat(sprintf("  %-20s  F = %6.3f  on %d coefs  p = %.4f\n",
              label, pt$F, pt$k, pt$p))
}

# --- Tidy coefficients for plotting ------------------------------------------
tidy_es <- function(mod, outcome_name) {
  ct <- summary(mod)$coeftable
  d  <- as.data.table(ct, keep.rownames = "term")
  setnames(d, c("term", "estimate", "std_error", "t_stat", "p_value"))
  d[, k := as.integer(gsub("^t_rel::(-?\\d+):beta$", "\\1", term))]
  d  <- d[!is.na(k)]
  # Add reference period as zero
  ref <- data.table(term = "ref", estimate = 0, std_error = 0,
                    t_stat = NA, p_value = NA, k = -1L)
  d <- rbindlist(list(d, ref), use.names = TRUE, fill = TRUE)
  d[, ci_lo := estimate - 1.96 * std_error]
  d[, ci_hi := estimate + 1.96 * std_error]
  d[, outcome := outcome_name]
  setorder(d, k)
  d
}

td_emp   <- tidy_es(es_log_emp,  "log_employment")
td_wage  <- tidy_es(es_log_wage, "mean_log_wage")
td_hours <- tidy_es(es_hours,    "mean_hours")

cat("\n  log_employment coefficients (k, estimate, SE):\n")
print(td_emp[, .(k, estimate = round(estimate, 4),
                  std_error = round(std_error, 4))])

# --- Plot --------------------------------------------------------------------
make_es_plot <- function(td, outcome_label, fname) {
  p <- ggplot(td, aes(x = k, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "darkred") +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.3) +
    scale_x_continuous(breaks = seq(-7, 12, 2),
                       labels = seq(-7, 12, 2)) +
    labs(
      x = "Trimestres relativos a t* (2022Q4)",
      y = expression(theta[k] %*% beta * "  (efecto por unidad de exposición)"),
      title = paste("Event study —", outcome_label),
      subtitle = "Lima Metropolitana, EPEN. IC 95%, errores clusterizados en CIUO-08-4d.",
      caption = "Período de referencia: 2022Q3 (k = -1). Buffer 2022Q4 excluido."
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.minor = element_blank())

  ggsave(file.path(fig_dir, fname), p, width = 8, height = 4.5)
  invisible(p)
}

make_es_plot(td_emp,   "log empleo",     "event_study_log_employment.pdf")
make_es_plot(td_wage,  "log salario hora","event_study_mean_log_wage.pdf")
make_es_plot(td_hours, "horas semanales", "event_study_mean_hours.pdf")

# --- Save --------------------------------------------------------------------
results <- list(
  models = list(log_employment = es_log_emp,
                mean_log_wage  = es_log_wage,
                mean_hours     = es_hours),
  tidy   = list(log_employment = td_emp,
                mean_log_wage  = td_wage,
                mean_hours     = td_hours),
  pretrend_tests = list(
    log_employment = test_pretrend(es_log_emp),
    mean_log_wage  = test_pretrend(es_log_wage),
    mean_hours     = test_pretrend(es_hours)
  )
)
saveRDS(results, file.path(out_dir, "event_study_results.rds"))

cat(sprintf("\n[DONE] Event study results saved.\n"))
cat(sprintf("       Figures in: %s\n", fig_dir))
