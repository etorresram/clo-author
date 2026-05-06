# Strategy Memo Round 2 — strategist-critic Report

**Date:** 2026-04-20
**Severity:** MEDIUM-HIGH (Strategy phase)
**Target:** `strategy_memo_genai_lac.md` (Round 2)
**Prior score:** 84/100 REVISE → **New score: 93/100 APPROVED**

---

## Executive Summary

All 10 required fixes from Round 1 applied at stated locations; 4 of 5 recommended improvements integrated. Revisions are substantive, not cosmetic: FE identification table, baseline-formality imputation protocol, DDD demotion with cryptocurrency-demeaning placebo, Rotemberg-disclosure Bartik protocol, explicit MTC tree — exactly the upgrades that turn a commit-gate memo into a PR-gate memo. Narrative D (§7.4) is sharp and distinguishable, not perfunctory. Bibliography verified — all 5 new bibkeys resolve with correct metadata.

Two residual concerns (Fix 1 score-as-dose defense; Fix 3 cell imputation for 6 of 7 countries) are real but acceptable given the strategist has documented them transparently and committed falsification strategies.

**Verdict: APPROVED for coder phase.** Score 93/100 crosses PR gate (90). Submission gate (95) remains conditional on empirical execution.

---

## Fix-by-Fix Verification

| # | Fix | Applied? | Substance correct? | Residual |
|---|-----|----------|-------------------|----------|
| 1 | ACRT estimand / Handa score-as-dose | YES | Partially defensible. Handa 2025 is correct citation; caveat is honest. "Strong positive correlation" ≠ monotone rank-preserving map. Mitigated by ATT(e) at representative e values as model-free complement. | −1 |
| 2 | FE identification table | YES | Correct. 3-row table (oc+ct / oc+ct+ot / oct) cleanly separates identification. | 0 |
| 3 | Baseline formality primary + imputation | YES | Mostly sound. Mexico ENOE rotating-panel correct. Cell imputation at (4-digit ISCO × age × gender × education × urban) for 6 RCS countries is standard, but injects attenuation bias. Strategist acknowledges in Residual Risk #2 with Mexico benchmark mitigation. | −1 |
| 4 | DDD demotion + diagnostics | YES | Correct. σ(A_c)/mean(A_c) < 0.20 threshold is defensible. Cryptocurrency-demeaning placebo isolates LLM-specific from general-tech salience. | 0 |
| 5 | Bartik explicit time structure + Rotemberg | YES | Correct. Change-on-levels structure explicit; Rotemberg disclosure committed; top-weighted-occupation drop and 2019 share robustness specified; AKM SE via `ShiftShareSE`. | 0 |
| 6 | Invert 2022Q4 | YES | Correct. "Q4 averages are 2/3 pre-launch → biases toward zero" logic sound. | 0 |
| 7 | Narrative D (complementarity) | YES | Genuinely sharp. Pattern statement (τ>0, tertiary/urban formal) structurally distinct from A/B/C. "Stratification of gains" framing is publishable. | 0 |
| 8 | 5 placeholder citations resolved | YES | All 5 verified with correct metadata (DOIs, journals). | 0 |
| 9 | §14 false-open decisions closed | YES | Items 2, 3, 4, 6, 7 closed. Items 1, 5 remain genuinely open (implementation-dependent). | 0 |
| 10 | Wild cluster bootstrap protocol | YES | `fwildclusterboot` named; <50 cluster trigger specified; AKM SE via `ShiftShareSE` for Bartik. | 0 |

---

## Recommended Improvements — Audit

| Recommendation | Integrated? | Location |
|----------------|-------------|----------|
| Oster bounds (δ=1, R²_max=1.3R²) | YES | §4.4 + §12.2 |
| External-validity paragraph (SSA / South Asia) | YES | §7.6 |
| MTC tree explicit | YES | §10.7 (four-level tree) |
| LPM boundary check | YES | §8.5 |
| SUTVA quantitative bound | Partial (deferred to analysis) | §4.5 — flagged |

SUTVA partial-addressal is acceptable — quantitative spillover bound requires data in hand.

---

## Positive Findings (R2 specific)

1. **Cryptocurrency-demeaning placebo (Fix 4) is inventive** — instrument hygiene move JLE referees reward
2. **Imputation protocol table in §5.2 (Fix 3)** cleaner than many published PAPs
3. **Narrative D is not throwaway** — "stratification of gains" framing genuinely publishable
4. **MTC tree in §10.7 is publication-grade** — four-level hierarchy with Romano-Wolf within / Bonferroni across
5. **Residual Risks section intellectually honest** — Handa load-bearing-ness, imputation attenuation, threshold sensitivity all flagged with falsification plans

---

## New Issues Introduced (Non-blocking)

1. §5.2 imputation table "None among our 7" row could be clearer about Mexico ENOE distinction (rotating panel ≠ true panel). Minor prose fix at writer stage.
2. §7.4 Narrative D targets AEJ:Applied/JHR; §7.1 Narrative A targets JLE/JHR. If Narrative D realizes with large formal effects, consider adding JLE.

---

## Residual Risks Monitor

Strategist's own Residual Risks section accurate. I add:

**R6: Handa 2025 citation load-bearing.** Entire score-as-dose defense rests on one paper. If Handa's correlation is contested (driven by specific occupation families rather than smooth gradient), Fix 1 collapses. Mitigation already present: ATT(e) at representative doses is model-free.

---

## Final Verdict

**APPROVED.** Score 93/100 crosses PR gate (90). Round 2 accepted on first re-review. No round 3 needed; no escalation. Memo cleared for coder phase.

Submission gate (≥95) achievable after empirical execution validates: (i) Handa-robustness for Fix 1 score-as-dose defense; (ii) Mexico-ENOE benchmark bounds the Fix 3 imputation attenuation.
