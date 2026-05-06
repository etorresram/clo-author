# ==============================================================================
# 16_enaho_validation.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 16 (ENAHO national-level validation)
#
# Validates the EPEN findings using the annual ENAHO module 500 (2021-2025).
# Three advantages over EPEN trimestral:
#   1. National coverage (not just Lima Metropolitana).
#   2. CNO-2015 4d available from 2021 (no harmonization needed).
#   3. ILO-standard formality definition via pension affiliation.
#
# Key trade-off: annual frequency. We have 5 yearly observations:
#   2021 = pre        (clean)
#   2022 = buffer     (mostly pre, ChatGPT launched 30 Nov 2022)  — DROPPED
#   2023, 2024, 2025  = post
#
# Specifications:
#   1. TWFE continuous   y = tau * (beta * post) + alpha_o + alpha_t + e
#   2. Interaction with formality (Design 1 of Phase 12), now using ILO formality
#
# Output:
#   data/cleaned/peru/enaho_validation.rds
# ==============================================================================

library(here)
library(haven)
library(data.table)
library(fixest)

raw_dir <- here("data", "raw", "peru", "enaho_anual")
out_dir <- here("data", "cleaned", "peru")
exp_dir <- here("data", "cleaned", "exposure")

# --- Load all 5 years of ENAHO module 500 ------------------------------------
load_year <- function(year) {
  f <- list.files(file.path(raw_dir, as.character(year)),
                  pattern = "enaho01a-.*-500\\.dta$", full.names = TRUE)[1]
  d <- as.data.table(read_dta(f))
  setnames(d, names(d), tolower(names(d)))
  cat(sprintf("  %d: %d rows, %d cols\n", year, nrow(d), ncol(d)))

  # Formality: prefer INEI-official ocupinf when available; reconstruct
  # otherwise using the documented INEI methodology approximated with
  # the variables available in module 500.
  if ("ocupinf" %in% names(d)) {
    inf_raw <- haven::zap_labels(d$ocupinf)
    # Per INEI labels: 1 = empleo informal, 2 = empleo formal
    is_formal <- as.integer(inf_raw == 2)
    formality_source <- "ocupinf"
  } else {
    # Proxy reconstruction (2024-2025):
    # Wage worker (p507 in {3,4} = empleado/obrero) AND contributes to pension
    # OR
    # Self-employed (p507 in {1,2}) AND firm registered in SUNAT (p510a1 in {1,2})
    # AND keeps accounting books (p510b == 1)
    pos <- haven::zap_labels(d$p507)
    pension <- as.integer(haven::zap_labels(d$p558a1) == 1 |
                          haven::zap_labels(d$p558a2) == 1 |
                          haven::zap_labels(d$p558a3) == 1 |
                          haven::zap_labels(d$p558a4) == 1)
    pension[is.na(pension)] <- 0L
    sunat <- as.integer(haven::zap_labels(d$p510a1) %in% c(1, 2))
    books <- as.integer(haven::zap_labels(d$p510b) == 1)
    is_formal <- as.integer(
      (pos %in% c(3, 4) & pension == 1) |
      (pos %in% c(1, 2) & sunat == 1   & books == 1)
    )
    formality_source <- "proxy"
  }

  d[, is_formal := is_formal]
  d[, formality_source := formality_source]

  d[, .(
    year       = year,
    formality_source = formality_source,
    conglome   = as.character(conglome),
    vivienda   = as.character(vivienda),
    hogar      = as.numeric(haven::zap_labels(hogar)),
    codperso   = as.numeric(haven::zap_labels(codperso)),
    age        = as.numeric(haven::zap_labels(get("p208a", inherits = FALSE))),
    occ_cno    = as.numeric(haven::zap_labels(p505r4)),
    sector     = as.numeric(haven::zap_labels(p506r4)),
    ocu500     = as.numeric(haven::zap_labels(ocu500)),
    is_formal  = is_formal,
    income     = as.numeric(haven::zap_labels(i524a1)),
    fac500a    = as.numeric(haven::zap_labels(fac500a))
  )]
}

cat("Loading ENAHO module 500 by year:\n")
panel <- rbindlist(lapply(2021:2025, load_year), fill = TRUE)
cat(sprintf("\nTotal pooled rows: %d\n", nrow(panel)))

# --- Build derived variables --------------------------------------------------
panel[, code_cno := formatC(as.integer(occ_cno), width = 4, format = "d", flag = "0")]
panel[is.na(is_formal), is_formal := 0L]

cat("\nFormality coverage by year (source = ocupinf or proxy):\n")
print(panel[, .(n = .N,
                pct_formal_INEI = 100 * mean(is_formal, na.rm = TRUE),
                source = first(formality_source)),
            by = year][order(year)])

# Treatment indicators
panel[, post := as.integer(year >= 2023)]
panel[, t_index := as.integer(year - 2020)]    # 1..5
panel[, weight := fac500a]

# --- Filter to analysis sample -----------------------------------------------
panel_analysis <- panel[ocu500 == 1 & !is.na(occ_cno) & occ_cno > 0 &
                        !is.na(income) & income > 0 & age >= 14 & age <= 65]
cat(sprintf("\nWorkers ocupados, edad 14-65, occ_cno valido: %d\n",
            nrow(panel_analysis)))

# Yearly summary BEFORE estimation
cat("\nYearly summary (national):\n")
yr <- panel_analysis[, .(
  n         = .N,
  emp_total = sum(weight, na.rm = TRUE),
  pct_formal_ilo = 100 * weighted.mean(is_formal, w = weight, na.rm = TRUE),
  income_mean    = weighted.mean(income, w = weight, na.rm = TRUE)
), by = year][order(year)]
print(yr)

# --- Merge GPT exposure -------------------------------------------------------
exp4 <- fread(file.path(exp_dir, "exposure_isco08.csv"))
exp4[, isco08_4d := formatC(as.integer(isco08_4d), width = 4,
                            format = "d", flag = "0")]
exp4_keep <- exp4[, .(code_cno = isco08_4d, beta)]

panel_analysis <- merge(panel_analysis, exp4_keep, by = "code_cno", all.x = TRUE)
cat(sprintf("\nWorkers with valid beta: %d (%.1f%%)\n",
            sum(!is.na(panel_analysis$beta)),
            100 * mean(!is.na(panel_analysis$beta))))

# --- Aggregate to (CNO, year) cells -------------------------------------------
panel_valid <- panel_analysis[!is.na(beta) & !is.na(weight)]
panel_valid[, log_income := log(income)]

cells <- panel_valid[, .(
  n_workers      = .N,
  employment     = sum(weight, na.rm = TRUE),
  log_employment = log(sum(weight, na.rm = TRUE)),
  mean_log_wage  = weighted.mean(log_income, w = weight, na.rm = TRUE),
  share_formal   = weighted.mean(is_formal, w = weight, na.rm = TRUE),
  beta           = first(beta),
  post           = first(post)
), by = .(code_cno, year)]

# Filters
MIN_N <- 30L
cells_kept <- cells[n_workers >= MIN_N]
cells_kept[, t_index := as.integer(year - 2020)]
cat(sprintf("\nCells before filter: %d  | after n>=%d: %d\n",
            nrow(cells), MIN_N, nrow(cells_kept)))
cat(sprintf("Distinct CNO codes kept: %d\n", uniqueN(cells_kept$code_cno)))

# Drop 2022 buffer
cells_main <- cells_kept[year != 2022]
cat(sprintf("After dropping 2022 buffer: %d cells\n", nrow(cells_main)))

# Balance: CNO codes must have at least 1 pre AND 1 post quarter
balance <- cells_main[, .(n_pre  = sum(year == 2021),
                          n_post = sum(year >= 2023)), by = code_cno]
codes_keep <- balance[n_pre >= 1 & n_post >= 1, code_cno]
cells_main <- cells_main[code_cno %in% codes_keep]
cat(sprintf("After balance filter: %d cells, %d CNO codes\n",
            nrow(cells_main), uniqueN(cells_main$code_cno)))

# --- Compute baseline F^2021 (CNO-level) per ILO formality -------------------
F_o <- cells_main[year == 2021, .(F_o_2021 = first(share_formal)), by = code_cno]
cells_main <- merge(cells_main, F_o, by = "code_cno")

# --- Estimation 1: Continuous TWFE -------------------------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("ENAHO ANNUAL — TWFE continuous (national, ILO formality)\n")
cat(strrep("=", 78), "\n", sep = "")

run_twfe <- function(outcome) {
  fml <- as.formula(sprintf("%s ~ I(beta * post) | code_cno + year", outcome))
  feols(fml, data = cells_main, weights = ~employment,
        cluster = ~code_cno, notes = FALSE)
}
res1 <- list(
  log_employment = run_twfe("log_employment"),
  mean_log_wage  = run_twfe("mean_log_wage")
)
etable(res1, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

# --- Estimation 2: Heterogeneity by ILO formality ---------------------------
cat("\n", strrep("=", 78), "\n", sep = "")
cat("ENAHO ANNUAL — Heterogeneity by ILO formality (interactuated)\n")
cat(strrep("=", 78), "\n", sep = "")

cells_main[, x_F := beta * post * F_o_2021]
cells_main[, x_I := beta * post * (1 - F_o_2021)]
run_int <- function(outcome) {
  fml <- as.formula(sprintf("%s ~ x_F + x_I | code_cno + year", outcome))
  feols(fml, data = cells_main, weights = ~employment,
        cluster = ~code_cno, notes = FALSE)
}
res2 <- list(
  log_employment = run_int("log_employment"),
  mean_log_wage  = run_int("mean_log_wage")
)
etable(res2, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2"), digits = 4)

# Test of equality tau_F = tau_I
cat("\nTest H0: tau_F = tau_I (Wald, normal approx):\n")
for (lab in c("log_employment", "mean_log_wage")) {
  mod <- res2[[lab]]
  b <- coef(mod); V <- vcov(mod)
  d <- b["x_F"] - b["x_I"]
  vd <- V["x_F","x_F"] + V["x_I","x_I"] - 2 * V["x_F","x_I"]
  z <- d / sqrt(vd)
  cat(sprintf("  %-20s  diff = %7.4f (SE %6.4f)  z = %5.2f  p = %.4f\n",
              lab, d, sqrt(vd), z, 2*pnorm(-abs(z))))
}

# --- Save ---------------------------------------------------------------------
results <- list(
  panel = panel_valid, cells = cells_main, F_o = F_o, yearly = yr,
  twfe_continuous = res1, twfe_interaction = res2
)
saveRDS(results, file.path(out_dir, "enaho_validation.rds"))
cat(sprintf("\n[DONE] Results saved.\n"))
