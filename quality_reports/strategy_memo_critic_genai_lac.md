# Strategy Memo — strategist-critic Report

**Date:** 2026-04-20
**Severity:** MEDIUM-HIGH (Strategy phase)
**Target:** `strategy_memo_genai_lac.md`
**Score:** 84/100 — **REVISE** (above commit gate 80, below PR gate 90)

---

## Executive Summary

Substantively strong, methodologically current strategy memo. Portfolio (continuous-treatment DiD + binary CS + SA event study + DDD + Bartik + Honest-DiD) is well-chosen. Three-narrative pre-commitment in §7 is a genuine design innovation, not a hedge. Memo is self-aware about Humlum-Vestergaard and LAC-specific threats.

However: 5 substantive identification problems must be addressed before code is written, plus 5 placeholder citations blocking the writer phase. Core CGBS 2024 framing has subtle misstatement; FE stack has absorption inconsistency; Bartik design is underspecified; informality-as-co-primary promotion is defensible only with baseline-formality protocol.

**Verdict: REVISE** — not MAJOR REVISION. Fixes are concrete and bounded. Design is sound.

---

## Required Fixes (Blocking before code)

1. **Restate the ACRT estimand (Issue 2.1)** — CGBS 2024 ACRT defined for *dose*; Eloundou ζ is a *predicted score*, not a dose administered. Either:
   - (a) Restate as ATT(e) conditional on $E_o = e$ — level effect at each exposure bin
   - (b) Defend score-as-dose via Handa 2025 realized-usage correlation
   **Deduction: −4**

2. **Rewrite §2.2/§2.5 FE identification statements (Issue 2.2)** — Write a precise table of which variation identifies τ under each FE stack. Current text conflates "α_oc absorbs E_o" (trivially true) with "FE protects against confounding" (not the case).
   **Deduction: −3**

3. **Promote baseline formality (F_{i,2021}) to primary interaction (Issue 2.3)** — Contemporaneous F_ict is a bad control (post-treatment outcome). Baseline formality is the econometrically defensible partition. Reframe the three §5.2 narratives around baseline F.
   **Deduction: −3** (biggest JLE-referee risk)

4. **Downgrade DDD from identification to triangulation (Issue 2.4)** — Google Trends for "ChatGPT" confounded by tech-press coverage + student curiosity. Add pre-committed diagnostic on σ(A_c) and a placebo demeaning (e.g., by Trends for "cryptocurrency").
   **Deduction: −2**

5. **Specify Bartik time structure + Rotemberg protocol (Issue 2.5)** — Current spec ambiguous between levels-on-Post and change-on-change. Commit to Rotemberg-weights reporting, top-weighted-occupation drop robustness, and acknowledge 2015–2019 vs pre-2022 share mismatch.
   **Deduction: −2**

6. **Invert 2022Q4 buffer decision (Issue 2.6)** — ChatGPT launched 30 Nov 2022. 2022Q4 averages are 2/3 pre-launch. Including biases τ toward zero. Drop as primary, include as robustness (Humlum-Vestergaard + Hartley convention).
   **Deduction: −1**

7. **Add Narrative D to §7** — Current three narratives miss "LAC effects positive (complementarity dominates)" — the Brynjolfsson/Chen pattern. If τ > 0, current PAP has no frame.
   **Deduction: 0 (counted in 2.3)**

8. **Resolve 5 placeholder citations:**
   - `Solon2015_weight` → Solon, Haider & Wooldridge (2015, JHR) "What Are We Weighting For?"
   - `Abadie2023_cluster` → Abadie, Athey, Imbens & Wooldridge (2023, QJE) "When Should You Adjust Standard Errors for Clustering?"
   - `Berg2018_spillover` → clarify (Berg, Buffie & Zanna 2018 IMF WP on AI inequality?)
   - `BurlingCobbCJ2020_pap` → clarify (Burlig 2018 JPubE on PAPs for non-experimental?)
   - `Vilhuber2020_reproducibility` → Vilhuber (AEA Data Editor, 2020 AEA P&P)
   **Deduction: −1**

9. **Close 4 false-open decisions in §14** — Items 2 (4-digit vs 3-digit), 3 (2022Q4), 4 (Bolivia/DR/Barbados), 6 (USD PPP vs log), 7 (Humlum-Vestergaard bib key) should be decisions, not open items.
   **Deduction: −1**

10. **Commit wild cluster bootstrap protocol (Issue 3.1)** — For specifications with <50 clusters, use Cameron-Gelbach-Miller 2008 wild cluster bootstrap. Commit `fwildclusterboot`.
    **Deduction: −2**

## Recommended Improvements (Non-blocking)

- SUTVA quantitative bound: within- vs cross-industry comparison (Issue 2.7) **−1**
- Multiple-testing tree explicit: Bonferroni × Romano-Wolf family definition (Issue 3.2) **−1**
- Oster bounds integrated into §4.4 with δ=1, R²_max=1.3·R² rule (Issue 4.1) **−1**
- External-validity paragraph to broader LAC + sub-Saharan Africa / South Asia (Issue 4.2) **−1**
- LPM boundary-outcome check for high-employment country × occupation cells (Issue 3.3)

---

## §7 Humlum-Vestergaard Pre-Commitment — Verdict

**Real strategy, not hedge.** Narrative C ("null in formal, large in informal") is structurally distinct from both Hartley/Chen US findings AND Humlum-Vestergaard — a genuine LAC-specific hypothesis.

**Missing:** Narrative D — "LAC effects positive (complementarity dominates), concentrated in tertiary/urban formal workers." This is the Brynjolfsson/Chen pattern and must be pre-committed.

---

## Publication Viability (Realistic)

- **JLE primary target:** P(R&R) ≈ 35% — realistic conditional on fixes
- **AER/QJE stretch:** P ≈ 10–15% — needs novel innovation, dramatic finding, or structural model
- **JHR R&R:** P ≈ 25%
- **AEJ:Applied R&R:** P ≈ 25%
- **Field downshift (Labour Economics):** P ≈ 15% if pre-trends fail + informality null + no cross-country pattern

**What pushes up:** (i) Realized-usage validation via Handa 2025 / LAC firm survey; (ii) Stripped-down task-based structural model rationalizing informality pattern; (iii) Admin data linkage in at least one country (IMSS Mexico, UI Chile).

---

## Positive Findings (what the memo gets right)

1. Portfolio thinking — 5 independent identification strategies + Honest-DiD is unusually rigorous
2. Pre-commitment protocol (§7) is a genuine contribution, not a hedge (adding D completes it)
3. Risk register (§12) — three-column risk/detection/mitigation is publication-track discipline
4. Diagnostic-driven decision rules (§8.3) — scripted rules, not judgment
5. Honest self-critique — SUTVA acknowledgment, Humlum-Vestergaard reference, null-replication fallback

---

## Final Verdict

**REVISE.** Score 84/100. Fixes are bounded and concrete. Design is sound. Round 2 escalation to strategist (not user) expected to converge in one round.

Do **not** advance to coder phase until Issues 2.1, 2.2, 2.3, and the 5 placeholder citations are resolved.
