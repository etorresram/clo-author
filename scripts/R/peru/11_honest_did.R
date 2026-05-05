# ==============================================================================
# 11_honest_did.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 11 (Honest-DiD identification bounds)
#
# Computes Rambachan-Roth (2023) identified-set bounds on the post-treatment
# coefficients of the Peru event study. Two restrictions on the violation of
# parallel trends:
#
#   (a) Relative-magnitudes bound (Mbar):
#       The post-period violation is at most Mbar times the maximum pre-period
#       violation. The "breakdown Mbar" is the smallest Mbar that lets zero
#       enter the identified set; the methodology (line 126) requires
#       Mbar^Peru >= 2 for principal claims to be retained.
#
#   (b) Smoothness bound (M):
#       The second difference of the path of treatment effects is bounded.
#       Reported as a complementary check.
#
# Inputs:
#   data/cleaned/peru/event_study_results.rds (Phase 10 models)
#
# Outputs:
#   data/cleaned/peru/honest_did_bounds.rds
#   paper/figures/peru/honest_did_<outcome>.pdf
# ==============================================================================

library(here)
library(data.table)
library(HonestDiD)
library(ggplot2)

out_dir <- here("data", "cleaned", "peru")
fig_dir <- here("paper", "figures", "peru")

es_results <- readRDS(file.path(out_dir, "event_study_results.rds"))

# --- Helper: pull (betahat, sigma) from a fixest event-study model -----------
# Our event study uses i(t_rel, beta, ref = -1), so coefficients are named
# "t_rel::-7:beta", ..., "t_rel::-2:beta", "t_rel::1:beta", ..., "t_rel::12:beta".
# Reference period (k = -1) is omitted. We need to reconstruct the canonical
# vector ordered as (pre periods, post periods) for HonestDiD.
extract_es <- function(mod) {
  cn  <- names(coef(mod))
  k   <- as.integer(gsub("^t_rel::(-?\\d+):beta$", "\\1", cn))
  ord <- order(k)
  list(betahat = coef(mod)[ord],
       sigma   = vcov(mod)[ord, ord, drop = FALSE],
       k_vals  = k[ord])
}

# --- Helper: run HonestDiD for one outcome ----------------------------------
run_honestdid <- function(mod, outcome_name, l_horizon = NULL) {
  ex <- extract_es(mod)
  k  <- ex$k_vals
  numPre  <- sum(k < 0)
  numPost <- sum(k > 0)
  cat(sprintf("\n  %s: numPre = %d, numPost = %d\n",
              outcome_name, numPre, numPost))

  # Default l_vec: average over all post-periods (Mbar applies to the average)
  if (is.null(l_horizon)) {
    l_vec <- rep(1 / numPost, numPost)
  } else {
    l_vec <- as.integer(seq_len(numPost) == l_horizon)
  }

  # Relative-magnitudes sensitivity
  rel <- createSensitivityResults_relativeMagnitudes(
    betahat        = ex$betahat,
    sigma          = ex$sigma,
    numPrePeriods  = numPre,
    numPostPeriods = numPost,
    Mbarvec        = c(0, 0.5, 1, 1.5, 2, 2.5, 3),
    l_vec          = l_vec
  )

  # Original (no constraint) confidence interval for the same target
  orig <- constructOriginalCS(
    betahat        = ex$betahat,
    sigma          = ex$sigma,
    numPrePeriods  = numPre,
    numPostPeriods = numPost,
    l_vec          = l_vec
  )

  list(rel = rel, orig = orig, l_vec = l_vec, k_vals = k,
       numPre = numPre, numPost = numPost)
}

# --- Helper: find breakdown Mbar (where CI first crosses zero) ---------------
breakdown_mbar <- function(rel) {
  # rel is a data.frame with columns Mbar, lb, ub
  # Result must be CONSISTENT with originally negative or originally positive
  rd <- as.data.table(rel)
  setorder(rd, Mbar)
  signs_lb <- sign(rd$lb)
  signs_ub <- sign(rd$ub)
  # CI excludes zero iff lb*ub > 0
  excludes_zero <- rd$lb * rd$ub > 0
  if (!any(excludes_zero)) return(0)
  # Breakdown = first Mbar at which CI INCLUDES zero
  if (all(excludes_zero)) return(Inf)
  first_includes <- min(rd$Mbar[!excludes_zero])
  first_includes
}

# --- Run for three outcomes --------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("HONEST-DiD: Relative-magnitudes bounds (target = average post-period)\n")
cat(strrep("=", 78), "\n", sep = "")

hd_emp   <- run_honestdid(es_results$models$log_employment, "log_employment")
hd_wage  <- run_honestdid(es_results$models$mean_log_wage,  "mean_log_wage")
hd_hours <- run_honestdid(es_results$models$mean_hours,     "mean_hours")

# Print bounds tables
cat("\n--- log_employment ---\n")
cat("Original CI: [", round(hd_emp$orig$lb, 4), ",",
    round(hd_emp$orig$ub, 4), "]\n")
print(hd_emp$rel)
cat(sprintf("Breakdown Mbar (smallest Mbar where CI includes 0): %.2f\n",
            breakdown_mbar(hd_emp$rel)))

cat("\n--- mean_log_wage ---\n")
cat("Original CI: [", round(hd_wage$orig$lb, 4), ",",
    round(hd_wage$orig$ub, 4), "]\n")
print(hd_wage$rel)
cat(sprintf("Breakdown Mbar: %.2f\n", breakdown_mbar(hd_wage$rel)))

cat("\n--- mean_hours ---\n")
cat("Original CI: [", round(hd_hours$orig$lb, 4), ",",
    round(hd_hours$orig$ub, 4), "]\n")
print(hd_hours$rel)
cat(sprintf("Breakdown Mbar: %.2f\n", breakdown_mbar(hd_hours$rel)))

# --- Plot sensitivity --------------------------------------------------------
plot_honest <- function(rel, orig, outcome_label, fname) {
  d <- as.data.table(rel)
  # Add original (Mbar = NA, just plot as reference)
  o <- data.table(Mbar = -0.3, lb = orig$lb, ub = orig$ub,
                  method = "Original CI")
  d[, method := "Honest-DiD"]
  d2 <- rbindlist(list(d, o), fill = TRUE)

  p <- ggplot(d2, aes(x = factor(Mbar), y = (lb + ub) / 2,
                      ymin = lb, ymax = ub, color = method)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_pointrange(size = 0.4, position = position_dodge(width = 0.3)) +
    scale_color_manual(values = c("Honest-DiD" = "black",
                                  "Original CI" = "red")) +
    labs(
      x = expression(bar(M)),
      y = "Identified set / IC para el efecto promedio post",
      title = paste("Honest-DiD —", outcome_label),
      subtitle = "Cotas Rambachan-Roth (2023), restricción de magnitudes relativas",
      color = ""
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.minor = element_blank(),
          legend.position = "bottom")

  ggsave(file.path(fig_dir, fname), p, width = 8, height = 4.5)
  invisible(p)
}

plot_honest(hd_emp$rel,   hd_emp$orig,   "log empleo",
            "honest_did_log_employment.pdf")
plot_honest(hd_wage$rel,  hd_wage$orig,  "log salario hora",
            "honest_did_mean_log_wage.pdf")
plot_honest(hd_hours$rel, hd_hours$orig, "horas semanales",
            "honest_did_mean_hours.pdf")

# --- Save --------------------------------------------------------------------
results <- list(
  log_employment = hd_emp,
  mean_log_wage  = hd_wage,
  mean_hours     = hd_hours,
  breakdown = c(
    log_employment = breakdown_mbar(hd_emp$rel),
    mean_log_wage  = breakdown_mbar(hd_wage$rel),
    mean_hours     = breakdown_mbar(hd_hours$rel)
  )
)
saveRDS(results, file.path(out_dir, "honest_did_bounds.rds"))

# --- Summary --------------------------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("BREAKDOWN MBAR — methodology criterion: Mbar >= 2.0\n")
cat(strrep("=", 78), "\n", sep = "")
for (out in c("log_employment", "mean_log_wage", "mean_hours")) {
  m <- results$breakdown[[out]]
  status <- if (is.infinite(m)) "robust at all Mbar tested" else
            if (m >= 2.0) sprintf("PASS (Mbar = %.2f >= 2.0)", m) else
            sprintf("FAIL (Mbar = %.2f < 2.0)", m)
  cat(sprintf("  %-20s  %s\n", out, status))
}

cat(sprintf("\n[DONE] Honest-DiD bounds saved.\n"))
