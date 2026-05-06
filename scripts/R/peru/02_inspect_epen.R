# ==============================================================================
# 02_inspect_epen.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 2 (inspection before harmonization)
#
# Inspects two EPEN files to verify:
#   - Variable names are consistent across the pre/post split (user reports
#     they already harmonized variable names; we double-check).
#   - `c308_cod` is 3-digit in pre files (epe_*) and 4-digit in post (epen_*).
#   - Coverage is Lima Metropolitana only (region == 1).
#   - Sample sizes are stable.
#   - Expansion-factor variable name (varies by quarter: fa_*).
#
# Output: console report only. No .rds saved.
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(haven)
library(data.table)

raw_dir <- here("data", "raw", "peru", "epen_trimestral")
stopifnot(dir.exists(raw_dir))

# --- Helper: inspect one file -------------------------------------------------
inspect_one <- function(filepath) {
  cat("\n", strrep("=", 78), "\n", sep = "")
  cat("FILE:", basename(filepath), "\n")
  cat(strrep("=", 78), "\n", sep = "")

  d <- as.data.table(read_dta(filepath))

  cat(sprintf("  Rows: %d  | Cols: %d\n", nrow(d), ncol(d)))

  # Variable names (lowercase per user's harmonization)
  vnames <- tolower(names(d))
  cat("  Variable names (first 30 of", length(vnames), "):\n")
  print(head(vnames, 30))

  # Look for key variables
  key_vars <- c("anio", "mes", "conglomerado", "selviv", "hogar",
                "region", "c201", "c207", "c208",
                "c308_cod", "c309_cod", "c310", "c311", "c312",
                "c313", "c317", "c318_t", "whorat", "c331",
                "c339_1", "c342", "c364_1", "c364_2", "c364_3",
                "c366", "seguro1", "ocup300",
                "ingtot", "ingtotp", "ingtrabw",
                "i339_1", "i342", "i345_1", "i348")
  present <- key_vars[key_vars %in% vnames]
  missing <- setdiff(key_vars, vnames)
  cat(sprintf("  Key vars present: %d / %d\n", length(present), length(key_vars)))
  if (length(missing) > 0) {
    cat("  MISSING:", paste(missing, collapse = ", "), "\n")
  }

  # Expansion factor (name varies by quarter: fa_<ond|jas|amj|efm><yy>)
  fa_cols <- grep("^fa_", vnames, value = TRUE)
  cat("  Expansion factor candidates (fa_*):", paste(fa_cols, collapse = ", "), "\n")

  # Region distribution (should be predominantly 1 = Lima Metropolitana)
  if ("region" %in% vnames) {
    setnames(d, names(d), tolower(names(d)))
    cat("  region distribution:\n")
    print(d[, .N, by = region][order(region)])
  }

  # c308_cod inspection: digit count
  if ("c308_cod" %in% vnames) {
    setnames(d, names(d), tolower(names(d)))
    occ <- d$c308_cod
    occ_nonmiss <- occ[!is.na(occ) & occ != 9999 & occ != 999]
    if (length(occ_nonmiss) > 0) {
      ndigits <- nchar(as.character(as.integer(occ_nonmiss)))
      cat("  c308_cod non-missing N:", length(occ_nonmiss), "\n")
      cat("  c308_cod digit-count distribution:\n")
      print(table(ndigits))
      cat("  c308_cod sample values (first 10 unique):\n")
      print(head(unique(occ_nonmiss), 10))
      cat(sprintf("  c308_cod range: [%d, %d]\n",
                  min(occ_nonmiss), max(occ_nonmiss)))
    }
  }

  # Quick label peek on one variable to confirm haven labels are intact
  if ("c207" %in% vnames) {
    setnames(d, names(d), tolower(names(d)))
    cat("  c207 (sex) distribution:\n")
    print(d[, .N, by = c207][order(c207)])
  }

  invisible(NULL)
}

# --- Inspect one PRE and one POST file ---------------------------------------
file_pre  <- file.path(raw_dir, "2021", "epe_q1_2021.dta")
file_post <- file.path(raw_dir, "2022", "epen_q4_2022.dta")

stopifnot(file.exists(file_pre), file.exists(file_post))

cat("\n#### PRE file (CO-1995 3d expected) ####\n")
inspect_one(file_pre)

cat("\n\n#### POST file (CNO-2015 4d expected) ####\n")
inspect_one(file_post)

# --- Loop: sample sizes across all quarters ----------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("SAMPLE SIZES BY QUARTER\n")
cat(strrep("=", 78), "\n", sep = "")

all_files <- list.files(raw_dir, pattern = "\\.dta$", recursive = TRUE,
                        full.names = TRUE)
all_files <- all_files[!grepl("/Anual", all_files)]  # in case any annual file

summary_dt <- rbindlist(lapply(all_files, function(f) {
  d <- as.data.table(read_dta(f))
  setnames(d, names(d), tolower(names(d)))
  fa_cols <- grep("^fa_", names(d), value = TRUE)
  fa_var  <- if (length(fa_cols) > 0) fa_cols[1] else NA_character_
  fa_sum  <- if (!is.na(fa_var)) sum(d[[fa_var]], na.rm = TRUE) else NA_real_
  data.table(
    file        = basename(f),
    classifier  = if (grepl("^epe_", basename(f))) "CO-1995 (3d)" else "CNO-2015 (4d)",
    n_rows      = nrow(d),
    fa_var      = fa_var,
    fa_total    = fa_sum
  )
}))
print(summary_dt)

cat("\n[DONE] Inspection complete.\n")
