# Domain Profile

<!--
Configured for: The Labor Market and Distributional Impact of Generative AI in Latin America
Author: Eric Torres (PUCP)
Last updated: 2026-04-11
-->

## Field

**Primary:** Labor Economics
**Adjacent subfields:** Development Economics, Public Economics, Economics of AI & Technology, Applied Microeconometrics

---

## Target Journals (ranked by tier)

| Tier | Journals |
|------|----------|
| Top-5 | AER, QJE, REStud, JPE |
| Top field | JLE, JHR, AEJ:Applied, AEJ:Policy, RESTAT |
| Strong field | JDE, JPubE, Labour Economics, ILR Review, Economic Development and Cultural Change |
| Specialty | World Development, IZA Journal of Labor Economics, Journal of Economic Inequality |

---

## Common Data Sources

| Dataset | Type | Access | Notes |
|---------|------|--------|-------|
| ENOE (Mexico) | Labor survey, quarterly | Public (INEGI) | Largest LAC labor survey; rotating panel; ISCO-08 compatible |
| ENE (Chile) | Labor survey, quarterly | Public (INE Chile) | ISCO-08 compatible; covers formal/informal |
| ENEMDU (Ecuador) | Labor survey, quarterly | Public (INEC Ecuador) | ISCO-08 codes available; urban/rural |
| GEIH (Colombia) | Labor survey, quarterly | Public (DANE) | ISCO-08 compatible; large sample |
| ECE (Costa Rica) | Labor survey, quarterly | Public (INEC Costa Rica) | ISCO-08 compatible; smaller sample |
| ENAHO (Peru) | Household survey, annual | Public (INEI) | Rich income/expenditure data; ISCO-08 compatible |
| ECH (Uruguay) | Household survey, annual | Public (INE Uruguay) | ISCO-08 compatible; small but clean |
| O*NET 27.2 | Occupation task content database | Public (US DOL) | Source for AI exposure scores via Eloundou et al. (2023) |
| SOC-2010 to ISCO-08 crosswalk | Concordance | Public (BLS/ILO) | >90% match rate confirmed (Azuara et al. 2024) |
| WDI | Country-level macro indicators | Public (World Bank) | Internet penetration, GDP, digitalization indices |
| Google Trends | ChatGPT search intensity by country | Public (Google) | Proxy for country-level LLM adoption intensity |

---

## Common Identification Strategies

| Strategy | Typical Application | Key Assumption to Defend |
|----------|-------------------|------------------------|
| DiD with occupational exposure (binary) | ChatGPT launch (Nov 2022) as shock; high- vs low-exposure occupations (p50 cutoff) | Parallel trends: absent AI shock, outcomes evolve similarly across exposure groups. Exposure measure is predetermined (US O*NET, not endogenous to LAC). |
| DiD with continuous treatment (Callaway, GB & SA 2024) | Continuous occupational exposure score instead of binary cutoff | Dose-response monotonicity. No manipulation of exposure assignment. |
| Event study (Sun & Abraham 2021) | Dynamic effects pre/post ChatGPT launch | No anticipation before Nov 2022. Flat pre-trends. |
| Shift-share / Bartik | Occupation shares (predetermined) × country-level AI adoption intensity | Exogeneity of occupation shares in base period. AI adoption not responding to LAC labor market conditions. |

---

## Field Conventions

- Binary outcomes (employment/participation) → report LPM as primary; probit/logit marginal effects in robustness
- Wage outcomes → log wages as primary; levels in robustness; address selection into employment (Lee bounds or Heckman correction)
- Clustering at the occupation level (unit of treatment variation); robustness with two-way clustering (occupation × time)
- Always discuss extensive margin (employment/participation) vs intensive margin (hours worked, wages)
- Heterogeneity by gender, age, education, formal/informal sector is expected in labor papers
- Modern DiD estimators required — naive TWFE unacceptable if treatment effect heterogeneity exists
- RIF regressions (Firpo, Fortin & Lemieux 2009) standard for distributional analysis
- Welfare analysis or distributional implications expected for top-5 submissions
- Cross-country studies must address harmonization of occupation codes and survey design differences

---

## Notation Conventions

| Symbol | Meaning | Anti-pattern |
|--------|---------|-------------|
| $Y_{ict}$ | Outcome for individual $i$ in country $c$ at time $t$ | Don't use $y$ without subscripts |
| $E_o$ | AI exposure score for occupation $o$ (continuous, $\in [0,1]$) | Don't use $T$ for exposure (conflicts with time) |
| $\text{Post}_t$ | Indicator for post-ChatGPT period ($t \geq$ 2023Q1) | Don't abbreviate as $P$ |
| $D_{ot}$ | Binary treatment: $\mathbb{1}[E_o > \text{median}] \times \text{Post}_t$ | Distinguish from continuous exposure |
| $\tau$ | ATT or CATT parameter of interest | Not $\beta$ which is reserved for controls |
| $\alpha_o, \alpha_c, \alpha_t$ | Occupation, country, time fixed effects | Always subscript to distinguish |
| $\alpha, \beta, \zeta$ | Direct, complementary, and upper-bound exposure parameters (Eloundou et al.) | Use Greek letters consistently with source paper |

---

## Seminal References

| Paper | Why It Matters |
|-------|---------------|
| Eloundou et al. (2023) | Source of GPT exposure scores mapped to occupations — foundation of treatment variable |
| Acemoglu & Restrepo (2020) | Task-based framework for automation and AI effects on labor — theoretical backbone |
| Acemoglu & Autor (2011) | Skills, Tasks and Technologies — canonical task framework |
| Webb (2020) | AI exposure measure based on patent-to-occupation mapping — alternative exposure measure |
| Callaway & Sant'Anna (2021) | Modern DiD estimator with heterogeneous treatment effects — primary estimation method |
| Callaway, Goodman-Bacon & Sant'Anna (2024) | DiD with continuous treatment — frontier method for continuous exposure |
| Sun & Abraham (2021) | Interaction-weighted event study estimator — replaces naive TWFE event studies |
| Firpo, Fortin & Lemieux (2009) | RIF/unconditional quantile regressions — key method for Paper 2 distributional analysis |
| Azuara, Ripani & Torres (2024) | Prior IDB exposure estimates for Chile, Mexico, Peru — direct predecessor to this project |
| Brynjolfsson, Li & Raymond (2023) | GenAI productivity effects — early causal evidence from customer service |
| Goodman-Bacon (2021) | TWFE decomposition — explains why naive DiD fails with heterogeneous effects |
| Goldsmith-Pinkham, Sorkin & Swift (2020) | Bartik instrument validity — framework for shift-share identification |

---

## Field-Specific Referee Concerns

- **"Why use US-based O*NET exposure for LAC?"** → Exposure measure is predetermined and based on task content, not adoption. US task content is a reasonable proxy for cognitive task structure across countries. Robustness with alternative exposure measures (Webb 2020, Felten et al. 2023).
- **"ISCO-08 crosswalk introduces measurement error"** → Show robustness to alternative mappings (4-digit vs 3-digit vs 2-digit). Report crosswalk match rates.
- **"Selection into employment post-shock biases wage estimates"** → Lee bounds or Heckman correction. Show employment effects first, then condition on selection.
- **"ChatGPT is just one model; what about adoption lags in LAC?"** → Event study showing timing. Google Trends data for actual adoption by country. Indirect channel: global task reallocation affects LAC even without local adoption.
- **"Latin America has low AI adoption; why would effects be detectable?"** → Indirect exposure via offshoring/nearshoring, global labor market integration. Also test for heterogeneity by internet penetration.
- **"Parallel trends assumption"** → Pre-trend tests, placebo treatment dates (2019, 2021), alternative control groups.
- **"External validity across 5 very different countries"** → Feature, not bug. Cross-country heterogeneity analysis is the contribution.
- **"Informality confounds results"** → Formal/informal heterogeneity analysis is central to Paper 2. Show effects separately.

---

## Quality Tolerance Thresholds

| Quantity | Tolerance | Rationale |
|----------|-----------|-----------|
| Point estimates | 1e-4 | Survey-weighted regression precision |
| Standard errors | 1e-3 | Clustered SE variability |
| Exposure scores | exact | Predetermined, no estimation uncertainty |
| Coverage rates | ± 0.02 | Bootstrap with B=999 |
