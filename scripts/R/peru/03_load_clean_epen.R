# ==============================================================================
# 03_load_clean_epen.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 3 (clean and concatenate EPEN)
#
# Loads the 20 EPEN .dta files (2021Q1 to 2025Q4), harmonizes variable names
# to lowercase, parses quarter from filename, builds derived variables, and
# filters to working-age employed in Lima Metropolitana. Output is a single
# long-format panel of one row per worker-quarter, with the raw occupational
# code (3-digit CO-1995 in pre, 4-digit CNO-2015 in post) preserved for the
# harmonization step in Phase 4.
#
# Key decisions (confirmed with user):
#   - Formal indicator: seguro1 in {1, 3}  (ESSALUD or ESSALUD+private)
#   - Hours variable:   whorat              (weekly total)
#   - Wage variable:    ingtotp / (whorat * 4.33)  (hourly real wage)
#   - Education:        5 categories collapsed from c366 (12 cats)
#   - Sample:           ocup300 == 1 AND age in [14, 65]
#
# Output: data/cleaned/peru/epen_long_classified.rds
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(haven)
library(data.table)
library(stringr)

raw_dir <- here("data", "raw", "peru", "epen_trimestral")
out_dir <- here("data", "cleaned", "peru")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# --- Helper: education collapse (12 cats -> 5) -------------------------------
# c366 codes per Diccionario:
#   1 = Sin nivel              -> "sin"
#   2 = Educación inicial      -> "sin"
#   3 = Primaria incompleta    -> "primaria"
#   4 = Primaria completa      -> "primaria"
#   5 = Secundaria incompleta  -> "secundaria"
#   6 = Secundaria completa    -> "secundaria"
#   7 = Básica especial        -> "secundaria"
#   8 = Superior no-univ inc.  -> "no_univ"
#   9 = Superior no-univ comp. -> "no_univ"
#  10 = Superior univ. inc.    -> "universitaria"
#  11 = Superior univ. comp.   -> "universitaria"
#  12 = Maestría/Doctorado     -> "universitaria"
educ5_map <- function(x) {
  fcase(
    x %in% c(1, 2),       "sin",
    x %in% c(3, 4),       "primaria",
    x %in% c(5, 6, 7),    "secundaria",
    x %in% c(8, 9),       "no_univ",
    x %in% c(10, 11, 12), "universitaria",
    default = NA_character_
  )
}

# --- Helper: parse quarter from filename --------------------------------------
parse_quarter <- function(fname) {
  year <- as.integer(str_extract(fname, "20[0-9]{2}"))
  qtr  <- as.integer(str_extract(fname, "q([1-4])", group = 1))
  list(year = year, quarter = qtr)
}

# --- Helper: clean one file ---------------------------------------------------
clean_one <- function(filepath) {
  fname <- basename(filepath)
  pq <- parse_quarter(fname)

  d <- as.data.table(read_dta(filepath))
  setnames(d, names(d), tolower(names(d)))

  # Find expansion factor (varies by quarter: fa_efm22, fa_ond23, etc.)
  fa_col <- grep("^fa_", names(d), value = TRUE)[1]
  if (is.na(fa_col)) stop("No expansion-factor column in ", fname)

  # Convert haven_labelled to plain numeric where needed
  to_num <- function(x) as.numeric(haven::zap_labels(x))

  out <- data.table(
    year         = pq$year,
    quarter      = pq$quarter,
    yearqtr      = pq$year + (pq$quarter - 1) / 4,

    # Survey IDs (uniqueness check downstream)
    conglomerado = as.character(d$conglomerado),
    selviv       = as.character(d$selviv),
    hogar        = to_num(d$hogar),
    persona      = to_num(d$c201),

    # Demographics
    age          = to_num(d$c208),
    sex_raw      = to_num(d$c207),
    educ_raw     = to_num(d$c366),

    # Occupation: raw code (3d in pre, 4d in post)
    occ_raw      = to_num(d$c308_cod),
    sector_raw   = to_num(d$c309_cod),

    # Activity status
    ocup300      = to_num(d$ocup300),

    # Outcome variables
    hours        = to_num(d$whorat),
    income_main  = to_num(d$ingtotp),

    # Formality proxy
    seguro1      = to_num(d$seguro1),

    # Other useful for robustness
    occ_category = to_num(d$c310),
    employer_typ = to_num(d$c311),

    # Weight
    weight       = to_num(d[[fa_col]])
  )

  # Mark classifier vintage
  out[, classifier := ifelse(year < 2022 | (year == 2022 & quarter <= 3),
                             "CO1995_3d", "CNO2015_4d")]

  # Derived variables
  out[, female     := as.integer(sex_raw == 2)]
  out[, age2       := age * age]
  out[, educ5      := educ5_map(educ_raw)]
  out[, is_formal  := as.integer(seguro1 %in% c(1, 3))]

  # Sector ISIC 1-digit (first digit of c309_cod)
  out[, sector_1d  := substr(formatC(as.integer(sector_raw), width = 4,
                                     format = "d", flag = "0"), 1, 1)]
  out[sector_raw == 9999 | is.na(sector_raw), sector_1d := NA_character_]

  # Hourly wage (Soles per hour, nominal)
  # Monthly income / (weekly hours * 4.33 weeks/month)
  out[, wage_hour := income_main / (hours * 4.33)]
  out[hours == 0 | is.na(hours), wage_hour := NA_real_]
  out[income_main == 999999, wage_hour := NA_real_]
  out[wage_hour <= 0, wage_hour := NA_real_]
  out[, log_wage_hour := log(wage_hour)]

  # Source file (audit trail)
  out[, src_file := fname]

  out[]
}

# --- Process all files --------------------------------------------------------
files <- list.files(raw_dir, pattern = "\\.dta$", recursive = TRUE,
                    full.names = TRUE)
files <- files[!grepl("/Anual/", files)]
cat(sprintf("Processing %d EPEN files ...\n", length(files)))

panel <- rbindlist(lapply(files, function(f) {
  cat("  ", basename(f), "\n", sep = "")
  clean_one(f)
}), fill = TRUE)

cat(sprintf("\nRaw stacked panel: %d rows\n", nrow(panel)))

# --- Apply analysis-sample filters --------------------------------------------
# Keep employed (ocup300 == 1), working-age (14-65), with valid occupation code
n_total       <- nrow(panel)
n_ocupado     <- sum(panel$ocup300 == 1, na.rm = TRUE)
n_age_ok      <- sum(panel$ocup300 == 1 & panel$age >= 14 & panel$age <= 65,
                     na.rm = TRUE)
n_occ_valid   <- sum(panel$ocup300 == 1 & panel$age >= 14 & panel$age <= 65 &
                     !is.na(panel$occ_raw) & panel$occ_raw != 9999 &
                     panel$occ_raw != 999, na.rm = TRUE)

cat(sprintf("  total rows           %d\n", n_total))
cat(sprintf("  ocupados             %d (%.1f%%)\n",
            n_ocupado, 100 * n_ocupado / n_total))
cat(sprintf("  ocupados, age 14-65  %d (%.1f%%)\n",
            n_age_ok, 100 * n_age_ok / n_total))
cat(sprintf("  + valid occ_raw      %d (%.1f%%)\n",
            n_occ_valid, 100 * n_occ_valid / n_total))

panel_clean <- panel[ocup300 == 1 &
                       age >= 14 & age <= 65 &
                       !is.na(occ_raw) & occ_raw != 9999 & occ_raw != 999]

# --- Validate digit-count by classifier vintage ------------------------------
panel_clean[, occ_digits := nchar(formatC(as.integer(occ_raw), format = "d"))]
cat("\nOccupation digit-count distribution by classifier vintage:\n")
print(panel_clean[, .N, by = .(classifier, occ_digits)][
        order(classifier, occ_digits)])

# --- Quarterly summary --------------------------------------------------------
cat("\nQuarterly sample sizes (post analysis-filter):\n")
qsumm <- panel_clean[, .(
  n_obs        = .N,
  n_expanded   = sum(weight, na.rm = TRUE),
  classifier   = first(classifier),
  pct_formal   = mean(is_formal, na.rm = TRUE) * 100,
  mean_hours   = mean(hours, na.rm = TRUE),
  mean_log_wage = mean(log_wage_hour, na.rm = TRUE)
), by = .(year, quarter)][order(year, quarter)]
print(qsumm)

# --- Save ---------------------------------------------------------------------
saveRDS(panel_clean, file.path(out_dir, "epen_long_classified.rds"))
cat(sprintf("\n[DONE] Panel saved: %s\n",
            file.path(out_dir, "epen_long_classified.rds")))
cat(sprintf("       Rows: %d  | Workers-quarters\n", nrow(panel_clean)))
