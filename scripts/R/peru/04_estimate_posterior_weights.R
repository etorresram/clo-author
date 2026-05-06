# ==============================================================================
# 04_estimate_posterior_weights.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 4 (estimate posterior weights)
#
# Estimates the conditional distribution P(CIUO-08-4d | CO-1995-3d, X) using
# the post-period EPEN (2022Q4-2025Q4), where both classifiers are observable
# (CNO-2015 directly, CO-1995 derivable via Anexo 1 of INEI).
#
# Conditioning vector X = (sex, age_bin, educ5, sector_1d) — confirmed with
# user. is_formal excluded to avoid conditioning on a heterogeneity outcome.
#
# Progressive fallback for sparse cells:
#   Level 0: (sex, age_bin, educ5, sector_1d)   primary
#   Level 1: (sex, age_bin, educ5)               drop sector
#   Level 2: (sex, educ5)                         drop sector + age
#   Level 3: only k (CO-1995-3d)                  uniform over CIUO children
# A cell at level L is used iff its expanded mass (sum of weights) is >= 50.
#
# Ambiguity handling:
#   - Anexo 1 (CNO->CO95) has 86 CNO codes with multiple CO-95 candidates.
#     We resolve to the SMALLEST CO-95 numerically (deterministic, reproducible).
#     Robustness in Phase 6 re-estimates with the dominant CO-95 alternative.
#   - Anexo 3 (CNO->CIUO) has multi-CIUO CNOs for ~10% of codes; we resolve
#     by taking the smallest CIUO code numerically.
#
# Output: data/cleaned/peru/posterior_weights.rds
#         A long-format table with columns:
#           level (0/1/2/3), code_co95, X_cells..., code_ciuo, prob, n_post,
#           mass_post (expanded)
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(data.table)
library(stringr)

cw_dir  <- here("data", "cleaned", "peru", "crosswalks")
out_dir <- here("data", "cleaned", "peru")

panel <- readRDS(file.path(out_dir, "epen_long_classified.rds"))
a1    <- readRDS(file.path(cw_dir, "anexo1_cno_to_co.rds"))
a3    <- readRDS(file.path(cw_dir, "anexo3_cno_to_ciuo.rds"))

cat(sprintf("Panel rows: %d  |  Anexo 1: %d  |  Anexo 3: %d\n",
            nrow(panel), nrow(a1), nrow(a3)))

# --- Pad raw codes to canonical width ----------------------------------------
pad_code <- function(x, width) {
  formatC(as.integer(x), width = width, format = "d", flag = "0")
}

panel[classifier == "CO1995_3d",  code_co95 := pad_code(occ_raw, 3)]
panel[classifier == "CNO2015_4d", code_cno  := pad_code(occ_raw, 4)]

# Sanity: digit counts after padding
cat("\nDigit-count after padding:\n")
print(panel[!is.na(code_co95), .N, by = .(nchar = nchar(code_co95))])
print(panel[!is.na(code_cno),  .N, by = .(nchar = nchar(code_cno))])

# --- Build deterministic CNO -> CO-95 lookup ---------------------------------
# Anexo 1 has 86 ambiguous CNOs; pick the smallest CO-95 code numerically.
cnotoco <- a1[, .(code_co = min(code_co)), keyby = code_cno]
n_ambig_co <- nrow(a1[, .N, by = code_cno][N > 1])
cat(sprintf("\nCNO->CO95 deterministic lookup: %d codes (%d resolved from %d ambiguities)\n",
            nrow(cnotoco), n_ambig_co, sum(a1[, .N, by = code_cno][N > 1, N])))

# --- Build deterministic CNO -> CIUO lookup ----------------------------------
cnotociuo <- a3[, .(code_ciuo = min(code_ciuo)), keyby = code_cno]
n_ambig_ciuo <- nrow(a3[, .N, by = code_cno][N > 1])
cat(sprintf("CNO->CIUO deterministic lookup: %d codes (%d resolved from %d ambiguities)\n",
            nrow(cnotociuo), n_ambig_ciuo, sum(a3[, .N, by = code_cno][N > 1, N])))

# --- Construct age_bin in the panel ------------------------------------------
panel[, age_bin := fcase(
  age >= 14 & age <= 29, "14_29",
  age >= 30 & age <= 49, "30_49",
  age >= 50 & age <= 65, "50_65"
)]

# --- Apply lookups to POST observations --------------------------------------
post <- panel[classifier == "CNO2015_4d"]
post <- merge(post, cnotoco,   by = "code_cno", all.x = TRUE)
post <- merge(post, cnotociuo, by = "code_cno", all.x = TRUE)

unmatched_co   <- sum(is.na(post$code_co))
unmatched_ciuo <- sum(is.na(post$code_ciuo))
cat(sprintf("\nPost obs: %d  |  unmatched CO95: %d  |  unmatched CIUO: %d\n",
            nrow(post), unmatched_co, unmatched_ciuo))
if (unmatched_co > 0 || unmatched_ciuo > 0) {
  cat("  Unmatched CNO codes (top 10):\n")
  print(post[is.na(code_co) | is.na(code_ciuo),
             .N, keyby = code_cno][order(-N)][1:10])
}

# Drop unmatched rows (cannot estimate posterior weights for them)
post <- post[!is.na(code_co) & !is.na(code_ciuo) &
             !is.na(sector_1d) & !is.na(age_bin) & !is.na(educ5) &
             !is.na(female)]
cat(sprintf("Post obs after dropping NAs in conditioning vars: %d\n", nrow(post)))

# --- Estimate Pr(CIUO | CO-95, X) at four fallback levels --------------------
# Level 0: full X. Cells with mass >= 50 expanded units win.
# At each lower level, only cells that didn't have mass >= 50 at higher levels
# are filled — but we just compute all four tables and let Phase 5 select.

estimate_level <- function(post_dt, group_vars, level) {
  by_target <- c(group_vars, "code_ciuo")
  # Mass per (group, ciuo)
  agg <- post_dt[, .(mass = sum(weight, na.rm = TRUE), n_obs = .N),
                 by = by_target]
  # Total mass per group (denominator)
  agg[, mass_group := sum(mass), by = group_vars]
  agg[, n_obs_group := sum(n_obs), by = group_vars]
  agg[, prob := mass / mass_group]
  agg[, level := level]
  setcolorder(agg, c("level", group_vars, "code_ciuo",
                     "prob", "mass", "mass_group", "n_obs", "n_obs_group"))
  agg
}

cat("\nEstimating posterior weights at 4 levels ...\n")

L0 <- estimate_level(post,
                     c("code_co", "female", "age_bin", "educ5", "sector_1d"), 0)
L1 <- estimate_level(post,
                     c("code_co", "female", "age_bin", "educ5"), 1)
L2 <- estimate_level(post,
                     c("code_co", "female", "educ5"), 2)
L3 <- estimate_level(post, "code_co", 3)

# Threshold: at least 30 SAMPLE observations per (k, X) cell (not expanded).
# Cells below this threshold are flagged for fallback to a coarser X.
THRESHOLD <- 30L

report_level <- function(tbl, group_vars, level_id) {
  cells <- unique(tbl[, ..group_vars])
  ok    <- unique(tbl[n_obs_group >= THRESHOLD, ..group_vars])
  cat(sprintf("  Level %d cells: %d  | n_obs>=%d: %d (%.1f%%)  | median n_obs/cell: %d\n",
              level_id, nrow(cells), THRESHOLD, nrow(ok),
              100 * nrow(ok) / nrow(cells),
              as.integer(median(unique(tbl[, .(g = .GRP, n_obs_group),
                                          by = group_vars]$n_obs_group)))))
}

report_level(L0, c("code_co", "female", "age_bin", "educ5", "sector_1d"), 0)
report_level(L1, c("code_co", "female", "age_bin", "educ5"),              1)
report_level(L2, c("code_co", "female", "educ5"),                          2)
report_level(L3, "code_co",                                                3)

# --- Sanity: probabilities sum to 1 within each cell -------------------------
sum_check <- L0[, .(s = sum(prob)),
                by = .(code_co, female, age_bin, educ5, sector_1d)][!between(s, 0.999, 1.001)]
cat(sprintf("\nLevel 0 cells where prob does NOT sum to 1: %d\n", nrow(sum_check)))

# --- Save ---------------------------------------------------------------------
weights <- list(L0 = L0, L1 = L1, L2 = L2, L3 = L3)
saveRDS(weights, file.path(out_dir, "posterior_weights.rds"))
cat(sprintf("\n[DONE] Posterior weights saved to %s\n",
            file.path(out_dir, "posterior_weights.rds")))
