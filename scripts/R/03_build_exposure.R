# ==============================================================================
# 03_build_exposure.R
# Build the occupational GPT-exposure panel at the ISCO-08 4-digit level.
# Paper : Torres (2026) -- Gen AI & LAC Labor Markets, Paper 1, Section 2.1
# Memo  : quality_reports/strategy_memo_genai_lac.md -- Sec. 1.2, 2.1, 8.4
#
# Inputs:
#   data/raw/onet/task_ratings.csv                      (Eloundou 2023, task-level)
#   data/raw/crosswalks/ISCO_SOC_Crosswalk.xls          (BLS ISCO-08 <-> SOC-2010)
#   data/raw/crosswalks/soc_2010_to_2018_crosswalk.xlsx (BLS SOC-2010 <-> 2018;
#                                                        auto-fetched on first run)
#
# Outputs:
#   data/cleaned/exposure/exposure_isco08.csv          (4-digit, primary)
#   data/cleaned/exposure/exposure_isco08.rds
#   data/cleaned/exposure/exposure_isco08_3d.csv       (3-digit, fallback)
#   data/cleaned/exposure/exposure_isco08_3d.rds
#   data/cleaned/exposure/crosswalk_diagnostics.csv    (stage-by-stage match rates)
#   data/cleaned/exposure/crosswalk_diagnostics.rds
#
# Paper-to-code naming map:
#   alpha   : Eloundou direct exposure           ( alpha in [0,1] )
#   beta    : Eloundou complementary exposure    ( beta  in [0,1] )
#   zeta    : Upper bound, alpha + beta          ( zeta  in [0,1], memo eq. S2.1 )
#   gamma   : Eloundou alternative rubric        ( gamma in [0,1], robustness )
#   E_o     : Treatment dose = zeta at ISCO-08 4d
#   isco08_4d / isco08_3d : 4- and 3-digit ISCO-08 codes
#   soc_vintage : provenance tag for the SOC side of the crosswalk;
#                 either "SOC-2010" (Eloundou already SOC-2010) or
#                 "SOC-2018 bridged to SOC-2010" (Eloundou SOC-2018 mapped via
#                 BLS 2010->2018 bridge).
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
ONET_PATH       <- here::here("data", "raw", "onet", "task_ratings.csv")
XWALK_PATH      <- here::here("data", "raw", "crosswalks", "ISCO_SOC_Crosswalk.xls")
SOC_BRIDGE_PATH <- here::here("data", "raw", "crosswalks",
                              "soc_2010_to_2018_crosswalk.xlsx")
OUT_DIR         <- here::here("data", "cleaned", "exposure")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

OUT_4D          <- file.path(OUT_DIR, "exposure_isco08.csv")
OUT_4D_RDS      <- file.path(OUT_DIR, "exposure_isco08.rds")
OUT_3D          <- file.path(OUT_DIR, "exposure_isco08_3d.csv")
OUT_3D_RDS      <- file.path(OUT_DIR, "exposure_isco08_3d.rds")
OUT_DIAG        <- file.path(OUT_DIR, "crosswalk_diagnostics.csv")
OUT_DIAG_RDS    <- file.path(OUT_DIR, "crosswalk_diagnostics.rds")

# --- Preconditions ------------------------------------------------------------
check_raw_files(ONET_PATH, XWALK_PATH)

message("[03_build_exposure] Loading Eloundou task ratings...")
tasks <- load_eloundou_scores(ONET_PATH)
stopifnot(nrow(tasks) > 0L)

message(sprintf(
  "  -> %s task rows across %s SOC occupations.",
  format(nrow(tasks), big.mark = ","),
  format(data.table::uniqueN(tasks$soc_code), big.mark = ",")
))

# --- Stage 1: task -> SOC-6d --------------------------------------------------
message("[03_build_exposure] Aggregating tasks -> SOC (6-digit)...")
soc <- aggregate_tasks_to_soc(tasks)
assert_range_01(soc$alpha, name = "alpha (SOC level)")
assert_range_01(soc$beta,  name = "beta (SOC level)")
assert_range_01(soc$zeta,  name = "zeta (SOC level)")
assert_range_01(soc$gamma, name = "gamma (SOC level)")
stopifnot(data.table::uniqueN(soc$soc_code) == nrow(soc))

n_soc_eloundou <- nrow(soc)
message(sprintf("  -> %s SOC codes with exposure.", n_soc_eloundou))

# --- Stage 1b: detect SOC vintage and bridge if needed ------------------------
# Fix #1 (critical): Eloundou 2023 publishes against O*NET-SOC 2019 (SOC-2018
# derivative); the BLS ISCO<->SOC crosswalk keys on SOC-2010.  We detect the
# Eloundou vintage from ICT anchor codes and, if SOC-2018, bridge to SOC-2010
# before merging with the ISCO crosswalk.  Without this step the entire
# 15-1XXX ICT block (software developers, systems analysts, web developers)
# drops out, producing a non-random 44-cell gap in the ISCO-08 4d panel.

eloundou_soc_vintage <- detect_soc_vintage(soc$soc_code)
message(sprintf(
  "[03_build_exposure] Detected Eloundou SOC vintage: %s",
  eloundou_soc_vintage
))

n_bridge_dropped  <- 0L
n_bridge_expanded <- 0L
n_bridge_merged   <- 0L
soc_vintage_label <- "SOC-2010"

if (eloundou_soc_vintage == "SOC-2018") {
  message("[03_build_exposure] Ensuring SOC 2010->2018 bridge is cached...")
  ensure_soc_2010_to_2018_bridge(SOC_BRIDGE_PATH)

  bridge <- load_soc_2010_to_2018_bridge(SOC_BRIDGE_PATH)
  message(sprintf(
    "  -> bridge has %s rows mapping %s SOC-2010 <-> %s SOC-2018 codes.",
    format(nrow(bridge), big.mark = ","),
    format(data.table::uniqueN(bridge$soc_2010), big.mark = ","),
    format(data.table::uniqueN(bridge$soc_2018), big.mark = ",")
  ))

  bridged <- bridge_soc_2018_to_2010(soc, bridge)
  soc <- bridged$soc_2010
  n_bridge_dropped  <- bridged$n_dropped
  n_bridge_expanded <- bridged$n_expanded
  n_bridge_merged   <- bridged$n_merged
  soc_vintage_label <- "SOC-2018 bridged to SOC-2010"

  message(sprintf(
    "  -> bridged: %s SOC-2010 rows produced (%d expansions, %d merges, %d dropped).",
    format(nrow(soc), big.mark = ","),
    n_bridge_expanded, n_bridge_merged, n_bridge_dropped
  ))

  # Post-bridge guards.
  assert_range_01(soc$alpha, name = "alpha (bridged SOC-2010)")
  assert_range_01(soc$beta,  name = "beta  (bridged SOC-2010)")
  assert_range_01(soc$zeta,  name = "zeta  (bridged SOC-2010)")
  assert_range_01(soc$gamma, name = "gamma (bridged SOC-2010)")
  stopifnot(data.table::uniqueN(soc$soc_code) == nrow(soc))
}

n_soc_for_merge <- nrow(soc)

# --- Stage 2: load ISCO <-> SOC-2010 crosswalk --------------------------------
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

# --- Stage 3: merge SOC scores into the crosswalk -----------------------------
message("[03_build_exposure] Merging SOC scores with ISCO crosswalk...")
joined <- crosswalk_soc_to_isco08(soc, xwalk)
n_soc_in_xwalk <- data.table::uniqueN(xwalk$soc_code)
n_soc_matched  <- data.table::uniqueN(joined[match_soc == TRUE, soc_code])
soc_match_rate <- n_soc_matched / n_soc_in_xwalk
message(sprintf(
  "  -> SOC match rate (in ISCO crosswalk): %s / %s = %.1f%%",
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
if ("gamma" %in% names(isco4)) {
  assert_range_01(isco4$gamma[!is.na(isco4$gamma)], name = "gamma (ISCO-4d)")
}

n_isco4_total     <- nrow(isco4)
n_isco4_matched   <- isco4[match_quality != "unmatched", .N]
isco4_match_rate  <- n_isco4_matched / n_isco4_total
n_isco4_partial   <- isco4[any_partial == TRUE, .N]
message(sprintf(
  "  -> ISCO-08 4d match rate: %s / %s = %.1f%%",
  format(n_isco4_matched, big.mark = ","),
  format(n_isco4_total,   big.mark = ","),
  100 * isco4_match_rate
))
message(sprintf(
  "  -> ISCO-08 4d cells with any_partial = TRUE (SOC split across ISCOs): %d",
  n_isco4_partial
))
message("  -> match_quality distribution:")
print(isco4[, .N, by = match_quality][order(-N)])

# --- Stage 5: 3-digit fallback ------------------------------------------------
message("[03_build_exposure] Building 3-digit fallback...")
isco3 <- aggregate_to_isco_3d(isco4)

# --- Diagnostics report (R2: message() everywhere) ----------------------------
message("\n================================================================")
message(" DIAGNOSTICS -- GPT Exposure Panel (ISCO-08)")
message("================================================================")

message(sprintf("Eloundou SOC vintage detected        : %s", eloundou_soc_vintage))
message(sprintf("Exposure soc_vintage label (output)  : %s", soc_vintage_label))
message(sprintf("SOC codes in Eloundou task file      : %6s",
                format(n_soc_eloundou, big.mark = ",")))
if (eloundou_soc_vintage == "SOC-2018") {
  message(sprintf(
    "Bridge summary                       : %d expansions, %d merges, %d dropped",
    n_bridge_expanded, n_bridge_merged, n_bridge_dropped))
  message(sprintf("SOC-2010 rows after bridging         : %6s",
                  format(n_soc_for_merge, big.mark = ",")))
}
message(sprintf("SOC-2010 codes in BLS ISCO xwalk     : %6s",
                format(n_soc_in_xwalk, big.mark = ",")))
message(sprintf("SOC-2010 codes matched (Eloundou)    : %6s  (%.1f%%)",
                format(n_soc_matched, big.mark = ","), 100 * soc_match_rate))
message(sprintf("ISCO-08 4-digit codes in xwalk       : %6s",
                format(n_isco4_total, big.mark = ",")))
message(sprintf("ISCO-08 4-digit matched (>=1 SOC)    : %6s  (%.1f%%)",
                format(n_isco4_matched, big.mark = ","), 100 * isco4_match_rate))
message(sprintf("ISCO-08 4d cells with partial SOC    : %6d", n_isco4_partial))
message(sprintf("ISCO-08 3-digit codes                : %6s",
                format(nrow(isco3), big.mark = ",")))

# ---- zeta distribution -------------------------------------------------------
zeta_vec <- isco4$zeta[!is.na(isco4$zeta)]
zeta_q   <- stats::quantile(zeta_vec, c(0.25, 0.50, 0.75, 0.90), names = FALSE)
message("\nDistribution of zeta across ISCO-08 4d (matched codes):")
message(sprintf("  mean = %.3f | median = %.3f | p25 = %.3f | p75 = %.3f | p90 = %.3f",
                mean(zeta_vec), zeta_q[2L], zeta_q[1L], zeta_q[3L], zeta_q[4L]))
message(sprintf("  min  = %.3f | max    = %.3f | n = %d",
                min(zeta_vec), max(zeta_vec), length(zeta_vec)))

# ---- top-10 / bottom-10 ------------------------------------------------------
top10    <- isco4[match_quality != "unmatched"][order(-zeta)][
              seq_len(10L), .(isco08_4d, isco08_label, zeta, n_onet_soc)]
bottom10 <- isco4[match_quality != "unmatched"][order(zeta)][
              seq_len(10L), .(isco08_4d, isco08_label, zeta, n_onet_soc)]

message("\nTop-10 ISCO-08 4d by zeta (most exposed):")
print(top10, row.names = FALSE)
message("\nBottom-10 ISCO-08 4d by zeta (least exposed):")
print(bottom10, row.names = FALSE)

# ---- ICT validation probe (fix #1 acceptance test) ---------------------------
ict_probes <- c("2511" = "Systems Analysts",
                "2512" = "Software Developers",
                "2513" = "Web/Multimedia Developers",
                "2514" = "Applications Programmers",
                "2211" = "Generalist Medical Practitioners",
                "2212" = "Specialist Medical Practitioners")
probe_tbl <- isco4[isco08_4d %in% names(ict_probes),
                   .(isco08_4d, isco08_label, zeta, match_quality, n_onet_soc)]
message("\nICT/medical recovery probe (post-bridge expectation: all matched):")
print(probe_tbl, row.names = FALSE)

# ---- military (ISCO major group 0) -------------------------------------------
military <- isco4[substr(isco08_4d, 1L, 1L) == "0"]
message(sprintf(
  "\nMilitary ISCO-08 codes (major group 0): %d (excluded from main analysis, kept for robustness per memo Sec. 10.2).",
  nrow(military)))

# ---- unmatched (flagged) -----------------------------------------------------
unmatched <- isco4[match_quality == "unmatched", .(isco08_4d, isco08_label)]
if (nrow(unmatched) > 0L) {
  message(sprintf("\nUnmatched ISCO-08 4d codes (%d):", nrow(unmatched)))
  print(unmatched, row.names = FALSE)
} else {
  message("\nAll ISCO-08 4-digit codes matched at least one SOC.")
}

# --- Diagnostic table ---------------------------------------------------------
diagnostics <- data.table::rbindlist(list(
  diagnostics_row("Eloundou task-level rows",        nrow(tasks),      n_soc_eloundou,  NA_real_),
  diagnostics_row("SOCs in Eloundou",                n_soc_eloundou,   n_soc_eloundou,  1),
  diagnostics_row("SOCs after vintage bridge",       n_soc_eloundou,   n_soc_for_merge, NA_real_),
  diagnostics_row("SOCs in BLS ISCO crosswalk",      n_soc_in_xwalk,   n_soc_in_xwalk,  1),
  diagnostics_row("SOCs matched (Eloundou join)",    n_soc_in_xwalk,   n_soc_matched,   soc_match_rate),
  diagnostics_row("ISCO-08 4d in crosswalk",         n_xwalk_isco,     n_isco4_total,   1),
  diagnostics_row("ISCO-08 4d matched",              n_isco4_total,    n_isco4_matched, isco4_match_rate),
  diagnostics_row("ISCO-08 4d cells with partial",   n_isco4_total,    n_isco4_partial, NA_real_),
  diagnostics_row("ISCO-08 3d in output",            nrow(isco3),      nrow(isco3),     1)
))
diagnostics[, soc_vintage := soc_vintage_label]

# --- Write outputs ------------------------------------------------------------
message("\n[03_build_exposure] Writing outputs...")

out4_cols <- c("isco08_4d", "isco08_label",
               "alpha", "beta", "zeta",
               if ("gamma" %in% names(isco4)) "gamma",
               "n_onet_soc", "any_partial", "match_quality")
out4 <- isco4[, ..out4_cols]
out4[, soc_vintage := soc_vintage_label]
data.table::setorder(out4, isco08_4d)
data.table::fwrite(out4, OUT_4D)
saveRDS(out4, OUT_4D_RDS)
message(sprintf("  wrote %s (%d rows)", OUT_4D,     nrow(out4)))
message(sprintf("  wrote %s (%d rows)", OUT_4D_RDS, nrow(out4)))

out3_cols <- c("isco08_3d",
               "alpha", "beta", "zeta",
               if ("gamma" %in% names(isco3)) "gamma",
               "n_isco08_4d", "n_matched_4d", "match_quality")
out3 <- isco3[, ..out3_cols]
out3[, soc_vintage := soc_vintage_label]
data.table::setorder(out3, isco08_3d)
data.table::fwrite(out3, OUT_3D)
saveRDS(out3, OUT_3D_RDS)
message(sprintf("  wrote %s (%d rows)", OUT_3D,     nrow(out3)))
message(sprintf("  wrote %s (%d rows)", OUT_3D_RDS, nrow(out3)))

data.table::fwrite(diagnostics, OUT_DIAG)
saveRDS(diagnostics, OUT_DIAG_RDS)
message(sprintf("  wrote %s (%d rows)", OUT_DIAG,     nrow(diagnostics)))
message(sprintf("  wrote %s (%d rows)", OUT_DIAG_RDS, nrow(diagnostics)))

# --- Final integrity checks ---------------------------------------------------
stopifnot(
  data.table::uniqueN(out4$isco08_4d) == nrow(out4),
  data.table::uniqueN(out3$isco08_3d) == nrow(out3),
  all(is.na(out4$zeta) | (out4$zeta >= 0 & out4$zeta <= 1)),
  all(is.na(out3$zeta) | (out3$zeta >= 0 & out3$zeta <= 1)),
  !is.null(out4$soc_vintage),
  !is.null(out3$soc_vintage)
)

message("\n[03_build_exposure] Done.\n")
