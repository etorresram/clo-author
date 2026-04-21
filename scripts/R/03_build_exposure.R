# ==============================================================================
# 03_build_exposure.R
# Build the occupational GPT-exposure panel at the ISCO-08 4-digit level.
# Paper : Torres (2026) -- Gen AI & LAC Labor Markets, Paper 1, Section 2.1
# Memo  : quality_reports/strategy_memo_genai_lac.md -- Sec. 1.2, 2.1, 8.4
#
# Inputs:
#   data/raw/onet/task_ratings.csv                    (Eloundou 2023, task-level)
#   data/raw/crosswalks/ISCO_SOC_Crosswalk.xls        (BLS ISCO-08 <-> SOC-2010)
#
# Outputs:
#   data/cleaned/exposure/exposure_isco08.csv        (4-digit, primary)
#   data/cleaned/exposure/exposure_isco08_3d.csv     (3-digit, fallback)
#   data/cleaned/exposure/crosswalk_diagnostics.csv  (stage-by-stage match rates)
#   data/cleaned/exposure/exposure_isco08.rds        (R-native mirror)
#
# Paper-to-code naming map:
#   alpha   : Eloundou direct exposure         ( alpha  in [0,1] )
#   beta    : Eloundou complementary exposure  ( beta   in [0,1] )
#   zeta    : Upper bound, alpha + beta        ( zeta   in [0,1], strategy memo eq. S2.1 )
#   E_o     : Treatment dose = zeta at ISCO-08 4d
#   isco08_4d / isco08_3d : 4- and 3-digit ISCO-08 codes
# ==============================================================================

# --- Packages (INV-15) --------------------------------------------------------
library(here)
library(data.table)
library(readxl)

# --- Seed (INV-14) ------------------------------------------------------------
set.seed(20260420)

# --- Helper functions ---------------------------------------------------------
source(here::here("scripts", "R", "functions", "build_exposure_map.R"))

# --- Paths (INV-16, INV-18) ---------------------------------------------------
ONET_PATH  <- here::here("data", "raw", "onet", "task_ratings.csv")
XWALK_PATH <- here::here("data", "raw", "crosswalks", "ISCO_SOC_Crosswalk.xls")
OUT_DIR    <- here::here("data", "cleaned", "exposure")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

OUT_4D      <- file.path(OUT_DIR, "exposure_isco08.csv")
OUT_3D      <- file.path(OUT_DIR, "exposure_isco08_3d.csv")
OUT_DIAG    <- file.path(OUT_DIR, "crosswalk_diagnostics.csv")
OUT_RDS     <- file.path(OUT_DIR, "exposure_isco08.rds")

# --- Preconditions ------------------------------------------------------------
check_raw_files(ONET_PATH, XWALK_PATH)

message("[03_build_exposure] Loading Eloundou task ratings...")
tasks <- load_eloundou_scores(ONET_PATH)
stopifnot(nrow(tasks) > 0L)

message(sprintf(
  "  -> %s task rows across %s SOC-2010 occupations.",
  format(nrow(tasks), big.mark = ","),
  format(data.table::uniqueN(tasks$soc_code), big.mark = ",")
))

# --- Stage 1: task -> SOC-6d --------------------------------------------------
message("[03_build_exposure] Aggregating tasks -> SOC-2010 (6-digit)...")
soc <- aggregate_tasks_to_soc(tasks)
assert_range_01(soc$alpha, name = "alpha (SOC level)")
assert_range_01(soc$beta,  name = "beta (SOC level)")
assert_range_01(soc$zeta,  name = "zeta (SOC level)")
stopifnot(data.table::uniqueN(soc$soc_code) == nrow(soc))

n_soc_eloundou <- nrow(soc)
message(sprintf("  -> %s SOC-2010 codes with exposure.", n_soc_eloundou))

# --- Stage 2: load crosswalk --------------------------------------------------
message("[03_build_exposure] Loading ISCO-08 <-> SOC-2010 crosswalk...")
xwalk <- load_isco_soc_crosswalk(XWALK_PATH)
n_xwalk_rows <- nrow(xwalk)
n_xwalk_isco <- data.table::uniqueN(xwalk$isco08_4d)
n_xwalk_soc  <- data.table::uniqueN(xwalk$soc_code)
message(sprintf(
  "  -> %s crosswalk rows: %s ISCO-08 4d codes, %s SOC-2010 codes.",
  format(n_xwalk_rows, big.mark = ","),
  format(n_xwalk_isco, big.mark = ","),
  format(n_xwalk_soc,  big.mark = ",")
))

# --- Stage 3: merge Eloundou SOC scores into the crosswalk --------------------
message("[03_build_exposure] Merging Eloundou SOC scores with crosswalk...")
joined <- crosswalk_soc_to_isco08(soc, xwalk)
n_soc_in_xwalk        <- data.table::uniqueN(xwalk$soc_code)
n_soc_matched         <- data.table::uniqueN(joined[match_soc == TRUE, soc_code])
soc_match_rate        <- n_soc_matched / n_soc_in_xwalk
message(sprintf(
  "  -> SOC match rate: %s / %s = %.1f%%",
  format(n_soc_matched,  big.mark = ","),
  format(n_soc_in_xwalk, big.mark = ","),
  100 * soc_match_rate
))

# --- Stage 4: aggregate to ISCO-08 4-digit ------------------------------------
message("[03_build_exposure] Aggregating SOCs -> ISCO-08 4-digit...")
isco4 <- aggregate_to_isco08(joined)
stopifnot(data.table::uniqueN(isco4$isco08_4d) == nrow(isco4))
assert_range_01(isco4$alpha[!is.na(isco4$alpha)], name = "alpha (ISCO-4d)")
assert_range_01(isco4$beta [!is.na(isco4$beta)],  name = "beta  (ISCO-4d)")
assert_range_01(isco4$zeta [!is.na(isco4$zeta)],  name = "zeta  (ISCO-4d)")

n_isco4_total     <- nrow(isco4)
n_isco4_matched   <- isco4[match_quality != "unmatched", .N]
isco4_match_rate  <- n_isco4_matched / n_isco4_total
message(sprintf(
  "  -> ISCO-08 4d match rate: %s / %s = %.1f%%",
  format(n_isco4_matched, big.mark = ","),
  format(n_isco4_total,   big.mark = ","),
  100 * isco4_match_rate
))
message("  -> match_quality distribution:")
print(isco4[, .N, by = match_quality][order(-N)])

# --- Stage 5: 3-digit fallback ------------------------------------------------
message("[03_build_exposure] Building 3-digit fallback...")
isco3 <- aggregate_to_isco_3d(isco4)

# --- Diagnostics report -------------------------------------------------------
cat("\n================================================================\n")
cat(" DIAGNOSTICS -- GPT Exposure Panel (ISCO-08)\n")
cat("================================================================\n")

cat(sprintf("\nSOC-2010 codes in Eloundou task file : %6s\n",
            format(n_soc_eloundou, big.mark = ",")))
cat(sprintf("SOC-2010 codes in BLS crosswalk      : %6s\n",
            format(n_soc_in_xwalk, big.mark = ",")))
cat(sprintf("SOC-2010 codes matched (Eloundou)    : %6s  (%.1f%%)\n",
            format(n_soc_matched, big.mark = ","), 100 * soc_match_rate))
cat(sprintf("ISCO-08 4-digit codes in crosswalk   : %6s\n",
            format(n_isco4_total, big.mark = ",")))
cat(sprintf("ISCO-08 4-digit matched (>=1 SOC)    : %6s  (%.1f%%)\n",
            format(n_isco4_matched, big.mark = ","), 100 * isco4_match_rate))
cat(sprintf("ISCO-08 3-digit codes                : %6s\n",
            format(nrow(isco3), big.mark = ",")))

# ---- zeta distribution -------------------------------------------------------
zeta_vec <- isco4$zeta[!is.na(isco4$zeta)]
zeta_q   <- quantile(zeta_vec, c(0.25, 0.50, 0.75, 0.90), names = FALSE)
cat("\nDistribution of zeta across ISCO-08 4d (matched codes):\n")
cat(sprintf("  mean = %.3f | median = %.3f | p25 = %.3f | p75 = %.3f | p90 = %.3f\n",
            mean(zeta_vec), zeta_q[2L], zeta_q[1L], zeta_q[3L], zeta_q[4L]))
cat(sprintf("  min  = %.3f | max    = %.3f | n = %d\n",
            min(zeta_vec), max(zeta_vec), length(zeta_vec)))

# ---- top-10 / bottom-10 ------------------------------------------------------
top10    <- isco4[match_quality != "unmatched"][order(-zeta)][1:10,
            .(isco08_4d, isco08_label, zeta, n_onet_soc)]
bottom10 <- isco4[match_quality != "unmatched"][order(zeta)][1:10,
            .(isco08_4d, isco08_label, zeta, n_onet_soc)]

cat("\nTop-10 ISCO-08 4d by zeta (most exposed):\n")
print(top10, row.names = FALSE)
cat("\nBottom-10 ISCO-08 4d by zeta (least exposed):\n")
print(bottom10, row.names = FALSE)

# ---- military (ISCO major group 0) -------------------------------------------
military <- isco4[substr(isco08_4d, 1L, 1L) == "0"]
cat(sprintf("\nMilitary ISCO-08 codes (major group 0): %d (excluded from main analysis, kept for robustness per memo Sec. 10.2).\n",
            nrow(military)))

# ---- unmatched (flagged) -----------------------------------------------------
unmatched <- isco4[match_quality == "unmatched", .(isco08_4d, isco08_label)]
if (nrow(unmatched) > 0L) {
  cat(sprintf("\nUnmatched ISCO-08 4d codes (%d):\n", nrow(unmatched)))
  print(unmatched, row.names = FALSE)
} else {
  cat("\nAll ISCO-08 4-digit codes matched at least one SOC.\n")
}

# --- Diagnostic table ---------------------------------------------------------
diagnostics <- data.table::rbindlist(list(
  diagnostics_row("Eloundou task-level rows",     nrow(tasks),           n_soc_eloundou, NA_real_),
  diagnostics_row("SOCs in Eloundou",             n_soc_eloundou,        n_soc_eloundou, 1),
  diagnostics_row("SOCs in BLS crosswalk",        n_soc_in_xwalk,        n_soc_in_xwalk, 1),
  diagnostics_row("SOCs matched (Eloundou join)", n_soc_in_xwalk,        n_soc_matched,  soc_match_rate),
  diagnostics_row("ISCO-08 4d in crosswalk",      n_xwalk_isco,          n_isco4_total,  1),
  diagnostics_row("ISCO-08 4d matched",           n_isco4_total,         n_isco4_matched, isco4_match_rate),
  diagnostics_row("ISCO-08 3d in output",         nrow(isco3),           nrow(isco3),    1)
))

# --- Write outputs ------------------------------------------------------------
message("\n[03_build_exposure] Writing outputs...")

out4 <- isco4[, .(
  isco08_4d, isco08_label,
  alpha, beta, zeta,
  n_onet_soc, match_quality
)]
data.table::setorder(out4, isco08_4d)
data.table::fwrite(out4, OUT_4D)
saveRDS(out4, OUT_RDS)
message(sprintf("  wrote %s (%d rows)", OUT_4D, nrow(out4)))

out3 <- isco3[, .(
  isco08_3d, alpha, beta, zeta,
  n_isco08_4d, n_matched_4d, match_quality
)]
data.table::setorder(out3, isco08_3d)
data.table::fwrite(out3, OUT_3D)
message(sprintf("  wrote %s (%d rows)", OUT_3D, nrow(out3)))

data.table::fwrite(diagnostics, OUT_DIAG)
message(sprintf("  wrote %s (%d rows)", OUT_DIAG, nrow(diagnostics)))

# --- Final integrity checks ---------------------------------------------------
stopifnot(
  data.table::uniqueN(out4$isco08_4d) == nrow(out4),
  data.table::uniqueN(out3$isco08_3d) == nrow(out3),
  all(is.na(out4$zeta) | (out4$zeta >= 0 & out4$zeta <= 1)),
  all(is.na(out3$zeta) | (out3$zeta >= 0 & out3$zeta <= 1))
)

message("\n[03_build_exposure] Done.\n")
