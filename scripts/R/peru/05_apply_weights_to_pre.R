# ==============================================================================
# 05_apply_weights_to_pre.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 5 (apply weights, build harmonized panel)
#
# Reads the posterior weights (4 fallback levels) and the EPEN long panel,
# then produces a single harmonized panel coded in CIUO-08 4d for both pre
# and post periods.
#
#   POST observations (2022Q4-2025Q4): deterministic merge with CNO -> CIUO.
#                                      One pre row -> one harmonized row.
#                                      level_used = -1, prob = 1.
#
#   PRE observations (2021Q1-2022Q3):  progressive fallback to most-saturated
#                                      (k, X) cell that has n_obs >= 30 in
#                                      the post. Each pre row expands to
#                                      multiple harmonized rows (one per
#                                      candidate CIUO), with weights split
#                                      by the posterior probability.
#                                      level_used in {0, 1, 2, 3}.
#
# Final harmonized weight: original survey weight x posterior probability.
# Sum of harmonized weights across the expansion of one pre worker equals
# the worker's original weight.
#
# Output: data/cleaned/peru/epen_harmonized_ciuo.rds
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(data.table)
library(stringr)

cw_dir  <- here("data", "cleaned", "peru", "crosswalks")
out_dir <- here("data", "cleaned", "peru")

panel   <- readRDS(file.path(out_dir, "epen_long_classified.rds"))
weights <- readRDS(file.path(out_dir, "posterior_weights.rds"))
a3      <- readRDS(file.path(cw_dir, "anexo3_cno_to_ciuo.rds"))

THRESHOLD <- 30L

# --- Pad codes & add age_bin in panel ----------------------------------------
pad_code <- function(x, width) {
  formatC(as.integer(x), width = width, format = "d", flag = "0")
}

panel[classifier == "CO1995_3d",  code_co  := pad_code(occ_raw, 3)]
panel[classifier == "CNO2015_4d", code_cno := pad_code(occ_raw, 4)]
panel[, age_bin := fcase(
  age >= 14 & age <= 29, "14_29",
  age >= 30 & age <= 49, "30_49",
  age >= 50 & age <= 65, "50_65"
)]

# Unique row id (audit trail)
panel[, row_id := .I]

# --- Build deterministic CNO -> CIUO lookup ----------------------------------
cnotociuo <- a3[, .(code_ciuo = min(code_ciuo)), keyby = code_cno]

# --- POST: deterministic CIUO assignment -------------------------------------
post <- panel[classifier == "CNO2015_4d"]
post <- merge(post, cnotociuo, by = "code_cno", all.x = TRUE)

# Drop unmatched (should be zero per Phase 4 diagnostics)
post <- post[!is.na(code_ciuo)]
post[, level_used := -1L]
post[, prob := 1.0]
post[, weight_harmonized := weight]

cat(sprintf("POST harmonized: %d rows | total weight: %.0f\n",
            nrow(post), sum(post$weight_harmonized)))

# --- PRE: progressive fallback -----------------------------------------------
pre <- panel[classifier == "CO1995_3d" &
             !is.na(code_co) & !is.na(female) & !is.na(age_bin) &
             !is.na(educ5)   & !is.na(sector_1d)]

# Build sets of "good" cell keys at each level
L0 <- weights$L0[n_obs_group >= THRESHOLD]
L1 <- weights$L1[n_obs_group >= THRESHOLD]
L2 <- weights$L2[n_obs_group >= THRESHOLD]
# L3 is the last-resort fallback — no threshold. A pre observation lands here
# only if its (k, X) cell failed thresholds at L0, L1, L2; using whatever data
# we have at the code_co level (even if sparse) is strictly better than
# dropping the observation.
L3 <- weights$L3

# L3 is built from POST observations — but some CO-95 codes appear in PRE
# without ever being observed in POST (no worker's CNO mapped to them via
# Anexo 1). For those codes we fall back to the OFFICIAL INEI mapping
# Anexo 2 (CO-95 -> CNO list) + Anexo 3 (CNO -> CIUO), with uniform
# probability across the resulting CIUO set. This adds rows to L3.
a2 <- readRDS(file.path(cw_dir, "anexo2_co_to_cno.rds"))
official_path <- merge(a2[, .(code_co, code_cno)], cnotociuo, by = "code_cno")
official_l3 <- official_path[, .(code_ciuo = unique(code_ciuo)), by = code_co]
official_l3[, n_per_co := .N, by = code_co]
official_l3[, prob := 1 / n_per_co]
official_l3[, n_obs_group := 0L]
official_l3[, mass_group  := 0L]
official_l3[, n_obs       := 0L]
official_l3[, mass        := 0L]
official_l3[, level       := 3L]
official_l3[, n_per_co    := NULL]

# Append only the CO-95 codes that L3 doesn't already cover
codes_in_L3 <- unique(L3$code_co)
official_to_add <- official_l3[!code_co %in% codes_in_L3]
cat(sprintf("\nOfficial-mapping fallback: adding %d CO-95 codes (%d CIUO rows) not in L3\n",
            uniqueN(official_to_add$code_co), nrow(official_to_add)))
L3 <- rbindlist(list(L3, official_to_add), fill = TRUE)

L0_keys <- unique(L0[, .(code_co, female, age_bin, educ5, sector_1d)])
L1_keys <- unique(L1[, .(code_co, female, age_bin, educ5)])
L2_keys <- unique(L2[, .(code_co, female, educ5)])
L3_keys <- unique(L3[, .(code_co)])

L0_keys[, in_L0 := TRUE]
L1_keys[, in_L1 := TRUE]
L2_keys[, in_L2 := TRUE]
L3_keys[, in_L3 := TRUE]

# Determine best level per pre observation
pre <- merge(pre, L0_keys,
             by = c("code_co", "female", "age_bin", "educ5", "sector_1d"),
             all.x = TRUE)
pre <- merge(pre, L1_keys,
             by = c("code_co", "female", "age_bin", "educ5"),
             all.x = TRUE)
pre <- merge(pre, L2_keys,
             by = c("code_co", "female", "educ5"),
             all.x = TRUE)
pre <- merge(pre, L3_keys, by = "code_co", all.x = TRUE)

pre[, level_used := fcase(
  in_L0 == TRUE, 0L,
  in_L1 == TRUE, 1L,
  in_L2 == TRUE, 2L,
  in_L3 == TRUE, 3L,
  default = NA_integer_
)]

cat("\nPRE level distribution:\n")
print(pre[, .N, by = level_used][order(level_used)])

# Drop rows where no level matched (should be very few or zero)
unmatched <- pre[is.na(level_used)]
if (nrow(unmatched) > 0) {
  cat(sprintf("WARNING: %d pre observations could not be matched at any level\n",
              nrow(unmatched)))
  cat("  Sample of unmatched code_co values:\n")
  print(head(unmatched[, .N, by = code_co][order(-N)], 10))
}
pre <- pre[!is.na(level_used)]

pre[, c("in_L0", "in_L1", "in_L2", "in_L3") := NULL]

# --- Apply level-specific posterior weights ----------------------------------
# Subset pre by level, merge with the corresponding probability table.
# Each merge expands rows by the number of CIUO candidates per cell.

apply_level <- function(pre_subset, weight_table, by_vars) {
  prob_tbl <- weight_table[, c(..by_vars, "code_ciuo", "prob")]
  out <- merge(pre_subset, prob_tbl, by = by_vars, allow.cartesian = TRUE)
  out
}

pre_l0 <- apply_level(pre[level_used == 0L], L0,
                      c("code_co", "female", "age_bin", "educ5", "sector_1d"))
pre_l1 <- apply_level(pre[level_used == 1L], L1,
                      c("code_co", "female", "age_bin", "educ5"))
pre_l2 <- apply_level(pre[level_used == 2L], L2,
                      c("code_co", "female", "educ5"))
pre_l3 <- apply_level(pre[level_used == 3L], L3, "code_co")

pre_harmonized <- rbindlist(list(pre_l0, pre_l1, pre_l2, pre_l3),
                            use.names = TRUE, fill = TRUE)
pre_harmonized[, weight_harmonized := weight * prob]

cat(sprintf("\nPRE harmonized: %d rows (from %d original) | total weight: %.0f\n",
            nrow(pre_harmonized), nrow(pre), sum(pre_harmonized$weight_harmonized)))

# Sanity: total weight in pre_harmonized should equal sum of original pre weights
expected_weight <- sum(pre$weight)
actual_weight   <- sum(pre_harmonized$weight_harmonized)
diff_pct <- abs(actual_weight - expected_weight) / expected_weight * 100
cat(sprintf("Total weight check: original=%.0f  expanded=%.0f  diff=%.4f%%\n",
            expected_weight, actual_weight, diff_pct))

# Sanity: each pre row's expansion should sum to 1 (within tolerance)
prob_sum_check <- pre_harmonized[, .(s = sum(prob)), by = row_id][!between(s, 0.999, 1.001)]
cat(sprintf("Pre rows with prob NOT summing to 1: %d / %d\n",
            nrow(prob_sum_check), uniqueN(pre_harmonized$row_id)))

# --- Stack pre + post --------------------------------------------------------
common_cols <- intersect(names(pre_harmonized), names(post))
harmonized <- rbind(post[, ..common_cols], pre_harmonized[, ..common_cols],
                    use.names = TRUE)
setorder(harmonized, year, quarter, row_id)

cat(sprintf("\nHarmonized panel: %d rows (from %d original observations)\n",
            nrow(harmonized), nrow(panel[!is.na(occ_raw)])))

# --- Final QC summary --------------------------------------------------------
cat("\nQuarterly summary of harmonized panel:\n")
qc <- harmonized[, .(
  n_rows         = .N,
  n_workers      = uniqueN(row_id),
  n_unique_ciuo  = uniqueN(code_ciuo),
  total_weight   = sum(weight_harmonized, na.rm = TRUE)
), by = .(year, quarter)][order(year, quarter)]
print(qc)

# --- Save ---------------------------------------------------------------------
saveRDS(harmonized, file.path(out_dir, "epen_harmonized_ciuo.rds"))
cat(sprintf("\n[DONE] Harmonized panel: %s\n",
            file.path(out_dir, "epen_harmonized_ciuo.rds")))
