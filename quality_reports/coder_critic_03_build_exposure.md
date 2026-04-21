# Code Review — `03_build_exposure.R`

**Date:** 2026-04-20
**Reviewer:** coder-critic
**Severity:** MEDIUM-HIGH (Execution phase, treatment-defining script)
**Score:** **72/100 — REVISE**
**Strike count:** 1 of 3

---

## Executive Summary

Script is well-structured and passes all code-quality invariants (INV-14 through INV-19). Helpers composable, range assertions in place, seed set, paths relative, no prohibited functions. Match-quality flags, 3-digit fallback, diagnostics built as specified. **On pure code hygiene: high 80s.**

However, **the crosswalk has a substantive methodological defect**: the 44 unmatched ISCO-08 4-digit codes are **not random** — they are the ICT cluster (25xx, 35xx), medical practitioners (22xx), and care/education aides (53xx). **Exactly the highest-exposure occupations and the paper's central policy interest.**

### Root cause: SOC vintage mismatch

- Eloundou et al. (2023) publishes scores keyed to **O*NET-SOC 2019 (SOC-2018 derivative)**
- BLS ISCO↔SOC crosswalk used is **SOC-2010 vintage**
- The 15-1XXX ICT block was renumbered between vintages:
  - SOC-2010 `15-1132` Software Developers Apps → SOC-2018 `15-1252`
  - SOC-2010 `15-1121` Computer Systems Analysts → SOC-2018 `15-1211`
- Result: all ISCO-08 25xx codes unmatched because their SOC-2010 equivalents aren't in Eloundou's SOC-2018 file

### Why this must be fixed before downstream

Dropping/imputing ICT occupations creates **attenuation bias in the same direction as Humlum-Vestergaard null** — mechanically reproducing the null the paper tries to distinguish itself from. Any JLE/JHR referee will catch this in minutes.

---

## Required Fixes (Blocking)

### Fix #1 (CRITICAL) — Harmonize SOC vintages

**Option (A) — Preferred: Two-step crosswalk with SOC-2010↔SOC-2018 bridge**
1. Download BLS SOC 2010-to-2018 crosswalk (`soc_2010_to_2018_crosswalk.xlsx` from bls.gov/soc)
2. Detect Eloundou SOC vintage (check if software-developer entries carry `15-1252` vs `15-1132`)
3. If SOC-2018: map Eloundou SOC-2018 → SOC-2010 via bridge (one-to-one for ~85%, handle many-to-one by mean)
4. Proceed with existing ISCO↔SOC-2010 merge

Expected recovery: **40+ of 44 unmatched 4-digit codes**.

**Option (B) — Validation: Use Azuara et al. (2024) direct Eloundou→ISCO-08 crosswalk**
The user coauthored Azuara 2024, which built this direct bridge for 3 LAC countries in the pilot. Use as cross-validation against Option (A).

**Recommendation:** Apply (A) as primary, validate against (B). Expected ζ values within ~0.05 for ICT cells.

### Fix #2 — Assert sibling coverage in 3-digit fallback

In `aggregate_to_isco_3d`, emit explicit `message()` (not silent NA) when a 3-digit parent has `match_quality == "unmatched"`, listing affected codes.

### Fix #3 — Document unweighted SOC-mean choice

Add comment in `aggregate_to_isco08` explaining unweighted vs employment-weighted mean. Report in diagnostics how many ISCO-08 cells have `any_partial = TRUE`.

---

## Detailed Deductions

| # | Severity | Issue | Deduction |
|---|----------|-------|-----------|
| 1 | CRITICAL | SOC vintage mismatch → 44 non-random unmatched cells (ICT + medical + care) | **−20** |
| 2 | HIGH | Silent imputation in 3-digit fallback when entire parent unmatched | −5 |
| 3 | MEDIUM | Unweighted mean over partial-split SOCs not documented | −5 |
| 4 | MEDIUM | `gamma_task` loaded but never aggregated (γ robustness missing) | −3 |
| 5 | LOW | `cat()` instead of `message()` in diagnostics (lines 122-171) | −3 |
| 6 | LOW | No `.rds` mirror for 3-digit/diagnostics | −1 |
| 7 | LOW | `1:10` literals vs `seq_len` | −1 |
| | | **Adjusted (1+2 overlap)** | **−28** |
| | | **Final** | **72/100** |

---

## Recommended Improvements (Non-Blocking)

- R1. Aggregate `gamma_task` through pipeline for γ robustness exposure
- R2. Replace `cat()` with `message()` for INV-compliant console
- R3. Save `.rds` mirrors of 3-digit and diagnostics outputs
- R4. Add `stopifnot(all(c("isco08_4d","soc_code") %in% names(d)))` after column renaming
- R5. Record SOC vintage explicitly in output (add `soc_vintage` column)

---

## What the Coder Got RIGHT

- Architecture (helpers + main + diagnostics + match_quality flags)
- All 6 INV code-quality invariants respected
- Roxygen docs, verb-noun naming, stopifnot guards
- Float tolerance (1e-10) not `==`
- NaN→NA defensive guards
- Duplicate-key checks
- Paper-to-code mapping at script header (lines 17-22)
- Memo-equation references in comments

If Fix #1 were resolved, the code would score **~88/100**. The deduction is driven almost entirely by ONE data-input decision — not by discipline.

---

## Verdict: REVISE

- NOT MAJOR REVISION — architecture sound
- NOT APPROVED — treatment variable contaminated in biasing direction
- Apply Fix #1 (blocking), Fix #2 (blocking), Fix #3 (document). Expected one-round convergence.
