# ==============================================================================
# build_exposure_map.R
# Helper functions for scripts/R/03_build_exposure.R
# Project : Gen AI & LAC Labor Markets
# Purpose : Load Eloundou (2023) task-level GPT-exposure ratings and aggregate
#           them from SOC-2010 (6-digit) to ISCO-08 (4-digit / 3-digit) via the
#           BLS ISCO-08 <-> SOC-2010 crosswalk.
#
# Inputs  : data/raw/onet/task_ratings.csv
#           data/raw/crosswalks/ISCO_SOC_Crosswalk.xls
#
# Exports : check_raw_files(), load_eloundou_scores(),
#           load_isco_soc_crosswalk(), aggregate_tasks_to_soc(),
#           crosswalk_soc_to_isco08(), aggregate_to_isco08(),
#           aggregate_to_isco_3d(), assert_range_01(),
#           diagnostics_row()
# ==============================================================================

# NOTE: packages are loaded at the top of 03_build_exposure.R (INV-15).
# This file contains only pure functions that take data.tables as input.

# ------------------------------------------------------------------------------
# Existence / integrity guard.
# ------------------------------------------------------------------------------

#' Check that required raw files exist.
#' @param onet_path Path to Eloundou task_ratings.csv.
#' @param xwalk_path Path to BLS ISCO_SOC_Crosswalk.xls.
#' @return TRUE invisibly; stops with an informative error otherwise.
check_raw_files <- function(onet_path, xwalk_path) {
  missing_files <- c(
    if (!file.exists(onet_path))  onet_path,
    if (!file.exists(xwalk_path)) xwalk_path
  )
  if (length(missing_files) > 0L) {
    stop(
      "Required raw file(s) not found:\n  ",
      paste(missing_files, collapse = "\n  "),
      "\nDownload Eloundou task_ratings.csv from the GPTs-are-GPTs ",
      "replication package and the ISCO-08<->SOC-2010 crosswalk from BLS.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------------------
# Range assertion: alpha, beta, zeta must lie in [0, 1].
# ------------------------------------------------------------------------------

#' Assert that a numeric vector lies in [lo, hi] (allowing NA).
#' @param x numeric
#' @param lo lower bound (default 0)
#' @param hi upper bound (default 1)
#' @param name variable label for error messaging
assert_range_01 <- function(x, lo = 0, hi = 1, name = "variable") {
  rng <- suppressWarnings(range(x, na.rm = TRUE))
  if (!is.finite(rng[1L]) || !is.finite(rng[2L])) {
    stop(sprintf("%s has no finite values.", name), call. = FALSE)
  }
  # tolerance for float noise
  if (rng[1L] < lo - 1e-10 || rng[2L] > hi + 1e-10) {
    stop(sprintf(
      "%s out of [%g, %g] range: observed [%g, %g].",
      name, lo, hi, rng[1L], rng[2L]
    ), call. = FALSE)
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------------------
# Load Eloundou task-level scores and collapse to the SOC-6d level.
# ------------------------------------------------------------------------------

#' Load Eloundou (2023) task-level scores from the GPTs-are-GPTs replication.
#'
#' The file `task_ratings.csv` stores one row per (SOC-2010 6-digit, O*NET task)
#' with human and GPT-4 ratings of alpha (direct exposure), beta (LLM +
#' complementary technologies), and gamma (alternative rubric). We follow the
#' strategy memo's definition and use the human-mean ratings as primary.
#'
#' @param onet_path path to task_ratings.csv
#' @return data.table with columns soc_code, alpha_task, beta_task, gamma_task
load_eloundou_scores <- function(onet_path) {
  d <- data.table::fread(onet_path)
  required <- c(
    "soc_code",
    "mean_rating_human_alpha",
    "mean_rating_human_beta",
    "mean_rating_human_gamma"
  )
  missing <- setdiff(required, names(d))
  if (length(missing) > 0L) {
    stop("Eloundou file missing columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  out <- d[, list(
    soc_code   = sprintf("%06d", as.integer(soc_code)),
    alpha_task = as.numeric(mean_rating_human_alpha),
    beta_task  = as.numeric(mean_rating_human_beta),
    gamma_task = as.numeric(mean_rating_human_gamma)
  )]

  assert_range_01(out$alpha_task, name = "alpha_task")
  assert_range_01(out$beta_task,  name = "beta_task")
  assert_range_01(out$gamma_task, name = "gamma_task")

  out
}

#' Aggregate task-level Eloundou scores to SOC-2010 6-digit occupations.
#'
#' Per Eloundou (2023), the occupation-level exposure is the (unweighted) mean
#' of task-level scores within the occupation. We compute alpha, beta and zeta
#' (= alpha + beta, clamped to [0,1]) per SOC, along with the number of tasks
#' used (a quality diagnostic).
#'
#' @param tasks data.table from load_eloundou_scores()
#' @return data.table keyed by soc_code with alpha, beta, zeta, n_tasks
aggregate_tasks_to_soc <- function(tasks) {
  soc <- tasks[, list(
    alpha   = mean(alpha_task, na.rm = TRUE),
    beta    = mean(beta_task,  na.rm = TRUE),
    n_tasks = .N
  ), by = soc_code]

  # zeta = alpha + beta (strategy memo upper bound), clamped into [0, 1].
  soc[, zeta := pmin(pmax(alpha + beta, 0), 1)]

  data.table::setkey(soc, soc_code)
  soc
}

# ------------------------------------------------------------------------------
# Load ISCO-08 <-> SOC-2010 crosswalk.
# ------------------------------------------------------------------------------

#' Load BLS ISCO-08 (4-digit) <-> SOC-2010 (6-digit) crosswalk.
#'
#' Output columns: isco08_4d, isco08_label, soc_code, soc_label, part.
#' - `part = "*"` indicates a partial match (one SOC is split across multiple
#'   ISCO codes). We retain these and average over SOCs per ISCO.
#'
#' @param xwalk_path path to ISCO_SOC_Crosswalk.xls
#' @return data.table
load_isco_soc_crosswalk <- function(xwalk_path) {
  sheets <- readxl::excel_sheets(xwalk_path)
  target <- grep("ISCO.*SOC", sheets, value = TRUE)[1L]
  if (is.na(target)) {
    stop("Could not find ISCO<->SOC sheet in ", xwalk_path, call. = FALSE)
  }
  raw <- readxl::read_excel(xwalk_path, sheet = target)
  d <- data.table::as.data.table(raw)
  data.table::setnames(
    d,
    old = c("ISCO-08 Code", "ISCO-08 Title EN", "part",
            "soc", "soc_code", "2010 SOC Title"),
    new = c("isco08_4d", "isco08_label", "part",
            "soc_text", "soc_code", "soc_label"),
    skip_absent = TRUE
  )
  # Normalize codes as fixed-width strings for safe joins.
  d[, soc_code := sprintf("%06d", as.integer(soc_code))]
  d[, isco08_4d := sprintf("%04d", as.integer(isco08_4d))]
  d[, isco08_label := trimws(isco08_label)]
  d[]
}

# ------------------------------------------------------------------------------
# Crosswalk SOC-6d scores -> ISCO-08 4-digit.
# ------------------------------------------------------------------------------

#' Merge SOC-level scores into the crosswalk.
#' @param soc data.table from aggregate_tasks_to_soc()
#' @param xwalk data.table from load_isco_soc_crosswalk()
#' @return long data.table with one row per (isco08_4d, soc_code) pair and the
#'         SOC's alpha/beta/zeta if matched; NA otherwise. Also flags
#'         `match_soc` logical and `part` from the crosswalk.
crosswalk_soc_to_isco08 <- function(soc, xwalk) {
  joined <- merge(
    xwalk[, list(isco08_4d, isco08_label, soc_code, part)],
    soc[,   list(soc_code, alpha, beta, zeta, n_tasks)],
    by = "soc_code", all.x = TRUE, sort = FALSE
  )
  joined[, match_soc := !is.na(alpha)]
  joined[]
}

#' Aggregate SOC-level exposures to ISCO-08 4-digit (unweighted SOC mean).
#'
#' For ISCO codes mapped to multiple SOCs (many-to-one), average alpha, beta
#' and zeta across matched SOCs. Track match-quality flags:
#'   exact         : 1 SOC, 1 ISCO, no 'part' split
#'   many-to-one   : >1 SOC maps to this ISCO
#'   partial-split : at least one crosswalk row has part = '*'
#'   unmatched     : no SOC-level Eloundou score available for any mapped SOC
#'
#' @param joined data.table from crosswalk_soc_to_isco08()
#' @return data.table keyed by isco08_4d with isco08_label, alpha, beta, zeta,
#'         n_onet_soc (matched SOCs), n_soc_total (total mapped SOCs),
#'         match_quality
aggregate_to_isco08 <- function(joined) {
  agg <- joined[, list(
    isco08_label = isco08_label[1L],
    alpha        = mean(alpha, na.rm = TRUE),
    beta         = mean(beta,  na.rm = TRUE),
    zeta         = mean(zeta,  na.rm = TRUE),
    n_onet_soc   = sum(match_soc),
    n_soc_total  = .N,
    any_partial  = any(part == "*", na.rm = TRUE)
  ), by = isco08_4d]

  # NaN -> NA when every matched SOC had NA (shouldn't happen but be defensive).
  for (v in c("alpha", "beta", "zeta")) {
    agg[is.nan(get(v)), (v) := NA_real_]
  }

  agg[, match_quality := data.table::fcase(
    n_onet_soc == 0L,                          "unmatched",
    n_onet_soc == 1L & n_soc_total == 1L &
      !any_partial,                            "exact",
    n_onet_soc >= 1L & any_partial,            "partial-split",
    n_onet_soc > 1L,                           "many-to-one",
    default = "other"
  )]

  # Clamp small float noise into [0,1].
  for (v in c("alpha", "beta", "zeta")) {
    agg[!is.na(get(v)), (v) := pmin(pmax(get(v), 0), 1)]
  }

  agg[, any_partial := NULL]
  data.table::setkey(agg, isco08_4d)
  agg[]
}

#' Aggregate 4-digit ISCO exposure to 3-digit (unweighted mean across 4d codes).
#' @param isco4 data.table from aggregate_to_isco08()
#' @return data.table keyed by isco08_3d
aggregate_to_isco_3d <- function(isco4) {
  d <- data.table::copy(isco4)
  d[, isco08_3d := substr(isco08_4d, 1L, 3L)]
  out <- d[, list(
    alpha           = mean(alpha, na.rm = TRUE),
    beta            = mean(beta,  na.rm = TRUE),
    zeta            = mean(zeta,  na.rm = TRUE),
    n_isco08_4d     = .N,
    n_matched_4d    = sum(match_quality != "unmatched"),
    n_onet_soc_sum  = sum(n_onet_soc, na.rm = TRUE)
  ), by = isco08_3d]
  for (v in c("alpha", "beta", "zeta")) {
    out[is.nan(get(v)), (v) := NA_real_]
  }
  out[, match_quality := data.table::fcase(
    n_matched_4d == 0L,                 "unmatched",
    n_matched_4d == n_isco08_4d,        "full",
    default                            = "partial"
  )]
  data.table::setkey(out, isco08_3d)
  out[]
}

# ------------------------------------------------------------------------------
# Diagnostics helper.
# ------------------------------------------------------------------------------

#' Build a one-row diagnostic summary for a named stage.
#' @param stage character label
#' @param n_in integer input size
#' @param n_out integer output size
#' @param match_rate proportion in [0,1]
diagnostics_row <- function(stage, n_in, n_out, match_rate = NA_real_) {
  data.table::data.table(
    stage      = stage,
    n_in       = as.integer(n_in),
    n_out      = as.integer(n_out),
    match_rate = match_rate
  )
}
