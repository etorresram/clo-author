# ==============================================================================
# 06_validate_imputation.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 6 (validate imputation)
#
# Two diagnostic tests for the harmonization procedure (Test 3, donut DiD,
# is post-DiD and lives in the robustness section):
#
#   Test 1: Composition stability at the cutoff.
#     Compare CIUO-08 employment shares in 2022Q3 (imputed pre) vs 2022Q4
#     (observed post). Under correct harmonization, no CIUO code should
#     exhibit a share jump > 5pp not attributable to the LLM shock.
#
#   Test 2: Temporal stability of posterior weights.
#     Re-estimate Pr(CIUO | k, X) using only 2023, only 2024, only 2025
#     post observations. Compute pairwise Kullback-Leibler divergence
#     (with Laplace smoothing) and total-variation distance between
#     the resulting distributions. Aggregate by employment weight.
#     Criterion (data.tex): aggregate KL < 0.05 nats.
#
# Output: data/cleaned/peru/imputation_diagnostics.rds (named list)
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(data.table)
library(stringr)

cw_dir  <- here("data", "cleaned", "peru", "crosswalks")
out_dir <- here("data", "cleaned", "peru")

harmonized <- readRDS(file.path(out_dir, "epen_harmonized_ciuo.rds"))
panel      <- readRDS(file.path(out_dir, "epen_long_classified.rds"))
a1         <- readRDS(file.path(cw_dir, "anexo1_cno_to_co.rds"))

# Reusable: deterministic CNO->CO95 lookup
cnotoco <- a1[, .(code_co = min(code_co)), keyby = code_cno]

# ==============================================================================
# TEST 1: Composition stability at the cutoff (2022Q3 vs 2022Q4)
# ==============================================================================
cat("\n", strrep("=", 78), "\n", sep = "")
cat("TEST 1: Composition stability at 2022Q3 (imputed) vs 2022Q4 (observed)\n")
cat(strrep("=", 78), "\n", sep = "")

q3 <- harmonized[year == 2022 & quarter == 3,
                 .(weight = sum(weight_harmonized, na.rm = TRUE)),
                 by = code_ciuo]
q3[, share := weight / sum(weight)]
setnames(q3, "share", "share_q3")
setnames(q3, "weight", "w_q3")

q4 <- harmonized[year == 2022 & quarter == 4,
                 .(weight = sum(weight_harmonized, na.rm = TRUE)),
                 by = code_ciuo]
q4[, share := weight / sum(weight)]
setnames(q4, "share", "share_q4")
setnames(q4, "weight", "w_q4")

cmp <- merge(q3, q4, by = "code_ciuo", all = TRUE)
cmp[is.na(share_q3), share_q3 := 0]
cmp[is.na(share_q4), share_q4 := 0]
cmp[, abs_diff_pp := abs(share_q4 - share_q3) * 100]
setorder(cmp, -abs_diff_pp)

cat(sprintf("  N CIUO codes considered: %d\n", nrow(cmp)))
cat(sprintf("  Median |diff|:           %.3f pp\n", median(cmp$abs_diff_pp)))
cat(sprintf("  Mean |diff|:             %.3f pp\n", mean(cmp$abs_diff_pp)))
cat(sprintf("  P90 |diff|:              %.3f pp\n", quantile(cmp$abs_diff_pp, 0.90)))
cat(sprintf("  P95 |diff|:              %.3f pp\n", quantile(cmp$abs_diff_pp, 0.95)))
cat(sprintf("  Max |diff|:              %.3f pp\n", max(cmp$abs_diff_pp)))
n_over_5pp <- sum(cmp$abs_diff_pp > 5)
cat(sprintf("  N CIUOs with |diff| > 5pp: %d (%.1f%%)\n",
            n_over_5pp, 100 * n_over_5pp / nrow(cmp)))

cat("\nTop 10 CIUO codes by absolute share difference:\n")
print(cmp[1:10, .(code_ciuo,
                  share_q3_pp = round(share_q3 * 100, 3),
                  share_q4_pp = round(share_q4 * 100, 3),
                  abs_diff_pp = round(abs_diff_pp, 3))])

test1 <- list(
  comparison       = cmp,
  median_abs_diff  = median(cmp$abs_diff_pp),
  max_abs_diff     = max(cmp$abs_diff_pp),
  p90_abs_diff     = quantile(cmp$abs_diff_pp, 0.90),
  n_over_5pp       = n_over_5pp,
  passes           = max(cmp$abs_diff_pp) <= 5
)

# ==============================================================================
# TEST 2: Temporal stability of posterior weights across post subperiods
# ==============================================================================
cat("\n", strrep("=", 78), "\n", sep = "")
cat("TEST 2: Temporal stability — re-estimate posterior weights by year\n")
cat(strrep("=", 78), "\n", sep = "")

# Build the post-period reference (CO-95-3d derivable + CIUO-08 observed)
panel[classifier == "CNO2015_4d", code_cno := formatC(as.integer(occ_raw),
                                                       width = 4, format = "d",
                                                       flag = "0")]
panel[, age_bin := fcase(
  age >= 14 & age <= 29, "14_29",
  age >= 30 & age <= 49, "30_49",
  age >= 50 & age <= 65, "50_65"
)]

a3 <- readRDS(file.path(cw_dir, "anexo3_cno_to_ciuo.rds"))
cnotociuo <- a3[, .(code_ciuo = min(code_ciuo)), keyby = code_cno]

post <- panel[classifier == "CNO2015_4d"]
post <- merge(post, cnotoco,   by = "code_cno", all.x = TRUE)
post <- merge(post, cnotociuo, by = "code_cno", all.x = TRUE)
post <- post[!is.na(code_co) & !is.na(code_ciuo) &
             !is.na(female) & !is.na(age_bin) &
             !is.na(educ5)  & !is.na(sector_1d)]

# Subset by year
y <- list(
  "2023" = post[year == 2023],
  "2024" = post[year == 2024],
  "2025" = post[year == 2025]
)

# Compute Pr(CIUO | k, X) per year
compute_dist <- function(d) {
  agg <- d[, .(mass = sum(weight, na.rm = TRUE), n_obs = .N),
           by = .(code_co, female, age_bin, educ5, sector_1d, code_ciuo)]
  agg[, mass_group := sum(mass), by = .(code_co, female, age_bin, educ5, sector_1d)]
  agg[, n_obs_group := sum(n_obs), by = .(code_co, female, age_bin, educ5, sector_1d)]
  agg[, prob := mass / mass_group]
  agg
}

D <- lapply(y, compute_dist)

# For pairwise KL, we need cells present in BOTH years AND with sufficient mass.
# Use Laplace smoothing (add eps) to avoid log(0).
EPS <- 1e-4
THRESHOLD <- 30L

pairwise_metrics <- function(p, q, label) {
  # Restrict to cells where both have n_obs_group >= THRESHOLD
  cell_vars <- c("code_co", "female", "age_bin", "educ5", "sector_1d")
  p_ok <- unique(p[n_obs_group >= THRESHOLD, ..cell_vars])
  q_ok <- unique(q[n_obs_group >= THRESHOLD, ..cell_vars])
  cells_common <- merge(p_ok, q_ok, by = cell_vars)
  cat(sprintf("\n  Pair %s: cells with n>=%d in both years: %d\n",
              label, THRESHOLD, nrow(cells_common)))
  if (nrow(cells_common) == 0) return(NULL)

  # Outer join over the union of CIUO codes within each cell
  pp <- merge(cells_common, p, by = cell_vars)[, .SD,
              .SDcols = c(cell_vars, "code_ciuo", "prob", "mass_group")]
  qq <- merge(cells_common, q, by = cell_vars)[, .SD,
              .SDcols = c(cell_vars, "code_ciuo", "prob")]
  setnames(pp, "prob", "p")
  setnames(qq, "prob", "q")
  joined <- merge(pp, qq, by = c(cell_vars, "code_ciuo"), all = TRUE)
  joined[is.na(p), p := 0]
  joined[is.na(q), q := 0]

  # Re-fill mass_group to all rows (weight for aggregation later)
  cell_mass <- joined[!is.na(mass_group), .(mg = first(mass_group)),
                      by = cell_vars]
  joined[, mass_group := NULL]
  joined <- merge(joined, cell_mass, by = cell_vars, all.x = TRUE)
  setnames(joined, "mg", "mass_group")

  # Smooth and renormalize within each cell
  joined[, p_s := (p + EPS)]
  joined[, q_s := (q + EPS)]
  joined[, p_s := p_s / sum(p_s), by = cell_vars]
  joined[, q_s := q_s / sum(q_s), by = cell_vars]

  # Per-cell KL (p_s || q_s) and total variation
  per_cell <- joined[, .(
    kl  = sum(p_s * log(p_s / q_s)),
    tv  = 0.5 * sum(abs(p - q)),
    mass_group = first(mass_group)
  ), by = cell_vars]

  # Employment-weighted aggregate
  total_mass <- sum(per_cell$mass_group)
  agg_kl <- sum(per_cell$kl * per_cell$mass_group) / total_mass
  agg_tv <- sum(per_cell$tv * per_cell$mass_group) / total_mass
  cat(sprintf("    Aggregate KL (employment-weighted): %.4f nats\n", agg_kl))
  cat(sprintf("    Aggregate TV (employment-weighted): %.4f\n", agg_tv))
  cat(sprintf("    Cell-level KL: median=%.4f  p90=%.4f  max=%.4f\n",
              median(per_cell$kl), quantile(per_cell$kl, 0.90), max(per_cell$kl)))

  list(per_cell = per_cell, agg_kl = agg_kl, agg_tv = agg_tv,
       n_cells = nrow(per_cell), total_mass = total_mass)
}

cat("\nPairwise comparisons of posterior weights between post-period years:\n")
m_23_24 <- pairwise_metrics(D[["2023"]], D[["2024"]], "2023 vs 2024")
m_24_25 <- pairwise_metrics(D[["2024"]], D[["2025"]], "2024 vs 2025")
m_23_25 <- pairwise_metrics(D[["2023"]], D[["2025"]], "2023 vs 2025")

test2 <- list(
  m_23_24 = m_23_24,
  m_24_25 = m_24_25,
  m_23_25 = m_23_25,
  passes_05 = all(c(m_23_24$agg_kl, m_24_25$agg_kl, m_23_25$agg_kl) < 0.05)
)

# --- Save ---------------------------------------------------------------------
diagnostics <- list(test1 = test1, test2 = test2)
saveRDS(diagnostics, file.path(out_dir, "imputation_diagnostics.rds"))

# --- Final summary ------------------------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("SUMMARY\n")
cat(strrep("=", 78), "\n", sep = "")
cat(sprintf("  Test 1 — Composition stability:\n"))
cat(sprintf("    max |diff| at cutoff = %.2f pp  (criterion: <= 5 pp)  %s\n",
            test1$max_abs_diff,
            if (test1$passes) "PASS" else "FAIL"))
cat(sprintf("  Test 2 — Temporal stability of posterior weights:\n"))
cat(sprintf("    aggregate KL 23-24 = %.4f nats\n", m_23_24$agg_kl))
cat(sprintf("    aggregate KL 24-25 = %.4f nats\n", m_24_25$agg_kl))
cat(sprintf("    aggregate KL 23-25 = %.4f nats\n", m_23_25$agg_kl))
cat(sprintf("    criterion: < 0.05 nats           %s\n",
            if (test2$passes_05) "PASS" else "FAIL"))

cat(sprintf("\n[DONE] Diagnostics saved to %s\n",
            file.path(out_dir, "imputation_diagnostics.rds")))
