# ==============================================================================
# 02b_find_formality_vars.R
# ==============================================================================
# Diagnose which variables are available in EPEN for constructing the formality
# indicator. The 2025 dictionary lists c312 (SUNAT), c313 (accounting books)
# and c364_* (pension affiliation) as formality proxies, but these were absent
# in 02_inspect_epen.R. We list ALL variables and search for any related to:
#   - pensions / pensiones
#   - health insurance / seguro
#   - employer registration / SUNAT / RUC / registr
#   - contract / contrato
#   - accounting books / libros / contabilidad
# ==============================================================================

library(here)
library(haven)
library(data.table)

raw_dir <- here("data", "raw", "peru", "epen_trimestral")

show_all_vars <- function(filepath) {
  cat("\n", strrep("=", 78), "\n", sep = "")
  cat("FILE:", basename(filepath), "\n")
  cat(strrep("=", 78), "\n", sep = "")
  d <- read_dta(filepath)
  vars <- data.table(
    name  = tolower(names(d)),
    label = sapply(d, function(x) attr(x, "label") %||% "")
  )

  # Search for formality-related labels
  pattern <- "(?i)(pension|afp|sunat|ruc|contrato|libro|contab|seguro|essalud|formal|registr|jurid|natural)"
  matches <- vars[grepl(pattern, label, perl = TRUE) | grepl(pattern, name, perl = TRUE)]
  cat(sprintf("\n  Variables matching formality pattern (%d found):\n", nrow(matches)))
  print(matches)

  cat("\n  All variables (first 50):\n")
  print(head(vars, 50))
  if (nrow(vars) > 50) {
    cat("\n  All variables (51 to end):\n")
    print(vars[51:nrow(vars)])
  }

  invisible(vars)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

cat("\n#### PRE file ####\n")
v_pre <- show_all_vars(file.path(raw_dir, "2021", "epe_q1_2021.dta"))

cat("\n\n#### POST file ####\n")
v_post <- show_all_vars(file.path(raw_dir, "2022", "epen_q4_2022.dta"))

# Compare variable sets
cat("\n", strrep("=", 78), "\n", sep = "")
cat("VARIABLES IN PRE BUT NOT POST:\n")
cat(strrep("=", 78), "\n", sep = "")
print(setdiff(v_pre$name, v_post$name))

cat("\n", strrep("=", 78), "\n", sep = "")
cat("VARIABLES IN POST BUT NOT PRE:\n")
cat(strrep("=", 78), "\n", sep = "")
print(setdiff(v_post$name, v_pre$name))

cat("\n[DONE]\n")
