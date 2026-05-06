# ==============================================================================
# build_exposure_map.R
# Helper functions for scripts/R/03_build_exposure.R
# Project : Gen AI & LAC Labor Markets
# Purpose : Load Eloundou (2023) task-level GPT-exposure ratings and aggregate
#           them from SOC (6-digit) to ISCO-08 (4-digit / 3-digit) via the BLS
#           ISCO-08 <-> SOC-2010 crosswalk.  Because Eloundou publishes against
#           O*NET-SOC 2019 (a SOC-2018 derivative) while the ISCO<->SOC
#           crosswalk keys on SOC-2010, this file also implements a SOC-2018
#           -> SOC-2010 bridge using the BLS 2010-to-2018 crosswalk.
#
# Inputs  : data/raw/onet/task_ratings.csv
#           data/raw/crosswalks/ISCO_SOC_Crosswalk.xls
#           data/raw/crosswalks/soc_2010_to_2018_crosswalk.xlsx (auto-fetched)
#
# Exports : check_raw_files(), load_eloundou_scores(),
#           load_isco_soc_crosswalk(), aggregate_tasks_to_soc(),
#           crosswalk_soc_to_isco08(), aggregate_to_isco08(),
#           aggregate_to_isco_3d(), assert_range_01(), diagnostics_row(),
#           detect_soc_vintage(), load_soc_2010_to_2018_bridge(),
#           ensure_soc_2010_to_2018_bridge(), bridge_soc_2018_to_2010(),
#           normalize_soc_code()
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
# SOC code normalization.
# ------------------------------------------------------------------------------

#' Normalize SOC codes to a canonical 6-digit no-hyphen string.
#'
#' Handles: hyphenated form (`15-1252`), plain 6-digit (`151252`), O*NET-SOC
#' ".00" suffix (`15-1252.00` or `151252.00`), and numeric input.  Returns NA
#' for inputs that are NA or cannot be coerced to 6 digits.
#'
#' @param x character or numeric vector of SOC codes
#' @return character vector, each either a 6-digit string or NA.
normalize_soc_code <- function(x) {
  if (is.numeric(x)) {
    return(ifelse(is.na(x), NA_character_, sprintf("%06d", as.integer(x))))
  }
  x <- as.character(x)
  # Strip O*NET-SOC ".00"/".01"/... suffix (detailed occupation tag).
  x <- sub("\\.[0-9]+$", "", x)
  # Strip hyphen.
  x <- gsub("-", "", x, fixed = TRUE)
  # Trim whitespace.
  x <- trimws(x)
  # Left-pad numeric strings to width 6; keep only if exactly 6 digits.
  out <- ifelse(grepl("^[0-9]+$", x),
                formatC(as.integer(x), width = 6L, flag = "0"),
                NA_character_)
  out[is.na(x) | x == "" | nchar(out) != 6L] <- NA_character_
  out
}

# ------------------------------------------------------------------------------
# SOC vintage detection and 2010<->2018 bridge.
# ------------------------------------------------------------------------------

# Anchor codes: software-developer area, where SOC-2010 and SOC-2018 disagree.
# SOC-2010: 15-1132/15-1133 (software developers, apps/systems).
# SOC-2018: 15-1252 (software developers), 15-1254 (web devs), 15-1211 (sys analysts).
.SOC_2010_ANCHORS <- c("151132", "151133", "151121", "151134", "151131")
.SOC_2018_ANCHORS <- c("151252", "151253", "151254", "151255",
                       "151211", "151221", "151251")

#' Detect which SOC vintage a set of SOC-6d codes belongs to.
#'
#' Heuristic: count anchor codes unique to each vintage in the `15-1xxx` ICT
#' block and the `15-2xxx` math block.  Returns the vintage with the larger
#' count, or "SOC-2010" on a tie (conservative: no bridging needed).
#'
#' @param soc_codes character vector of 6-digit SOC codes (normalized).
#' @return one of "SOC-2010" or "SOC-2018".
detect_soc_vintage <- function(soc_codes) {
  stopifnot(is.character(soc_codes))
  n_2010 <- sum(soc_codes %in% .SOC_2010_ANCHORS)
  n_2018 <- sum(soc_codes %in% .SOC_2018_ANCHORS)
  if (n_2018 > n_2010) "SOC-2018" else "SOC-2010"
}

#' Ensure the SOC 2010-to-2018 bridge file is cached locally; fetch otherwise.
#'
#' BLS direct download is Akamai-blocked for automated clients; we fall back
#' to the Internet Archive mirror (known-good snapshot).  If neither source is
#' reachable, we fail loudly with a manual-download instruction.
#'
#' @param dest_path target xlsx path
#' @return dest_path (invisibly) on success; stops on failure.
ensure_soc_2010_to_2018_bridge <- function(dest_path) {
  if (file.exists(dest_path) && file.info(dest_path)$size > 10000L) {
    return(invisible(dest_path))
  }
  dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)
  urls <- c(
    "https://www.bls.gov/soc/2018/soc_2010_to_2018_crosswalk.xlsx",
    paste0("https://web.archive.org/web/20240926213405/",
           "https://www.bls.gov/soc/2018/soc_2010_to_2018_crosswalk.xlsx")
  )
  ua <- paste0("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ",
               "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0")
  for (u in urls) {
    tryCatch({
      utils::download.file(u, destfile = dest_path, mode = "wb",
                           quiet = TRUE, headers = c("User-Agent" = ua))
      # Verify it is a real xlsx (ZIP-format, >10 KB).
      if (file.info(dest_path)$size > 10000L) {
        con <- file(dest_path, "rb")
        magic <- readBin(con, "raw", n = 2L)
        close(con)
        if (identical(as.integer(magic), c(0x50L, 0x4BL))) {
          message(sprintf("[build_exposure_map] Fetched SOC-2010->2018 bridge from %s",
                          sub("^https?://", "", u)))
          return(invisible(dest_path))
        }
      }
    }, error = function(e) NULL)
  }
  stop(
    "Could not auto-fetch the BLS SOC 2010-to-2018 crosswalk.\n",
    "Please manually download soc_2010_to_2018_crosswalk.xlsx from ",
    "https://www.bls.gov/soc/2018/ and place it at:\n  ", dest_path,
    call. = FALSE
  )
}

#' Load and normalize the BLS SOC 2010-to-2018 crosswalk.
#'
#' The BLS xlsx has six header rows of boilerplate.  We skip them and normalize
#' SOC codes to canonical 6-digit form.  Fails loudly if the expected columns
#' are missing (edge-case guard from fix spec).
#'
#' @param bridge_path path to soc_2010_to_2018_crosswalk.xlsx
#' @return data.table with columns soc_2010, soc_2018
load_soc_2010_to_2018_bridge <- function(bridge_path) {
  raw <- readxl::read_excel(bridge_path, sheet = 1L, skip = 6L)
  nm <- names(raw)
  col_2010 <- grep("2010.*SOC.*Code", nm, ignore.case = TRUE, value = TRUE)[1L]
  col_2018 <- grep("2018.*SOC.*Code", nm, ignore.case = TRUE, value = TRUE)[1L]
  if (is.na(col_2010) || is.na(col_2018)) {
    stop("SOC 2010->2018 bridge file has unexpected header; columns found: ",
         paste(nm, collapse = ", "), call. = FALSE)
  }
  d <- data.table::as.data.table(raw)
  d <- d[, .(
    soc_2010 = normalize_soc_code(get(col_2010)),
    soc_2018 = normalize_soc_code(get(col_2018))
  )]
  d <- d[!is.na(soc_2010) & !is.na(soc_2018)]
  data.table::setkey(d, soc_2018)
  d[]
}

#' Bridge an Eloundou SOC-2018 exposure table onto SOC-2010 space.
#'
#' Semantics:
#'  * One-to-one SOC-2018 -> SOC-2010: direct substitution.
#'  * One-to-many (single SOC-2018 becomes multiple SOC-2010):
#'      replicate the exposure row for each SOC-2010 child (conservative --
#'      assigns the same alpha/beta/zeta/gamma to all children).
#'  * Many-to-one (multiple SOC-2018 rolled into one SOC-2010):
#'      average alpha/beta/zeta/gamma across the merged codes, record count.
#'  * SOC-2018 codes that are themselves already valid SOC-2010 codes
#'    (unchanged between vintages) pass through untouched via the bridge's
#'    identity rows.
#'  * SOC-2018 codes absent from the bridge are dropped (logged at diagnostic
#'    level in the caller).  The function returns the count dropped.
#'
#' @param soc_2018 data.table keyed by soc_code (SOC-2018) with columns
#'   alpha, beta, zeta, gamma (optional), n_tasks.
#' @param bridge data.table from load_soc_2010_to_2018_bridge().
#' @return list(soc_2010 = data.table keyed by soc_code (SOC-2010),
#'              n_dropped = integer count of SOC-2018 codes without a bridge row,
#'              n_expanded = integer count of one-to-many expansions,
#'              n_merged = integer count of many-to-one collapses).
bridge_soc_2018_to_2010 <- function(soc_2018, bridge) {
  stopifnot(is.data.table(soc_2018), "soc_code" %in% names(soc_2018))
  has_gamma <- "gamma" %in% names(soc_2018)

  # Align key name to join.
  s2018 <- data.table::copy(soc_2018)
  data.table::setnames(s2018, "soc_code", "soc_2018")

  in_codes <- unique(s2018$soc_2018)
  present_in_bridge <- intersect(in_codes, bridge$soc_2018)
  n_dropped <- length(setdiff(in_codes, present_in_bridge))

  # Inner join: this replicates a given SOC-2018 row for each SOC-2010 child
  # (one-to-many expansion) automatically.
  joined <- merge(s2018, bridge, by = "soc_2018", all.x = FALSE, all.y = FALSE,
                  allow.cartesian = TRUE)

  n_expanded <- nrow(joined) - length(present_in_bridge)

  # Many-to-one: multiple SOC-2018 codes map to the same SOC-2010 code.
  # Average exposure scores across the merged codes.
  agg_cols <- c("alpha", "beta", "zeta", if (has_gamma) "gamma")
  expr <- lapply(agg_cols, function(v) bquote(mean(.(as.name(v)), na.rm = TRUE)))
  names(expr) <- agg_cols
  expr$n_tasks       <- quote(sum(n_tasks, na.rm = TRUE))
  expr$n_soc_2018_in <- quote(.N)
  j <- as.call(c(quote(list), expr))
  out <- joined[, eval(j), by = .(soc_2010)]

  n_merged <- sum(out$n_soc_2018_in > 1L)

  # Clamp float noise into [0,1].
  for (v in agg_cols) {
    out[!is.na(get(v)), (v) := pmin(pmax(get(v), 0), 1)]
  }

  data.table::setnames(out, "soc_2010", "soc_code")
  data.table::setkey(out, soc_code)

  list(soc_2010 = out[], n_dropped = n_dropped,
       n_expanded = n_expanded, n_merged = n_merged)
}

# ------------------------------------------------------------------------------
# Load Eloundou task-level scores and collapse to the SOC-6d level.
# ------------------------------------------------------------------------------

#' Load Eloundou (2023) task-level scores from the GPTs-are-GPTs replication.
#'
#' The file `task_ratings.csv` stores one row per (SOC 6-digit, O*NET task)
#' with human and GPT-4 ratings of alpha (direct exposure), beta (LLM +
#' complementary technologies), and gamma (alternative rubric).  We follow the
#' strategy memo's definition and use the human-mean ratings as primary.
#'
#' Eloundou keys scores on O*NET-SOC 2019 (a SOC-2018 derivative).  SOC codes
#' are normalized to canonical 6-digit form; vintage detection happens
#' downstream in 03_build_exposure.R.
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
    soc_code   = normalize_soc_code(soc_code),
    alpha_task = as.numeric(mean_rating_human_alpha),
    beta_task  = as.numeric(mean_rating_human_beta),
    gamma_task = as.numeric(mean_rating_human_gamma)
  )]
  out <- out[!is.na(soc_code)]

  assert_range_01(out$alpha_task, name = "alpha_task")
  assert_range_01(out$beta_task,  name = "beta_task")
  assert_range_01(out$gamma_task, name = "gamma_task")

  out
}

#' Aggregate task-level Eloundou scores to SOC 6-digit occupations.
#'
#' Per Eloundou (2023), the occupation-level exposure is the (unweighted) mean
#' of task-level scores within the occupation.  We compute alpha, beta, zeta
#' (= alpha + beta, clamped to [0,1]) and gamma (Eloundou's alternative
#' rubric, carried through for robustness) per SOC, along with the number of
#' tasks used (a quality diagnostic).
#'
#' @param tasks data.table from load_eloundou_scores()
#' @return data.table keyed by soc_code with alpha, beta, zeta, gamma, n_tasks
aggregate_tasks_to_soc <- function(tasks) {
  soc <- tasks[, list(
    alpha   = mean(alpha_task, na.rm = TRUE),
    beta    = mean(beta_task,  na.rm = TRUE),
    gamma   = mean(gamma_task, na.rm = TRUE),
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
#'   ISCO codes).  We retain these and average over SOCs per ISCO.
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
  d[, soc_code := normalize_soc_code(soc_code)]
  d[, isco08_4d := sprintf("%04d", as.integer(isco08_4d))]
  d[, isco08_label := trimws(isco08_label)]
  # R4: hard guard that rename actually produced the required columns.
  stopifnot(all(c("isco08_4d", "soc_code") %in% names(d)))
  d[]
}

# ------------------------------------------------------------------------------
# Crosswalk SOC-6d scores -> ISCO-08 4-digit.
# ------------------------------------------------------------------------------

#' Merge SOC-level scores into the crosswalk.
#' @param soc data.table from aggregate_tasks_to_soc() OR the bridged SOC-2010
#'   table from bridge_soc_2018_to_2010().  Must contain columns soc_code,
#'   alpha, beta, zeta; optionally gamma, n_tasks.
#' @param xwalk data.table from load_isco_soc_crosswalk()
#' @return long data.table with one row per (isco08_4d, soc_code) pair and the
#'         SOC's alpha/beta/zeta/gamma if matched; NA otherwise.  Also flags
#'         `match_soc` logical and `part` from the crosswalk.
crosswalk_soc_to_isco08 <- function(soc, xwalk) {
  has_gamma <- "gamma" %in% names(soc)
  keep_cols <- c("soc_code", "alpha", "beta", "zeta",
                 if (has_gamma) "gamma", if ("n_tasks" %in% names(soc)) "n_tasks")
  joined <- merge(
    xwalk[, list(isco08_4d, isco08_label, soc_code, part)],
    soc[, ..keep_cols],
    by = "soc_code", all.x = TRUE, sort = FALSE
  )
  joined[, match_soc := !is.na(alpha)]
  joined[]
}

#' Aggregate SOC-level exposures to ISCO-08 4-digit (unweighted SOC mean).
#'
#' For ISCO codes mapped to multiple SOCs (many-to-one), average alpha, beta,
#' zeta, and gamma across matched SOCs.  Track match-quality flags:
#'   exact         : 1 SOC, 1 ISCO, no 'part' split
#'   many-to-one   : >1 SOC maps to this ISCO
#'   partial-split : at least one crosswalk row has part = '*'
#'   unmatched     : no SOC-level Eloundou score available for any mapped SOC
#'
#' Choice of aggregator: we use the UNWEIGHTED mean across matched SOCs.
#' An employment-weighted mean would be preferable in principle, but would
#' require a harmonized cross-country SOC-level employment distribution for
#' each of the 5 LAC countries -- infeasible with the current panel.  The
#' unweighted mean is (i) the aggregator Eloundou et al. (2023) use at the
#' task->SOC level, (ii) what Humlum-Vestergaard use in their ISCO rollup,
#' and (iii) matches the strategy-memo primary specification.  We report
#' `any_partial` / cell counts in diagnostics so readers can see how many
#' ISCO cells are driven by partial SOC splits (an employment-weighting
#' robustness check is implemented downstream per memo Sec. 10).
#'
#' @param joined data.table from crosswalk_soc_to_isco08()
#' @return data.table keyed by isco08_4d with isco08_label, alpha, beta, zeta,
#'         gamma (if present), n_onet_soc (matched SOCs), n_soc_total (total
#'         mapped SOCs), match_quality, any_partial
aggregate_to_isco08 <- function(joined) {
  has_gamma <- "gamma" %in% names(joined)
  if (has_gamma) {
    agg <- joined[, list(
      isco08_label = isco08_label[1L],
      alpha        = mean(alpha, na.rm = TRUE),
      beta         = mean(beta,  na.rm = TRUE),
      zeta         = mean(zeta,  na.rm = TRUE),
      gamma        = mean(gamma, na.rm = TRUE),
      n_onet_soc   = sum(match_soc),
      n_soc_total  = .N,
      any_partial  = any(part == "*", na.rm = TRUE)
    ), by = isco08_4d]
  } else {
    agg <- joined[, list(
      isco08_label = isco08_label[1L],
      alpha        = mean(alpha, na.rm = TRUE),
      beta         = mean(beta,  na.rm = TRUE),
      zeta         = mean(zeta,  na.rm = TRUE),
      n_onet_soc   = sum(match_soc),
      n_soc_total  = .N,
      any_partial  = any(part == "*", na.rm = TRUE)
    ), by = isco08_4d]
  }

  # NaN -> NA when every matched SOC had NA (shouldn't happen but be defensive).
  num_vars <- c("alpha", "beta", "zeta", if (has_gamma) "gamma")
  for (v in num_vars) {
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
  for (v in num_vars) {
    agg[!is.na(get(v)), (v) := pmin(pmax(get(v), 0), 1)]
  }

  data.table::setkey(agg, isco08_4d)
  agg[]
}

#' Aggregate 4-digit ISCO exposure to 3-digit (unweighted mean across 4d codes).
#'
#' Emits a message() for each 3-digit parent whose ENTIRE 4-digit child set is
#' unmatched -- downstream scripts can then decide whether to try 2-digit
#' fallback or drop those cells (fix #2 from the coder-critic report).
#'
#' @param isco4 data.table from aggregate_to_isco08()
#' @return data.table keyed by isco08_3d with alpha, beta, zeta, (gamma),
#'         n_isco08_4d, n_matched_4d, match_quality
aggregate_to_isco_3d <- function(isco4) {
  has_gamma <- "gamma" %in% names(isco4)
  d <- data.table::copy(isco4)
  d[, isco08_3d := substr(isco08_4d, 1L, 3L)]

  if (has_gamma) {
    out <- d[, list(
      alpha           = mean(alpha, na.rm = TRUE),
      beta            = mean(beta,  na.rm = TRUE),
      zeta            = mean(zeta,  na.rm = TRUE),
      gamma           = mean(gamma, na.rm = TRUE),
      n_isco08_4d     = .N,
      n_matched_4d    = sum(match_quality != "unmatched"),
      n_onet_soc_sum  = sum(n_onet_soc, na.rm = TRUE)
    ), by = isco08_3d]
  } else {
    out <- d[, list(
      alpha           = mean(alpha, na.rm = TRUE),
      beta            = mean(beta,  na.rm = TRUE),
      zeta            = mean(zeta,  na.rm = TRUE),
      n_isco08_4d     = .N,
      n_matched_4d    = sum(match_quality != "unmatched"),
      n_onet_soc_sum  = sum(n_onet_soc, na.rm = TRUE)
    ), by = isco08_3d]
  }

  num_vars <- c("alpha", "beta", "zeta", if (has_gamma) "gamma")
  for (v in num_vars) {
    out[is.nan(get(v)), (v) := NA_real_]
  }
  out[, match_quality := data.table::fcase(
    n_matched_4d == 0L,                 "unmatched",
    n_matched_4d == n_isco08_4d,        "full",
    default                            = "partial"
  )]

  # Fix #2: report 3-digit parents with zero matched children.
  full_unmatched <- out[match_quality == "unmatched"]
  if (nrow(full_unmatched) > 0L) {
    message(sprintf(
      "[aggregate_to_isco_3d] %d 3-digit parents have ALL 4-digit children unmatched:",
      nrow(full_unmatched)
    ))
    d_unmatched <- d[match_quality == "unmatched"]
    for (p in full_unmatched$isco08_3d) {
      kids <- d_unmatched[isco08_3d == p]
      parent_label <- kids$isco08_label[1L]
      message(sprintf(
        "    %s -- %s  (children: %s)",
        p,
        if (is.na(parent_label)) "(no label)" else parent_label,
        paste(kids$isco08_4d, collapse = ", ")
      ))
    }
  }

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
