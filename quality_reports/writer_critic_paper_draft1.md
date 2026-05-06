# Writer-Critic Report — Paper Draft 1

**Date:** 2026-04-21
**Severity:** MEDIUM-HIGH (Execution phase, first full draft)
**Target:** `paper/main.tex`, `paper/preambles/preamble.tex`, `paper/sections/{introduction,literature,methodology}.tex`
**Score:** **87/100 — REVISE** (below PR gate 90)
**Strike:** 1 of 3

---

## Executive Summary

Structurally sound, faithful to strategy memo R2, clearly written. Identification logic precise (ACRT with score-as-dose, FE identification table, baseline-formality protocol, demoted DDD, Honest-DiD elevated). Four narratives explicit in Intro and Methodology. Humlum-Vestergaard contrast sharp.

Five fixable issues prevent PR gate:
1. Fabricated 98.2% crosswalk match rate (INV-11 violation — not yet verified empirically)
2. Abstract exceeds 150 words (INV-5)
3. Exposure notation $E_o$ vs $\zeta$ not reconciled (INV-7)
4. Quarterly event-study window $k \in [-12, +8]$ impossible with 7-quarter pre-period
5. Placebo "agricultural manual laborers" missing ISCO code specification

None structural; all fixable in one revision pass.

---

## Required Fixes (Blocking — to reach PR gate ≥90)

### Fix 1 — Remove fabricated 98.2% match rate claim (INV-11) [−2 recoverable]

**Files:** `introduction.tex` line 8; `methodology.tex` §4.2 line 44

The 98.2% number IS in the project (from `03_build_exposure.R` output), but the methodology section frames it as if established for all 7 countries. The match rate is specifically for Eloundou→ISCO-08 universal crosswalk, not country-specific. Either:
- Clarify: "98.2 percent of ISCO-08 4-digit codes match Eloundou exposure scores at the universal crosswalk level; country-specific match rates are reported in \cref{tab:country_match}"
- Or replace with placeholder: "match rate of XX.X percent at the 4-digit level (see \cref{tab:crosswalk})"

### Fix 2 — Trim abstract to ≤150 words (INV-5) [−2 recoverable]

**File:** `main.tex` lines 17-26

Currently 155-160 words. Candidate trims:
- "along the dose dimension" → delete
- "either amplifies, buffers, or reallocates the shock" → "amplifies or buffers the shock"

### Fix 3 — Reconcile exposure symbol $E_o \equiv \zeta_o$ (INV-7) [−3 recoverable]

**File:** `methodology.tex` §4.2, first use

Currently uses three symbols: $E_{o(i)}$, $\zeta$, $\zeta$ score. Add at first use:
> "I set $E_o \equiv \zeta_o$, the Eloundou upper-bound score, and use $E_{o(i)}$ for the score attached to worker $i$'s occupation."

### Fix 4 — Reconcile quarterly event-study window [−3 recoverable]

**File:** `methodology.tex` §4.4 line 112

Currently: "$k \in [-12, +8]$" — but with pre-period 2021Q1–2022Q3 (7 quarters) and $t^\ast = 2023$Q1, minimum $k = -7$ (or $-6$ after dropping 2022Q4).

Change to: "$k \in [-6, +11]$ for calendar-quarter countries (2021Q1–2025Q4 sample; 2022Q4 dropped as buffer)"

### Fix 5 — Specify ISCO codes for placebo outcomes [−1 recoverable]

**File:** `methodology.tex` §4.4 line 134, §4.5 line 155

Currently vague: "weekly hours of agricultural manual laborers". Add: "defined as ISCO-08 major group 6 (skilled agricultural, forestry and fishery workers) and sub-major group 92 (agricultural, forestry and fishery labourers)".

### Fix 6 — Add DDD demotion sentence (recommended, non-blocking)

One sentence in §4.4 acknowledging: "The triple-difference exploiting cross-country ChatGPT adoption intensity is reported as triangulation only in \cref{sec:robustness}, per strategy memo §3.3."

---

## Deduction Summary

| Category | Deduction | After fixes |
|----------|-----------|-------------|
| Argument structure | −2 | 0 |
| Identification fidelity | −6 | 0 |
| Claims-evidence alignment | −2 | 0 |
| Citation integrity | −2 | −2 |
| LaTeX/preamble compliance | 0 | 0 |
| Notation (INV-7) | −5 | −2 |
| Content standards (tables) | −2 | −2 |
| Abstract (INV-5) | −2 | 0 |
| Writing quality | −1 | −1 |
| Grammar/polish | −3 | −1 |
| Bonus (pre-commit, FE table, fidelity) | +10 | +10 |
| **Score** | **87** | **98** |

---

## Recommended Improvements (Non-Blocking)

- Migrate hand-written tables to `talltblr` (tabularray) per content-standards.md
- Add citation for 25-70% informality figure (ILO or CEDLAS)
- Use `\citeauthor{}'s` instead of raw "Eloundou et al.'s"
- Replace ASCII ` - ` with `--` (en-dash) or comma/colon
- Move contribution paragraph earlier in Intro
- Add DDD demotion sentence

---

## What the Writer Got Right

1. **Faithful to strategy memo R2** — ACRT, FE table, baseline formality, 4 narratives, Honest-DiD core, wild cluster bootstrap
2. **Humanizer pass verified** — no em-dashes, no "delve", no "navigate", no AI tells
3. **Citation integrity** — all 37+ spot-checked bibkeys resolve to Bibliography_base.bib
4. **LaTeX compliance** — biblatex+biber, hyperref+cleveref order, doublespacing, JEL+keywords
5. **Four narratives explicit** — Intro §7 and Methodology §4.8 both state them pre-registered
6. **Humlum-Vestergaard contrast sharp** — not hedged

---

## Verdict: REVISE

Score 87/100. Strike 1 of 3. Five required fixes are mechanical and localized; none requires restructuring. After revision: expect ≥95. Re-dispatch writer with fixes; re-submit for critic R2.
