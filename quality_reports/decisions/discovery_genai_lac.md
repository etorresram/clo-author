# Decision Record: Discovery — Gen AI & LAC Labor Markets

**Date:** 2026-04-11
**Phase:** Discovery
**Decided by:** Eric Torres (user), in interview with Claude

---

## Decision

Frame the doctoral thesis as a **two-paper dissertation on the causal effects of generative AI on Latin American labor markets**, with Paper 1 (labor market effects: employment, hours, wages) as the principal contribution and Paper 2 (distributional and social protection effects) as the companion.

The empirical design uses:
- **7-country panel** (Chile, Colombia, Costa Rica, Ecuador, Mexico, Peru, Uruguay)
- **DiD with continuous occupational exposure** from Eloundou et al. (2023), mapped via O*NET → SOC → ISCO-08 crosswalk
- **ChatGPT launch (Nov 2022)** as exogenous shock
- **Modern DiD estimators:** Callaway & Sant'Anna (2021); Callaway, Goodman-Bacon & Sant'Anna (2024) for continuous treatment; Sun & Abraham (2021) for event study
- **Task-based framework** of Acemoglu & Restrepo (2018, 2020) as theoretical anchor

Target journals: JLE, JHR, AEJ:Applied (field-tier); AER, QJE, REStud (aspirational top-5).

---

## Alternatives Considered

### A1. Single-country deep dive (e.g., Peru only)
- **Pros:** Tighter identification, richer heterogeneity analysis, less harmonization burden.
- **Why rejected:** Loses the comparative dimension that distinguishes this paper from existing US/OECD evidence. Cross-country variation in informality and adoption intensity is the paper's core contribution.

### A2. Firm-level analysis (matched employer-employee data)
- **Pros:** Allows adoption-intensity measurement, firm-level productivity channels.
- **Why rejected:** Matched data not publicly available for all 7 LAC countries. Would restrict sample severely.

### A3. Structural model with AI adoption decisions
- **Pros:** Stronger welfare analysis, policy counterfactuals.
- **Why rejected:** Out of scope for a two-paper reduced-form dissertation. Can be a follow-up paper.

### A4. 10-country scope (including Bolivia, Barbados, Dominican Republic)
- **Pros:** Wider coverage of LAC region.
- **Why rejected:** ISCO codes incomplete or absent in microdata; crosswalk match rate insufficient. Cleaner to proceed with 7 countries with full ISCO coverage.

### A5. Binary treatment at p50 as primary specification
- **Pros:** Standard in prior AI-labor literature (Liu et al. 2025).
- **Why rejected:** Arbitrary cutoff is the first thing a referee will challenge. Continuous treatment (Callaway et al. 2024) avoids this and uses more variation. Binary reported as secondary.

### A6. Naive TWFE DiD
- **Pros:** Simple, widely understood.
- **Why rejected:** Known to be biased with heterogeneous treatment effects (Goodman-Bacon 2021, de Chaisemartin & D'Haultfoeuille 2020). Unacceptable at target journals in 2026.

### A7. RBTC (routine-biased technical change) as primary framework
- **Pros:** Classical framework, easy to cite.
- **Why rejected:** LLMs affect *non-routine* cognitive tasks, breaking the RBTC prediction. Task-based framework (Acemoglu & Restrepo) is more flexible and current. RBTC mentioned as contrast, not anchor.

---

## Key Assumptions (Must Hold)

1. **ChatGPT launch (Nov 2022) is exogenous to LAC labor markets.** Unlikely to be violated — the launch was a US technology decision not responsive to LAC conditions.
2. **O*NET-based exposure is a valid proxy for task content in LAC occupations.** Defended by: task content is relatively stable across countries within an ISCO code; validated indirectly by Azuara et al. 2024 which used the same mapping.
3. **Parallel trends holds.** Testable via pre-trend plots, placebo shocks, triple diff with Google Trends.
4. **ISCO-08 crosswalk match rate ≥90% in all 7 countries.** Confirmed for Chile, Mexico, Peru (Azuara 2024). Needs validation for Colombia, Costa Rica, Ecuador, Uruguay.
5. **Survey sample sizes support occupation-level variation at 4-digit ISCO.** Needs verification per country.

---

## What Would Invalidate This Design

- **Pre-trends show systematic divergence** between high- and low-exposure occupations before 2023 → must re-design with alternative identification (e.g., synthetic control by occupation).
- **ISCO crosswalk match rate <80% in multiple countries** → may need to aggregate to 3-digit ISCO, losing resolution. If <70%, need alternative occupation measurement.
- **Google Trends shows essentially zero variation in ChatGPT adoption across LAC countries** → triple-diff robustness check is weakened; must rely more heavily on placebos.
- **ChatGPT launch was anticipated** (unlikely but possible — OpenAI beta testing, GPT-3 hype cycle): if evidence of pre-launch adjustment found in pre-trends, treatment date must shift earlier.
- **Sample size insufficient at 4-digit ISCO in smaller countries** (Uruguay, Costa Rica): may need to drop these or aggregate.

---

## Follow-Up Actions

1. Validate crosswalk match rates for Colombia, Costa Rica, Ecuador, Uruguay (not previously tested in Azuara 2024 pilot).
2. Download and inspect sample sizes at 4-digit ISCO for all 7 surveys.
3. Pull Google Trends ChatGPT data by country as a candidate adoption intensity measure.
4. Incorporate the user's existing literature folder into `master_supporting_docs/supporting_papers/` for the Librarian to ingest.
5. Proceed to `/strategize` to formalize the identification design and pre-analysis plan.

---

## Approval

**User (Eric Torres):** Approved framing, 7-country scope, task-based framework, continuous DiD as primary. Approved contrast-with-OECD as sharpest contribution.
