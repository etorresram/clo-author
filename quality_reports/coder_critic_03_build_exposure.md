# Code Audit — `03_build_exposure.R`

**Strike count: 2 of 3 — CLEARED (no third strike needed)**

---

## Round 2 — 2026-04-20

**Score: 92/100 — APPROVED** (PR gate cleared)

### Executive Summary

All 3 blocking fixes from Round 1 correctly implemented and verified in outputs. Match rate 90% → **98.2%** (target ≥95% beaten). ICT/medical recovery probe matches claimed ζ values exactly. 8 residual unmatched codes confirmed non-biasing (military, 1 religious, 5 niche manual/textile). Code quality held up — no regressions. **Approved for downstream scripts.**

### Round 2 Verification

| Fix | Status | Notes |
|-----|--------|-------|
| #1 SOC vintage harmonization | VERIFIED | `detect_soc_vintage()` uses 12 anchor codes; `bridge_soc_2018_to_2010()` handles 1:1, 1:many, many:1; `.00` suffix normalized; magic-byte ZIP guard against Akamai 403; Internet Archive fallback with LOUD failure path |
| #2 3-digit fallback messaging | VERIFIED | Substantive `message()` listing parent + children, not a stub. Only fires for ISCO 011 (military) as expected |
| #3 Unweighted mean documentation | VERIFIED | 10-line comment block explaining rationale (infeasibility across 5 LAC countries, Eloundou/Humlum precedent, memo §10 forward reference). `any_partial=TRUE` for 283 of 438 ISCO-08 cells |
| R1 `gamma_task` aggregated | VERIFIED | Flows task → SOC → ISCO-4d → ISCO-3d |
| R2 `cat()` → `message()` | VERIFIED | No `cat()` in main script |
| R3 `.rds` mirrors | VERIFIED | All 3 outputs have `.rds` |
| R4 `stopifnot` column guards | VERIFIED | Lines 65, 80, 134, 319-326, helper 375 |
| R5 `seq_len(10L)` | VERIFIED | No `1:n` literals remain |

### ICT Recovery Probe (all verified against output CSV)

| ISCO | Label | ζ R1 | ζ R2 | Match |
|------|-------|------|------|-------|
| 2511 | Systems analysts | MISSING | 0.7346 | partial-split |
| 2512 | Software developers | MISSING | 0.7000 | partial-split |
| 2513 | Web/multimedia developers | MISSING | 0.9325 | exact |
| 2514 | Applications programmers | MISSING | 1.0000 | exact |
| 2211 | Generalist medical practitioners | MISSING | 0.5868 | partial-split |
| 2212 | Specialist medical practitioners | MISSING | 0.4832 | partial-split |

Face validity: top-10 now dominated by ICT/cognitive occupations (Applications programmers 1.0, Public relations 1.0, Training/staff dev 0.975, Web devs 0.932) — Eloundou pattern restored.

### 8 Residual Unmatched (confirmed non-biasing)

| ISCO | Label | Impact |
|------|-------|--------|
| 0110 | Commissioned armed forces officers | Military — excluded per memo §10.2 |
| 0210 | Non-commissioned armed forces officers | Military — excluded per memo §10.2 |
| 3413 | Religious associate professionals | Niche, no SOC analog |
| 4213 | Pawnbrokers and money-lenders | Niche, no SOC analog |
| 7133 | Building structure cleaners | Manual — low expected exposure |
| 8155 | Fur and leather preparing machine operators | Manual — low expected exposure |
| 8159 | Textile machine operators NEC | Manual — low expected exposure |
| 9613 | Sweepers and related labourers | Manual — low expected exposure |

**None are ICT, medical, education, clerical, or managerial → no systematic exposure bias.**

### Score Breakdown (R2)

- Starting: 100
- Internet Archive snapshot reliability risk: −1
- `detect_soc_vintage` silent tie-break when both counts zero: −1
- `n_bridge_expanded` semantics slightly off from docstring: −1
- Minor roxygen absence on 3-digit message block: −1
- Residual 8 unmatched codes (unavoidable): −4
- **Final: 92/100 — APPROVED**

### Recommended (Non-Blocking) for Future Polish

1. Rename `n_bridge_expanded` to `n_extra_join_rows` or reimplement as `nrow(joined) - length(unique(joined$soc_2018))` for true 1:many count
2. Add `warning()` in `detect_soc_vintage` when both anchor counts are zero
3. Archive BLS xlsx in git-LFS or DVC for replication

### Verdict: APPROVED

Downstream scripts (`04_merge_exposure.R`, `02_harmonize_surveys.R`) may proceed using `data/cleaned/exposure/exposure_isco08.csv` as the canonical treatment variable.

---

## Round 1 — 2026-04-20 (Historical)

**Score: 72/100 — REVISE**

### Root cause

**SOC vintage mismatch.** Eloundou et al. (2023) publishes scores keyed to **O*NET-SOC 2019 (SOC-2018 derivative)**. BLS ISCO↔SOC crosswalk used was **SOC-2010 vintage**. The `15-1XXX` ICT block was renumbered between vintages (SOC-2010 `15-1132` Software Developers → SOC-2018 `15-1252`), causing all ISCO-08 25XX software/IT occupations to drop (44 unmatched, non-random, biasing toward zero).

### Required Fixes

1. **CRITICAL** — Harmonize SOC vintages via bridge (2010↔2018)
2. **HIGH** — 3-digit fallback message when all children unmatched
3. **MEDIUM** — Document unweighted SOC-mean choice

All 3 applied successfully in R2. See R2 section above.
