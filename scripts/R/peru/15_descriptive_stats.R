# ==============================================================================
# 15_descriptive_stats.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 15 (descriptive statistics for paper)
#
# Produces the four pieces the data.tex Descriptives subsection needs:
#   1. Sample-size table by year (workers, expanded employment, % formal,
#      mean weekly hours, mean hourly wage).
#   2. Baseline 2021 demographics (one column).
#   3. Beta distribution: weighted mean, SD, percentiles, share with beta=0.
#   4. Top-10 most-exposed and least-exposed occupations.
#
# Output:
#   data/cleaned/peru/descriptive_stats.rds   (named list)
#   paper/tables/peru/tab_*.tex               (LaTeX tables for inclusion)
# ==============================================================================

library(here)
library(data.table)

out_dir <- here("data", "cleaned", "peru")
tab_dir <- here("paper", "tables", "peru")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

panel <- readRDS(file.path(out_dir, "epen_with_exposure.rds"))

# Worker-level rows are EXPANDED for pre period via posterior weights; for
# population-representative descriptive statistics we use weight_harmonized.
panel_valid <- panel[!is.na(beta) & !is.na(weight_harmonized)]

# --- Helper: weighted SD and quantile -----------------------------------------
weighted_sd <- function(x, w) {
  m <- weighted.mean(x, w, na.rm = TRUE)
  sqrt(sum(w * (x - m)^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
}
weighted_quantile <- function(x, w, probs) {
  ord <- order(x); x <- x[ord]; w <- w[ord]
  cw  <- cumsum(w) / sum(w)
  vapply(probs, function(p) x[which.max(cw >= p)], numeric(1))
}

# ==============================================================================
# Table 1: Sample sizes and aggregate outcomes by year
# ==============================================================================
yr <- panel_valid[, .(
  n_workers      = uniqueN(paste(conglomerado, selviv, hogar, persona, year, quarter)),
  n_obs_rows     = .N,
  emp_expanded   = sum(weight_harmonized) / 4,  # avg per quarter (4 quarters)
  pct_formal     = 100 * weighted.mean(is_formal, w = weight_harmonized,
                                       na.rm = TRUE),
  hours_mean     = weighted.mean(hours, w = weight_harmonized, na.rm = TRUE),
  log_wage_mean  = weighted.mean(log_wage_hour, w = weight_harmonized,
                                 na.rm = TRUE),
  beta_mean      = weighted.mean(beta, w = weight_harmonized, na.rm = TRUE)
), by = year][order(year)]

cat("\n=== Sample sizes and aggregate outcomes by year ===\n")
print(yr)

# ==============================================================================
# Table 2: Baseline 2021 demographics (single column)
# ==============================================================================
b21 <- panel_valid[year == 2021]
demo <- list(
  N_workers       = nrow(b21),
  emp_expanded_q1 = round(sum(b21[year == 2021 & quarter == 1]$weight_harmonized)),
  age_mean        = round(weighted.mean(b21$age, w = b21$weight_harmonized), 1),
  age_sd          = round(weighted_sd(b21$age, b21$weight_harmonized), 1),
  pct_female      = round(100 * weighted.mean(b21$female,
                                              w = b21$weight_harmonized), 1),
  pct_terciary    = round(100 * weighted.mean(b21$educ5 == "universitaria" |
                                              b21$educ5 == "no_univ",
                                              w = b21$weight_harmonized), 1),
  pct_formal      = round(100 * weighted.mean(b21$is_formal,
                                              w = b21$weight_harmonized), 1),
  hours_mean      = round(weighted.mean(b21$hours, w = b21$weight_harmonized), 1),
  hours_sd        = round(weighted_sd(b21$hours, b21$weight_harmonized), 1),
  log_wage_mean   = round(weighted.mean(b21$log_wage_hour,
                                        w = b21$weight_harmonized,
                                        na.rm = TRUE), 2)
)
cat("\n=== 2021 baseline demographics ===\n")
str(demo)

# ==============================================================================
# Table 3: Beta distribution (employment-weighted), 2021 vs 2025
# ==============================================================================
beta_dist <- function(d, label) {
  q <- weighted_quantile(d$beta, d$weight_harmonized,
                         c(0.10, 0.25, 0.50, 0.75, 0.90))
  data.table(
    period   = label,
    mean     = weighted.mean(d$beta, w = d$weight_harmonized),
    sd       = weighted_sd(d$beta, d$weight_harmonized),
    p10      = q[1], p25 = q[2], p50 = q[3], p75 = q[4], p90 = q[5],
    pct_zero = 100 * weighted.mean(d$beta == 0, w = d$weight_harmonized)
  )
}
bdist <- rbindlist(list(
  beta_dist(panel_valid[year == 2021], "2021 (baseline)"),
  beta_dist(panel_valid[year == 2025], "2025 (final)")
))
cat("\n=== Beta distribution, employment-weighted ===\n")
print(bdist)

# ==============================================================================
# Table 4: Top-10 most/least exposed CIUO codes
# ==============================================================================
ciuo_emp <- panel_valid[year == 2021,
                        .(emp = sum(weight_harmonized),
                          beta = first(beta)),
                        by = code_ciuo][order(-beta)]
top10 <- ciuo_emp[!is.na(beta)][1:10]
bot10 <- ciuo_emp[!is.na(beta)][order(beta)][1:10]

# Add labels by joining with exposure file
exp4 <- fread(here("data", "cleaned", "exposure", "exposure_isco08.csv"))
exp4[, isco08_4d := formatC(as.integer(isco08_4d), width = 4,
                            format = "d", flag = "0")]
top10 <- merge(top10, exp4[, .(code_ciuo = isco08_4d, isco08_label)],
               by = "code_ciuo", all.x = TRUE)
bot10 <- merge(bot10, exp4[, .(code_ciuo = isco08_4d, isco08_label)],
               by = "code_ciuo", all.x = TRUE)
top10[, label_es := isco08_label]
bot10[, label_es := isco08_label]
cat("\n=== Top 10 most-exposed CIUO codes (2021) ===\n")
print(top10[order(-beta), .(code_ciuo, beta = round(beta, 3),
                            emp = round(emp), label_es)])
cat("\n=== Bottom 10 least-exposed CIUO codes ===\n")
print(bot10[order(beta), .(code_ciuo, beta = round(beta, 3),
                           emp = round(emp), label_es)])

# ==============================================================================
# Table 5: Cross-tabulation beta quartile x formality
# ==============================================================================
b21q <- panel_valid[year == 2021]
b21q[, beta_q := cut(beta,
                     breaks = c(-Inf,
                                weighted_quantile(b21q$beta, b21q$weight_harmonized,
                                                  c(0.25, 0.5, 0.75)),
                                Inf),
                     labels = c("Q1 (baja)", "Q2", "Q3", "Q4 (alta)"))]
ct <- b21q[, .(
  pct_formal = 100 * weighted.mean(is_formal, w = weight_harmonized),
  emp        = sum(weight_harmonized),
  beta_med   = weighted_quantile(beta, weight_harmonized, 0.5)
), by = beta_q][order(beta_q)]
ct[, share_emp := round(100 * emp / sum(emp), 1)]
cat("\n=== Cross-tab: beta quartile x formality (2021) ===\n")
print(ct)

# ==============================================================================
# Save and write LaTeX fragments
# ==============================================================================
results <- list(
  yearly       = yr,
  demographics = demo,
  beta_dist    = bdist,
  top10        = top10,
  bottom10     = bot10,
  cross_tab    = ct
)
saveRDS(results, file.path(out_dir, "descriptive_stats.rds"))

# --- LaTeX: yearly summary ---------------------------------------------------
yr_tex <- sprintf(
  paste0("%d & %d & %.0f & %.1f & %.1f & %.2f & %.3f \\\\\n"),
  yr$year,
  yr$n_workers,
  yr$emp_expanded,
  yr$pct_formal,
  yr$hours_mean,
  yr$log_wage_mean,
  yr$beta_mean
)
writeLines(yr_tex, file.path(tab_dir, "tab_yearly.tex"))

# --- LaTeX: top/bottom 10 occupations -----------------------------------------
top_tex <- sprintf(
  "%s & %.3f & %s \\\\\n",
  top10$code_ciuo[1:10], round(top10$beta[1:10], 3),
  substr(top10$label_es[1:10], 1, 60)
)
writeLines(top_tex, file.path(tab_dir, "tab_top10.tex"))

bot_tex <- sprintf(
  "%s & %.3f & %s \\\\\n",
  bot10$code_ciuo[1:10], round(bot10$beta[1:10], 3),
  substr(bot10$label_es[1:10], 1, 60)
)
writeLines(bot_tex, file.path(tab_dir, "tab_bottom10.tex"))

cat(sprintf("\n[DONE] Descriptives saved.\n"))
cat(sprintf("       LaTeX fragments in: %s\n", tab_dir))
