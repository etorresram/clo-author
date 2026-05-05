# ==============================================================================
# 01_load_inei_crosswalks.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru harmonization, Phase 1
#
# Reads the four INEI correspondence anexos from the official Excel workbook
# and produces clean, validated R tables saved as .rds.
#
# Source:  https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx
# Sheets:
#   caratula           — cover page (skipped)
#   CNO2015_CO95       — Anexo 1: CNO-2015 (4d) -> CO-1995 (3d)   many-to-one
#   CO95_CNO2015       — Anexo 2: CO-1995 (3d)  -> CNO-2015 (4d)  one-to-many
#   CNO2015_CIUO2008   — Anexo 3: CNO-2015 (4d) -> CIUO-2008 (4d) ~1:1
#   CIUO2008_CNO2015   — Anexo 4: CIUO-2008 (4d)-> CNO-2015 (4d)  ~1:1
#
# Output: data/cleaned/peru/crosswalks/anexo[1-4].rds
# ==============================================================================

# --- Setup --------------------------------------------------------------------
library(here)
library(readxl)
library(data.table)
library(stringr)

xlsx_path <- here("data", "raw", "peru", "inei_crosswalks.xlsx")
out_dir   <- here("data", "cleaned", "peru", "crosswalks")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

stopifnot(file.exists(xlsx_path))

# --- Helper: pad code column to fixed width ----------------------------------
# INEI codes come as integers; we force character with leading zeros so that
# downstream joins are unambiguous. CO-95 needs 3 digits, CNO/CIUO need 4.
pad_code <- function(x, width) {
  formatC(as.integer(x), width = width, format = "d", flag = "0")
}

# --- Helper: read an anexo with INEI's quirks --------------------------------
# Header is in row 4; data starts row 5. We read with col_names = FALSE,
# drop the first 4 rows, and set our own clean names.
read_anexo <- function(sheet, n_cols, col_names, code_col = 1) {
  raw <- read_excel(
    xlsx_path,
    sheet     = sheet,
    col_names = FALSE,
    col_types = "text",
    skip      = 4
  )
  raw <- as.data.table(raw)

  # INEI sometimes appends trailing blank columns (e.g., Anexo 2, Anexo 4).
  # We keep only the first n_cols meaningful columns.
  raw <- raw[, 1:n_cols]
  setnames(raw, col_names)

  # Drop empty trailing rows AND footer/source lines.
  # INEI appends a "Fuente: ..." row at the end of some sheets; we use the
  # numeric-code column (which differs by anexo: col 1 in Anexos 1-2, col 2
  # in Anexos 3-4) to identify rows that contain a real classifier code.
  raw <- raw[!is.na(raw[[code_col]]) & raw[[code_col]] != ""]
  raw <- raw[grepl("^[0-9]+$", raw[[code_col]])]

  raw
}

# --- Anexo 1: CNO-2015 (4d) -> CO-1995 (3d) ---------------------------------
# Columns in INEI order:
#   code_cno (4d) | desc_cno | enlace_cno | code_co (3d) | desc_co | enlace_co
cat("[Anexo 1] Reading CNO2015_CO95 ...\n")
a1 <- read_anexo(
  sheet     = "CNO2015_CO95",
  n_cols    = 6,
  col_names = c("code_cno", "desc_cno", "enlace_cno",
                "code_co",  "desc_co",  "enlace_co")
)
a1[, code_cno := pad_code(code_cno, 4)]
a1[, code_co  := pad_code(code_co,  3)]
a1[, c("enlace_cno", "enlace_co") := NULL]
a1[, desc_cno := str_squish(desc_cno)]
a1[, desc_co  := str_squish(desc_co)]
cat(sprintf("  rows: %d | unique CNO: %d | unique CO: %d\n",
            nrow(a1), uniqueN(a1$code_cno), uniqueN(a1$code_co)))

# Validation: Anexo 1 should be many-to-one (each CNO maps to exactly one CO)
multi_co_per_cno <- a1[, .(n = uniqueN(code_co)), by = code_cno][n > 1]
if (nrow(multi_co_per_cno) > 0) {
  cat(sprintf("  WARNING: %d CNO codes map to >1 CO code (Anexo 1 should be many-to-one)\n",
              nrow(multi_co_per_cno)))
  print(head(multi_co_per_cno))
}

# --- Anexo 2: CO-1995 (3d) -> CNO-2015 (4d) ---------------------------------
cat("\n[Anexo 2] Reading CO95_CNO2015 ...\n")
a2 <- read_anexo(
  sheet     = "CO95_CNO2015",
  n_cols    = 6,
  col_names = c("code_co",  "desc_co",  "enlace_co",
                "code_cno", "desc_cno", "enlace_cno")
)
a2[, code_co  := pad_code(code_co,  3)]
a2[, code_cno := pad_code(code_cno, 4)]
a2[, c("enlace_cno", "enlace_co") := NULL]
a2[, desc_cno := str_squish(desc_cno)]
a2[, desc_co  := str_squish(desc_co)]
cat(sprintf("  rows: %d | unique CO: %d | unique CNO: %d\n",
            nrow(a2), uniqueN(a2$code_co), uniqueN(a2$code_cno)))

# Validation: Anexo 2 should be one-to-many (CO codes map to multiple CNOs)
cardinality_co <- a2[, .(n_cno = uniqueN(code_cno)), by = code_co]
cat(sprintf("  Cardinality CO -> CNO: min=%d  median=%d  max=%d  mean=%.2f\n",
            min(cardinality_co$n_cno),
            as.integer(median(cardinality_co$n_cno)),
            max(cardinality_co$n_cno),
            mean(cardinality_co$n_cno)))

# --- Anexo 3: CNO-2015 (4d) -> CIUO-2008 (4d) -------------------------------
# Columns in INEI order (NOTE: description first, then code):
#   desc_cno | code_cno | enlace_cno | code_ciuo | desc_ciuo | enlace_ciuo
cat("\n[Anexo 3] Reading CNO2015_CIUO2008 ...\n")
a3 <- read_anexo(
  sheet     = "CNO2015_CIUO2008",
  n_cols    = 6,
  col_names = c("desc_cno",  "code_cno", "enlace_cno",
                "code_ciuo", "desc_ciuo", "enlace_ciuo"),
  code_col  = 2  # description first, then code
)
a3[, code_cno  := pad_code(code_cno,  4)]
a3[, code_ciuo := pad_code(code_ciuo, 4)]
a3[, c("enlace_cno", "enlace_ciuo") := NULL]
a3[, desc_cno  := str_squish(desc_cno)]
a3[, desc_ciuo := str_squish(desc_ciuo)]
cat(sprintf("  rows: %d | unique CNO: %d | unique CIUO: %d\n",
            nrow(a3), uniqueN(a3$code_cno), uniqueN(a3$code_ciuo)))

# Cardinality: how many CIUO per CNO?
cardinality_cno <- a3[, .(n_ciuo = uniqueN(code_ciuo)), by = code_cno]
cat(sprintf("  Cardinality CNO -> CIUO: min=%d  median=%d  max=%d  mean=%.2f\n",
            min(cardinality_cno$n_ciuo),
            as.integer(median(cardinality_cno$n_ciuo)),
            max(cardinality_cno$n_ciuo),
            mean(cardinality_cno$n_ciuo)))
n_one_to_one <- sum(cardinality_cno$n_ciuo == 1)
cat(sprintf("  CNO codes mapping 1:1 to CIUO: %d / %d (%.1f%%)\n",
            n_one_to_one, nrow(cardinality_cno),
            100 * n_one_to_one / nrow(cardinality_cno)))

# --- Anexo 4: CIUO-2008 (4d) -> CNO-2015 (4d) -------------------------------
cat("\n[Anexo 4] Reading CIUO2008_CNO2015 ...\n")
a4 <- read_anexo(
  sheet     = "CIUO2008_CNO2015",
  n_cols    = 6,
  col_names = c("desc_ciuo", "code_ciuo", "enlace_ciuo",
                "desc_cno",  "code_cno",  "enlace_cno"),
  code_col  = 2  # description first, then code
)
a4[, code_ciuo := pad_code(code_ciuo, 4)]
a4[, code_cno  := pad_code(code_cno,  4)]
a4[, c("enlace_cno", "enlace_ciuo") := NULL]
a4[, desc_cno  := str_squish(desc_cno)]
a4[, desc_ciuo := str_squish(desc_ciuo)]
cat(sprintf("  rows: %d | unique CIUO: %d | unique CNO: %d\n",
            nrow(a4), uniqueN(a4$code_ciuo), uniqueN(a4$code_cno)))

# --- Cross-validation: Anexo 3 vs Anexo 4 round-trip ------------------------
# If Anexo 3 says CNO X -> CIUO Y, does Anexo 4 say CIUO Y -> CNO X?
cat("\n[Round-trip check] Anexo 3 <-> Anexo 4 ...\n")
edges_3 <- unique(a3[, .(code_cno, code_ciuo)])
edges_4 <- unique(a4[, .(code_cno, code_ciuo)])
shared        <- nrow(merge(edges_3, edges_4, by = c("code_cno", "code_ciuo")))
only_in_a3    <- nrow(fsetdiff(edges_3, edges_4))
only_in_a4    <- nrow(fsetdiff(edges_4, edges_3))
cat(sprintf("  Edges in both Anexos:    %d\n", shared))
cat(sprintf("  Edges only in Anexo 3:   %d\n", only_in_a3))
cat(sprintf("  Edges only in Anexo 4:   %d\n", only_in_a4))
if (only_in_a3 + only_in_a4 > 0) {
  cat("  NOTE: discrepancies between Anexo 3 and Anexo 4 are not necessarily errors;\n")
  cat("        INEI may use different cardinality rules in each direction.\n")
}

# --- Save ---------------------------------------------------------------------
saveRDS(a1, file.path(out_dir, "anexo1_cno_to_co.rds"))
saveRDS(a2, file.path(out_dir, "anexo2_co_to_cno.rds"))
saveRDS(a3, file.path(out_dir, "anexo3_cno_to_ciuo.rds"))
saveRDS(a4, file.path(out_dir, "anexo4_ciuo_to_cno.rds"))

cat("\n[DONE] Four anexos saved to", out_dir, "\n")
