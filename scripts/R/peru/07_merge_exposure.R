# ==============================================================================
# 07_merge_exposure.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 7 (merge GPT-exposure scores)
#
# Merges the Eloundou et al. (2023) exposure panel onto the harmonized Peru
# panel (CIUO-08 4d). Strategy:
#   1. Try 4-digit match (preferred granularity).
#   2. For codes unmatched at 4d, fall back to 3d (ISCO-08 3-digit aggregate).
#   3. Report match rate; objective is >=98% per the methodology.
#
# Operational treatment dose: E_o = beta_o (complementary exposure, the choice
# defended in sec:method).
#
# Input:
#   data/cleaned/peru/epen_harmonized_ciuo.rds  (157,608 rows)
#   data/cleaned/exposure/exposure_isco08.csv     (438 codes)
#   data/cleaned/exposure/exposure_isco08_3d.csv  (130 codes, 3d fallback)
#
# Output:
#   data/cleaned/peru/epen_with_exposure.rds      (panel + alpha,beta,zeta,gamma)
#   data/cleaned/peru/exposure_match_diagnostics.rds
# ==============================================================================

library(here)
library(data.table)

out_dir <- here("data", "cleaned", "peru")
exp_dir <- here("data", "cleaned", "exposure")

panel <- readRDS(file.path(out_dir, "epen_harmonized_ciuo.rds"))
exp4  <- fread(file.path(exp_dir, "exposure_isco08.csv"))
exp3  <- fread(file.path(exp_dir, "exposure_isco08_3d.csv"))

cat(sprintf("Panel rows: %d  | unique CIUO 4d: %d\n",
            nrow(panel), uniqueN(panel$code_ciuo)))
cat(sprintf("Exposure 4d: %d codes (%d with beta) | Exposure 3d: %d (%d with beta)\n",
            nrow(exp4), sum(!is.na(exp4$beta)),
            nrow(exp3), sum(!is.na(exp3$beta))))

# --- Standardize keys ---------------------------------------------------------
# Both code_ciuo and isco08_4d should be 4-digit zero-padded character.
exp4[, isco08_4d := formatC(as.integer(isco08_4d), width = 4,
                            format = "d", flag = "0")]
panel_keys <- unique(panel$code_ciuo)
exp_keys   <- exp4$isco08_4d

cat(sprintf("\nPanel CIUO codes:    %d\n", length(panel_keys)))
cat(sprintf("Exposure 4d codes:   %d\n", length(exp_keys)))
cat(sprintf("Codes in both:       %d\n", length(intersect(panel_keys, exp_keys))))
cat(sprintf("Panel codes missing in exposure 4d: %d\n",
            length(setdiff(panel_keys, exp_keys))))

# --- Stage 1: 4-digit merge ---------------------------------------------------
exp4_keep <- exp4[, .(code_ciuo = isco08_4d,
                      alpha_4d = alpha, beta_4d = beta,
                      zeta_4d = zeta, gamma_4d = gamma,
                      match_quality_4d = match_quality)]

merged <- merge(panel, exp4_keep, by = "code_ciuo", all.x = TRUE)

# --- Stage 2: 3-digit fallback ------------------------------------------------
exp3[, isco08_3d := formatC(as.integer(isco08_3d), width = 3,
                            format = "d", flag = "0")]
exp3_keep <- exp3[, .(code_ciuo_3d = isco08_3d,
                      alpha_3d = alpha, beta_3d = beta,
                      zeta_3d = zeta, gamma_3d = gamma)]

merged[, code_ciuo_3d := substr(code_ciuo, 1, 3)]
merged <- merge(merged, exp3_keep, by = "code_ciuo_3d", all.x = TRUE)

# --- Resolve final exposure: prefer 4d when available -------------------------
merged[, alpha := fifelse(!is.na(alpha_4d), alpha_4d, alpha_3d)]
merged[, beta  := fifelse(!is.na(beta_4d),  beta_4d,  beta_3d)]
merged[, zeta  := fifelse(!is.na(zeta_4d),  zeta_4d,  zeta_3d)]
merged[, gamma := fifelse(!is.na(gamma_4d), gamma_4d, gamma_3d)]

# Provenance flag for transparency
merged[, exposure_source := fcase(
  !is.na(beta_4d), "4d_eloundou",
  !is.na(beta_3d), "3d_fallback",
  default          = "unmatched"
)]

# --- Diagnostics --------------------------------------------------------------
cat("\nExposure match rates (rows of harmonized panel):\n")
src <- merged[, .(n = .N, w = sum(weight_harmonized, na.rm = TRUE)),
              by = exposure_source]
src[, pct_n := round(100 * n / sum(n), 2)]
src[, pct_w := round(100 * w / sum(w), 2)]
print(src[order(-n)])

# Per-period match rate (verifies harmonization didn't kill the match)
cat("\nMatch rate by year (% of expanded employment with valid beta):\n")
qmatch <- merged[, .(
  total_w = sum(weight_harmonized, na.rm = TRUE),
  matched = sum(weight_harmonized[!is.na(beta)], na.rm = TRUE)
), by = year]
qmatch[, pct := round(100 * matched / total_w, 2)]
print(qmatch[order(year)])

# Beta distribution summary (employment-weighted in 2021 vs 2025)
weighted_quantile <- function(x, w, probs) {
  ord   <- order(x)
  x_    <- x[ord]
  cum_w <- cumsum(w[ord]) / sum(w)
  vapply(probs, function(p) x_[which.max(cum_w >= p)], numeric(1))
}

cat("\nEmployment-weighted beta distribution by quarter (2021Q1, 2023Q1, 2025Q4):\n")
for (yq in list(c(2021, 1), c(2023, 1), c(2025, 4))) {
  d <- merged[year == yq[1] & quarter == yq[2] & !is.na(beta)]
  q <- weighted_quantile(d$beta, d$weight_harmonized,
                         c(0.10, 0.25, 0.50, 0.75, 0.90))
  m <- weighted.mean(d$beta, w = d$weight_harmonized)
  cat(sprintf("  %dQ%d:  mean = %.3f  | p10 = %.3f  p50 = %.3f  p90 = %.3f\n",
              yq[1], yq[2], m, q[1], q[3], q[5]))
}

# --- Drop staging columns and save -------------------------------------------
merged[, c("code_ciuo_3d",
           "alpha_4d", "beta_4d", "zeta_4d", "gamma_4d",
           "alpha_3d", "beta_3d", "zeta_3d", "gamma_3d",
           "match_quality_4d") := NULL]

saveRDS(merged, file.path(out_dir, "epen_with_exposure.rds"))

diagnostics <- list(
  match_summary = src,
  per_year      = qmatch,
  unmatched_codes = unique(merged[exposure_source == "unmatched", code_ciuo])
)
saveRDS(diagnostics, file.path(out_dir, "exposure_match_diagnostics.rds"))

cat(sprintf("\n[DONE] Merged panel: %s\n",
            file.path(out_dir, "epen_with_exposure.rds")))
cat(sprintf("       Rows: %d  | with valid beta: %d (%.1f%%)\n",
            nrow(merged), sum(!is.na(merged$beta)),
            100 * mean(!is.na(merged$beta))))
