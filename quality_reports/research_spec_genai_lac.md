# Research Specification: Labor Market Effects of Generative AI in Latin America

**Status:** APPROVED (interview 2026-04-11)
**Author:** Eric Torres (PUCP)
**Thesis structure:** Two-paper dissertation; Paper 1 is the principal

---

## Research Question

**Paper 1 (principal):** Does exposure to large language models (LLMs) causally reduce employment, hours worked, and wages in affected occupations across Latin American labor markets, and do these effects differ from patterns documented in advanced economies?

**Paper 2:** Does LLM exposure increase wage dispersion and widen gaps in social protection coverage (formal vs informal, by gender, education, and age) in Latin America?

---

## Motivation

Generative AI is the most significant labor-market shock since the computer revolution, yet the empirical evidence is concentrated in high-income economies with low informality and high digital readiness. Latin America presents a fundamentally different context: informality exceeds 50% in most of the region, labor protections are fragmented, and AI adoption is uneven. Existing LAC evidence (Azuara, Ripani & Torres 2024; Benítez & Parrado 2024; World Bank 2024) has estimated *exposure* but not *causal effects*. This project provides the first causal estimates of LLM impact on LAC labor markets using a harmonized panel of 7 countries and modern DiD methods.

Policy relevance is immediate: LAC governments are designing AI strategies (Chile's National AI Policy, Mexico's digital transformation agenda) without causal evidence on employment displacement or reinstatement in their own markets. This paper fills that gap.

---

## Theoretical Framework

**Primary:** Task-based framework of Acemoglu & Restrepo (2018, 2020). LLM exposure operates through two opposing channels:
- **Displacement effect:** LLMs substitute for cognitive tasks, reducing labor demand in exposed occupations → negative employment/wage effect.
- **Reinstatement effect:** LLMs complement human judgment in new tasks, raising productivity → positive wage effect in exposed occupations.

The net effect is empirical and is expected to vary across countries according to labor market structure, informality, and adoption intensity.

**Contrast with RBTC (Autor, Levy & Murnane 2003):** Classical RBTC predicted automation of *routine* cognitive tasks. LLMs break this pattern by affecting *non-routine* cognitive tasks (writing, analysis, synthesis). This generates a testable prediction: non-routine high-skill occupations, historically protected from automation, now show employment/wage responses.

**LAC-specific hypothesis:** In LAC, wage complementarity (reinstatement) is expected to be *weaker* than in advanced economies because (i) formal workers in high-exposure occupations face less adoption intensity, (ii) informal workers lack the technological infrastructure to complement AI, and (iii) displacement effects may concentrate in the informal sector where protection is weakest. This cross-country contrast is the paper's sharpest contribution.

---

## Hypotheses

**H1 (primary):** LLM exposure at the occupational level reduces hours worked and employment in exposed occupations relative to control occupations after the launch of ChatGPT (Nov 2022).

**H2:** Wage effects in LAC are *smaller in magnitude* than documented effects in US/OECD settings (Brynjolfsson et al. 2023; Hartley et al. 2024; Chen et al. 2025), reflecting lower adoption intensity and structural differences.

**H3 (Paper 2):** LLM exposure increases wage dispersion (widening of upper percentiles relative to lower) and widens the formal-informal earnings gap.

**H4 (Paper 2):** Effects are heterogeneous by gender (female-dominated high-exposure occupations show larger effects), age (younger workers adapt faster), and education (tertiary-educated workers experience stronger complementarity).

---

## Empirical Strategy

**Design:** Difference-in-Differences with occupational AI exposure as the treatment measure, and the launch of ChatGPT (Nov 2022) + its 2023 diffusion as the exogenous shock.

**Treatment variable:**
- **Primary:** Continuous exposure score $E_o \in [0,1]$ from Eloundou et al. (2023), mapped O*NET → SOC → ISCO-08 (match rate >90% confirmed from Azuara et al. 2024 pilot).
- **Secondary:** Binary treatment at p50 of exposure distribution (for comparability with Liu et al. 2025 and prior literature).

**Estimators:**
1. **Primary — Continuous DiD (Callaway, Goodman-Bacon & Sant'Anna 2024):** Dose-response estimates using continuous exposure. Avoids arbitrary cutoffs.
2. **Secondary — Callaway & Sant'Anna (2021):** Heterogeneity-robust estimator with occupation as the unit of treatment.
3. **Event study — Sun & Abraham (2021):** Interaction-weighted dynamic effects.
4. **Triple differences (robustness):** exposure × post × country-level ChatGPT adoption intensity (measured via Google Trends for "ChatGPT" by country).
5. **Shift-share / Bartik:** Pre-period occupation shares × AI adoption intensity as a second identification strategy.

**Identifying assumption:** Parallel trends in outcomes between high- and low-exposure occupations absent the LLM shock. Defended via:
- Pre-trend plots and formal pre-trend tests
- Placebo shocks at 2019 and 2021
- Triple differences exploiting country-level adoption variation (Google Trends)
- Control for prior automation exposure (Acemoglu-Restrepo robot exposure, Webb 2020 AI patents) to isolate the LLM-specific effect
- Robustness to alternative exposure measures (Webb 2020, Felten et al. 2023)

**Clustering:** Occupation level (unit of treatment variation). Robustness with two-way clustering (occupation × time) and country × occupation.

**Heterogeneity:** Gender, age, education, formal/informal sector, urban/rural, economic sector. Causal forests (Athey & Wager 2018) as a data-driven complement.

**Sensitivity:** Oster (2019) bounds for selection on unobservables.

---

## Data

| Country | Survey | Frequency | Period |
|---------|--------|-----------|--------|
| Peru | ENAHO | Annual | 2015–2024 |
| Uruguay | ECH | Annual | 2015–2024 |
| Mexico | ENOE | Quarterly | 2015Q1–2024Q4 |
| Costa Rica | ECE | Quarterly | 2015Q1–2024Q4 |
| Colombia | GEIH | Quarterly | 2015Q1–2024Q4 |
| Chile | ENE | Quarterly | 2015Q1–2024Q4 |
| Ecuador | ENEMDU | Quarterly | 2015Q1–2024Q4 |

**Harmonization strategy:** Annual frequency as primary analysis (all 7 countries). Quarterly event study as secondary analysis (5 countries). Exact dates subject to data availability confirmation.

**Exposure data:** O*NET 27.2 task-level exposure scores from Eloundou et al. (2023), mapped via BLS SOC-2010 → ILO ISCO-08 crosswalk, imputed to microdata at 4-digit ISCO level.

**Match rate:** >90% (confirmed in Azuara et al. 2024 pilot for Chile, Mexico, Peru; to be re-validated for the 4 new countries).

**Contextual indicators:** WDI (internet penetration, GDP, services share), Google Trends for ChatGPT search intensity by country.

---

## Expected Results

1. **Negative employment effect** (H1): 2–5% reduction in employment/hours in high-exposure occupations relative to low-exposure, consistent with Hartley et al. (2024) for US but smaller in magnitude.
2. **Muted wage complementarity** (H2): Wage effects positive but statistically smaller than Brynjolfsson et al. (2023) customer-service estimates. This contrast is the paper's distinctive empirical finding.
3. **Amplified informal-sector displacement** (H3/H4): Within exposed occupations, informal workers lose more hours than formal workers — a pattern absent in OECD estimates.
4. **Heterogeneity by country:** Larger effects in Chile, Uruguay, Costa Rica (higher adoption, more formal markets); smaller effects in Bolivia, Ecuador, Peru (lower adoption, higher informality).

**What would surprise me:** Finding zero effects anywhere — implying LLM exposure as measured does not operate as a treatment in LAC. This would require re-framing the paper as a null result with a clear mechanism (e.g., lack of adoption).

---

## Contribution

1. **First causal evidence for LAC.** Prior LAC literature (Azuara et al. 2024, Benítez & Parrado 2024, Ciaschi et al. 2025) estimates *potential* exposure, not realized effects.
2. **7-country harmonized panel.** Extends from Azuara et al.'s 3 countries (Chile, Mexico, Peru) to 7 (+ Colombia, Costa Rica, Ecuador, Uruguay). Variation in informality and adoption intensity is a feature, not a bug.
3. **Frontier DiD methods.** Continuous treatment (Callaway et al. 2024), Sun-Abraham event studies, causal forests — beyond the binary TWFE standard in most applied AI-labor papers.
4. **Contrast with OECD estimates.** Direct comparison with US/OECD causal estimates (Hartley, Chen, Hui, Brynjolfsson) provides external validity evidence and documents LAC-specific patterns.
5. **Reproducible infrastructure.** Harmonized crosswalk and cleaned panel released as replication package, enabling future LAC researchers to extend the analysis.

---

## Open Questions

1. **Bolivia, Dominican Republic, Barbados:** Originally considered but dropped due to ISCO compatibility. Should we include them via a reduced analysis (e.g., 1-digit ISCO) as a robustness check, or exclude cleanly?
2. **Annual vs. quarterly harmonization:** Does harmonizing everything to annual lose statistical power for the event study? Consider dual analysis — annual as main, quarterly as secondary for the 5 trimestral countries.
3. **ChatGPT adoption measurement:** Google Trends is an imperfect proxy. Are there better country-level adoption measures (e.g., OpenAI API usage, firm-level surveys)?
4. **Sector-level spillovers:** Current design estimates partial equilibrium effects (within-occupation). Should we add a shift-share framework to capture sector-level reallocation?
5. **Paper 2 social protection instruments:** Which specific instruments are testable with survey data? (Conditional cash transfers, unemployment insurance coverage, pension contributions.) This needs explicit specification.
