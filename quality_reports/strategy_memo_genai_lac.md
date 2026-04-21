# Strategy Memo — The Labor Market and Distributional Impact of Generative AI in Latin America

**Project:** Doctoral dissertation (PUCP), two-paper structure
**Author:** Eric Torres
**Phase:** `/strategize` — **Round 2 revision** (responding to strategist-critic 84/100, REVISE)
**Paper type:** Reduced-form (primary), with descriptive/measurement decomposition in Paper 2
**Date:** 2026-04-20
**Target journal(s):** JLE (primary) · JHR · AEJ:Applied · RESTAT (backups)

---

## Executive Summary

This memo formalizes the identification strategy for a 7-country difference-in-differences (DiD) study of how the launch of ChatGPT (November 2022) affected employment, hours, and wages in Latin American labor markets. The **primary estimator is the continuous-treatment DiD of \citet{CallawayCGBS2024_continuous}** applied to occupational exposure scores from \citet{Eloundou2023_gpt_exposure}, interpreted as a *realized-usage gradient* via the validation in \citet{Handa2025_economic_tasks}. Secondary estimators include binary-cutoff Callaway-Sant'Anna \citep{CallawayS2021_did}, Sun-Abraham event study \citep{SunAbraham2021_eventstudy}, shift-share \citep{GoldsmithPinkham2020_bartik, BorusyakHJ2022_shiftshare}, and — as triangulation, not primary identification — a triple-difference exploiting cross-country adoption intensity. Parallel trends is defended with pre-trends, placebo dates (2019, 2021), and Honest-DiD partial identification \citep{RambachanRoth2023_honest}.

The strategy is engineered to deliver a defensible result regardless of whether effects replicate Hartley/Chen/Hui, Brynjolfsson/Chen, or Humlum-Vestergaard. The **informal-sector interaction** — measured by *baseline* (2021) formality — is the paper's central LAC-specific contribution and is pre-registered as the sharpest test, not an exploratory subgroup.

---

## §1. Research Question and Primary Estimand

### 1.1 The causal question

Let $Y_{ict}$ denote a labor-market outcome (employment indicator, log hourly wage, weekly hours) for individual $i$ in country $c$ at time $t$. Let $o(i)$ denote the 4-digit ISCO-08 occupation of worker $i$ at the time of observation, with continuous exposure score $E_{o(i)} \in [0,1]$ from \citet{Eloundou2023_gpt_exposure} ($\zeta$ upper bound). Let $\text{Post}_t = \mathbb{1}[t \geq 2023\text{Q}1]$.

We want to identify the causal effect of LLM exposure on outcome $Y$ — the difference between the potential outcome $Y_{ict}(E_{o(i)})$ that obtains when occupations are exposed at intensity $E_{o(i)}$ from 2023Q1 onward, and the counterfactual $Y_{ict}(0)$ that would have obtained absent the ChatGPT launch.

### 1.2 Primary estimand: ACR on the Treated, with score-as-dose interpretation

**[REVISED — Fix 1]** Following \citet{CallawayCGBS2024_continuous}, the primary estimand is the **Average Causal Response on the Treated** along the dose dimension:

$$
\tau^{\text{ACRT}}(e) \;=\; \mathbb{E}\!\left[\,\frac{\partial Y_{ict}(e)}{\partial e}\,\bigg|\,E_{o(i)} = e,\, \text{Post}_t = 1\right], \qquad e \in (0,1]
$$

and its average over the exposure distribution:

$$
\bar\tau^{\text{ACRT}} \;=\; \int_0^1 \tau^{\text{ACRT}}(e)\, f_{E|\text{treated}}(e)\, de.
$$

**Interpretive caveat (added Round 2).** The CGBS 2024 ACRT estimand is defined for *administered dose*, whereas the Eloundou $\zeta$ score is a *predicted* exposure index, not a dose actually delivered to each worker. We adopt the **score-as-dose interpretation** by leaning on the realized-usage validation of \citet{Handa2025_economic_tasks}: Anthropic's analysis of millions of Claude conversations and OpenAI's parallel work on ChatGPT show a strong positive correlation between the Eloundou predicted-exposure ranking and observed AI-tool usage by occupation. Under this validation, we interpret $\bar\tau^{\text{ACRT}}$ as the labor-market response to a unit increase in the exposure index, with the understanding that the index maps to a realized-use gradient via the Handa correlation. This interpretation is standard in the AI-exposure literature and is what referees expect; we state it explicitly to forestall the "score is not dose" objection.

We also report the **level ATT(e)** at representative exposure values ($e = 0.25, 0.50, 0.75$) — the dose–response curve — as the model-free complement that does not require the score-as-dose mapping.

### 1.3 Why ACR/ATT, not ATE or ITT

- **Not ATE:** continuous exposure makes ATE require strong extrapolation; ACR is the direct dose–response analog and is nonparametrically identified under weaker assumptions \citep{CallawayCGBS2024_continuous}.
- **Not ITT:** exposure is observed at the occupation (not firm or individual) level. Adoption intensity enters as a *separate* country-level interaction (triple-difference, demoted to triangulation).
- **LATE is not the target:** there is no compliance structure in an occupation-level shock.

### 1.4 Relationship to H1–H4

| Hypothesis | Primary test | Estimand |
|---|---|---|
| **H1** — Exposure reduces employment/hours | Sign and magnitude of $\bar\tau^{\text{ACRT}}$ on employment and hours | ACRT, dose-response curve |
| **H2** — Wage effects smaller than OECD | Magnitude of $\bar\tau^{\text{ACRT}}$ on $\log w$ vs. Hartley/Chen | 95% CI overlap with prior |
| **H3** — Wage dispersion widens (Paper 2) | RIF coefficients at percentiles 10/25/50/75/90 \citep{FirpoFL2009_rif} | Unconditional quantile partial effect |
| **H4** — Heterogeneity by gender/education/age, and critically by **baseline formality** | CATTs from \citet{CallawayS2021_did} and causal forests \citep{AtheyWager2018_forests} | CATT on pre-specified subgroups |

---

## §2. Identification Strategy — Primary

### 2.1 Design

**Design family:** Difference-in-Differences with continuous treatment and one-shot shock.

**Treatment unit:** occupation $o$ at the 4-digit ISCO-08 level (declarative fallback to 3-digit if cell size $< 100$ obs per country-year per §8.3; **closed decision, see §14**).

**Treatment timing:** single adoption date for all occupations, $t^\ast = 2023$Q$1$. ChatGPT launched 30 November 2022; we treat 2023Q1 as the first fully post-treatment period. **[REVISED — Fix 6]** PRIMARY specification *drops* 2022Q4 (transitional — Q4 averages are 2/3 pre-launch; including biases $\tau$ toward zero). ROBUSTNESS specification includes 2022Q4 as treated (conservative lower bound). This matches the convention in \citet{HumlumVestergaard2025_llm} and \citet{Hartley2024_labor_effects}.

**Exposure:** $E_o \in [0,1]$, the Eloundou $\zeta$ upper-bound score \citep{Eloundou2023_gpt_exposure}, imputed at ISCO-08 4-digit. Eloundou $\alpha, \beta$ and Webb \citep{Webb2020_ai_exposure} / Felten \citep{Felten2023_ai_exposure} measures form the robustness layer.

### 2.2 Estimating equation — continuous DiD

Following \citet{CallawayCGBS2024_continuous}, for each exposure level $e \in (0,1]$ we estimate

$$
\text{ATT}(e, t) \;=\; \mathbb{E}\!\left[Y_{ict}(e) - Y_{ict}(0)\ \big|\ E_{o(i)} = e\right], \quad t \geq t^\ast,
$$

from the identified moment

$$
\text{ATT}(e, t) \;=\; \mathbb{E}\!\left[Y_{ict} - Y_{ic,t^\ast-1}\ \big|\ E_{o(i)} = e\right]\;-\;\mathbb{E}\!\left[Y_{ict} - Y_{ic,t^\ast-1}\ \big|\ E_{o(i)} = 0\right]
$$

under conditional parallel trends. We estimate via the `did` R package (continuous extension) and aggregate into the dose–response curve.

**Parametric companion:**

$$
\boxed{\;Y_{ict} \;=\; \tau\, \bigl(E_{o(i)} \cdot \text{Post}_t\bigr) \;+\; X_{ict}' \gamma \;+\; \alpha_{oc} \;+\; \alpha_{ct} \;+\; \varepsilon_{ict}\;}
$$

**[REVISED — Fix 2] Fixed-effects identification table.** Replacing the prior hand-wavy text:

| FE stack | $\tau$ identified from | Interpretation |
|---|---|---|
| $\alpha_{oc} + \alpha_{ct}$ | Within-(occupation, country) temporal variation in $E_o \cdot \text{Post}_t$ | **Primary DiD** — within-country, within-occupation |
| $\alpha_{oc} + \alpha_{ct} + \alpha_{ot}$ | Same, net of *global* occupation × time shocks | Cross-country deviations from global occupation trajectories — hard identification |
| $\alpha_{oct}$ | Not identified — treatment is fully absorbed | — (do not estimate) |

The $\alpha_{oc}$ FE absorbs the level of $E_o$ (which is time-invariant within $o$). The $\alpha_{ct}$ FE absorbs country-specific macro shocks. $\tau$ is thus the within-occupation-country deviation in $Y$ post-2023 across occupations with different exposure levels. The hard-identification spec ($+\alpha_{ot}$) further removes any common-across-countries occupation trend, leaving only the cross-country differential in occupation-level dynamics.

### 2.3 Dose-response curve + exposure bins

Beyond the linear slope, we estimate the dose-response by binning $E_o$ into quintiles and estimating ATT(g,t) for quintiles 2–5 vs. Q1:

$$
Y_{ict} \;=\; \sum_{q=2}^{5} \tau_q \cdot \mathbb{1}[E_{o(i)} \in Q_q] \cdot \text{Post}_t \;+\; X_{ict}'\gamma + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}.
$$

Monotonicity of $\{\tau_2, \ldots, \tau_5\}$ is a testable implication of a clean dose–response.

### 2.4 Weighting

Weighted by survey expansion factor for population representativeness; unweighted as robustness per \citet{SolonHW2015_weight}. Pooled cross-country regressions rescale country weights so each enters with equal population-share contribution (otherwise Mexico dominates).

### 2.5 Fixed-effects and clustering structure

| Spec | Fixed effects | Clustering | Purpose |
|---|---|---|---|
| **Baseline** | $\alpha_{oc}, \alpha_{ct}$ | Occupation (4-digit ISCO) | Primary |
| **TW cluster** | $\alpha_{oc}, \alpha_{ct}$ | Occupation AND country × time | Robustness — serial correlation |
| **Hard identification** | $\alpha_{oc}, \alpha_{ct}, \alpha_{ot}$ | Occupation × country | Within-occupation across-country |
| **Individual panel** (Mexico ENOE) | $\alpha_i, \alpha_{ct}$ | Individual | Rotating-panel within-person |

**Why occupation-level clustering as primary:** $E_o$ varies only across occupations, so treatment is effectively assigned at the occupation level. Clustering at a finer unit understates SE \citep{AbadieAIW2023_cluster}. ~400 4-digit ISCO occupations × 7 countries delivers adequate cluster count.

**[REVISED — Fix 10] Wild cluster bootstrap protocol.** For specifications with fewer than 50 clusters, we use the wild cluster bootstrap \citep{AbadieAIW2023_cluster} via the R package `fwildclusterboot`. This applies to (i) any country-level specification (7 countries), and (ii) country-by-country subsample analyses where heterogeneity cells drop below 50 clusters (single-country cluster counts are ~400 occupations on average, but some demographic × occupation cells fall below the threshold). For the Bartik specification, we use the Adão-Kolesár-Morales SE via `ShiftShareSE` as the design-appropriate alternative.

### 2.6 The "pool vs stack" decision

1. **Pooled (primary):** all 7 countries stacked; country enters via $\alpha_{ct}$. One $\bar\tau$ with maximum power.
2. **Stacked country-by-country:** 7 separate regressions, $\tau_c$ per country — the inputs to the cross-country heterogeneity table (Paper 1, Table 3).

---

## §3. Identification Strategy — Secondary / Robustness Layer

A credible paper reports multiple identification strategies that converge.

### 3.1 Binary-cutoff DiD \citep{CallawayS2021_did}

$$
Y_{ict} \;=\; \tau^{\text{bin}} \cdot (D_o \cdot \text{Post}_t) + X_{ict}'\gamma + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}, \quad D_o = \mathbb{1}[E_o > \text{median}(E)].
$$

Cutoff at population-weighted p50; alternatives p25, p33, p66, p75 in robustness. Reported because the prior literature \citep{Hartley2024_labor_effects, Liu2025_generate_future} uses it.

### 3.2 Event study \citep{SunAbraham2021_eventstudy}

$$
Y_{ict} \;=\; \sum_{\substack{k = -K \\ k \neq -1}}^{K} \theta_k \cdot \bigl(E_{o(i)} \cdot \mathbb{1}[t - t^\ast = k]\bigr) + X_{ict}'\gamma + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}.
$$

Reference period $k=-1$. Quarterly coverage $k \in [-12, +8]$ (5 countries); annual $k \in [-8, +2]$ (all 7). Sun-Abraham IW estimator for heterogeneity robustness.

**Expected pattern:** flat $\theta_k$ for $k < 0$; step-down at $k=0$; cumulative $\theta_k$ stabilizing or growing post-2023.

### 3.3 Triple differences (exposure × post × adoption intensity) — **[REVISED — Fix 4: Triangulation only, not primary identification]**

Country-level adoption $A_c$ measured via Google Trends search intensity for "ChatGPT" (normalized 0–100, averaged over 2023). Equation:

$$
Y_{ict} \;=\; \tau^{\text{DDD}} \cdot (E_{o(i)} \cdot \text{Post}_t \cdot A_c) + \tau^{\text{DD}} \cdot (E_{o(i)} \cdot \text{Post}_t) + X_{ict}'\gamma + \alpha_{oct} + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}.
$$

**Status (Round 2):** DDD is **demoted from primary identification layer to triangulation/robustness**. Rationale:
- Google Trends for "ChatGPT" is contaminated by tech-press coverage and student curiosity; it is not a clean adoption measure.
- DDD is informative when its sign matches DD; it cannot rescue a failed DD.

**Pre-committed diagnostics (gating use of DDD):**
1. **Variance threshold.** Report $\sigma(A_c)$ across the 7 countries. If $\sigma(A_c) / \text{mean}(A_c) < 0.20$, the DDD spec is dropped from the main paper as uninformative (insufficient cross-country variation).
2. **Placebo demeaning.** Construct $\tilde A_c = A_c^{\text{ChatGPT}} - A_c^{\text{cryptocurrency}}$ using Google Trends for both terms over the same 2023 window. This isolates LLM-specific cross-country variation from general tech-salience interest. Re-estimate DDD with $\tilde A_c$; the DDD result is reported as headline only if both DDD and DDD-with-$\tilde A_c$ have the same sign as the DD.

### 3.4 Shift-share / Bartik \citep{GoldsmithPinkham2020_bartik, BorusyakHJ2022_shiftshare} — **[REVISED — Fix 5: Explicit time structure]**

Local labor market $\ell$ × country $c$ × time $t$. Shares from 2019 (pre-COVID); shift is $E_o$:

$$
Z_{\ell c} \;=\; \sum_o \text{emp}_{o, \ell c, 2019} \cdot E_o
$$

$$
Y_{\ell c t} \;=\; \gamma \cdot (Z_{\ell c} \cdot \text{Post}_t) \;+\; \alpha_{\ell c} \;+\; \alpha_{ct} \;+\; \varepsilon_{\ell c, t}.
$$

**Pre-committed protocol:**
- **Rotemberg weights** \citep{GoldsmithPinkham2020_bartik} reported in an appendix table.
- **Narrative discussion of top-5 weighted occupations** to argue for share credibility.
- **Robustness: drop the top-weighted occupation** and re-estimate; the result must survive in sign.
- **Share-period selection.** Post-COVID sample precludes 2015–2019 shares (pre-COVID structure does not reflect the post-COVID equilibrium where our DiD operates). Primary: 2021 shares (first available post-COVID year — predetermined relative to ChatGPT launch by ~2 years). Robustness: average of 2021–2022 shares to reduce measurement noise.
- **Adão-Kolesár-Morales SE** via `ShiftShareSE` as the design-appropriate inference.

### 3.5 Honest-DiD \citep{RambachanRoth2023_honest}

For every DiD estimate we report, Honest-DiD partial-identification bounds:

$$
\Delta^{\text{RM}}(M) \;=\; \Bigl\{\delta : |\delta_t - \delta_{t-1}| \leq M \cdot \max_{s < 0} |\delta_s - \delta_{s-1}|\;\forall\,t\Bigr\}.
$$

Report (i) breakdown value $\bar M$ and (ii) identified set at $M=1$. Headline claims require $\bar M \geq 2$.

### 3.6 Summary of the identification portfolio

| Strategy | Estimand | Primary identifying variation | Status |
|---|---|---|---|
| **Continuous DiD (CGBS 2024)** | ACRT | Within-occupation-country dose × post | **Primary** |
| **Binary DiD (CS 2021)** | ATT(high vs low) | Within-occupation-country high-vs-low × post | Comparability with prior literature |
| **Event study (SA 2021)** | Dynamic ATT(k) | Within-occupation-country time path | Pre-trends and dynamics |
| **Triple-diff (adoption)** | ATE of dose × adoption | Within-country-occupation × cross-country adoption | **Triangulation only** (not identification) — gated by §3.3 diagnostics |
| **Shift-share (Bartik)** | Local-labor-market ATT | Cross-local-market occupation composition | Independent identification — Rotemberg-disclosed |
| **Honest-DiD** | Bounded ATT | Pre-trends-bounded counterfactual | Universal robustness layer |

---

## §4. Key Identifying Assumptions and Defense

### 4.1 Parallel trends

**Statement.** $\mathbb{E}[Y_{ict}(0) - Y_{ic,t^\ast-1}(0) \mid E_{o(i)} = e] = \mathbb{E}[Y_{ict}(0) - Y_{ic,t^\ast-1}(0) \mid E_{o(i)} = 0]$ for all $e$ and all $t \geq t^\ast$.

**Defense:**
1. Pre-trends event-study plot (Sun-Abraham).
2. Joint $F$-test that $\theta_k = 0$ for $k<0$ — low-power caveat per \citet{RothSantAnnaBP2023_trending}.
3. Placebo dates 2019Q1, 2021Q1.
4. Honest-DiD (§3.5).
5. Within-LAC-region placebo (Bolivia, DR, Paraguay at 1-digit ISCO).

### 4.2 No anticipation

**[REVISED — Fix 6]** Primary spec drops 2022Q4 as transitional (Q4 averages are 2/3 pre-launch; including it biases $\tau$ toward zero, since the period is mechanically a weighted average of pre and post). Robustness spec includes 2022Q4 as treated to provide a conservative lower bound on the magnitude of effect. This matches \citet{HumlumVestergaard2025_llm} and \citet{Hartley2024_labor_effects} convention.

Threats: GPT-3/3.5 commercial API use 2020–2022 (relevant for global formal sector, weak in LAC informal); AI-hype-cycle anticipation. Diagnostics: $\theta_{-2}, \theta_{-1}$ in the event study.

### 4.3 Exogeneity of occupational exposure

Eloundou scores built from O\*NET task content (US, 2022–2023) using GPT-4 + human rubric — neither responsive to LAC 2023 outcomes. Task content within ISCO codes stable across countries \citep{Azuara2024_idb_ai}. Robustness across Webb, Felten, and Handa exposures.

### 4.4 No confounding contemporaneous shocks

Candidates: post-COVID recovery (biases against us), inflation (absorbed by $\alpha_{ct}$), Mexican nearshoring (biases against us), macro volatility (drop Argentina; drop Uruguay as robustness), minimum-wage changes (control for $\Delta \log MW_{ct}$ × low-wage occupation indicator).

**Oster bounds (added Round 2).** For each headline result, we report \citet{Oster2019_unobservables} bounds with $\delta = 1$ (selection on unobservables equal to selection on observables) and $R^2_{\max} = 1.3 \cdot R^2$ per Oster's recommendation, via the `sensemakr` package. **Failure criterion:** if the identified set $[\hat\beta, \hat\beta^*(\delta=1, R^2_{\max}=1.3R^2)]$ contains zero, we flag that headline as not robust to selection-on-unobservables and require a Honest-DiD $\bar M \geq 2$ to retain it.

### 4.5 SUTVA — no spillovers across exposure cells

Most at-risk assumption. Intra-firm spillovers bias toward zero. Defense: industry × country × time FE as placebo; firm-size heterogeneity (large-firm spillovers > small-firm); narrative bound \citep{BergBZ2018_ai_inequality} that <20% AI adoption bounds GE effects. Acknowledged limit.

---

## §5. Heterogeneity Analysis (Paper 1)

### 5.1 Pre-registered dimensions

| Dimension | Partition | Primary motivation |
|---|---|---|
| **Country** | 7 country-specific CATTs | Cross-country heterogeneity is the contribution |
| **Baseline formality** $F_{i,2021}$ | Formal vs informal in 2021 (last pre-2023 obs) | **Central LAC channel — see §5.2** |
| Gender | Male vs female | H4 |
| Education | Tertiary vs <tertiary | H4 — complementarity |
| Age | 15–29, 30–49, 50+ | H4 |
| Sector | 1-digit ISIC | Services vs manufacturing vs agriculture |
| Skill level | ISCO 1-digit (1–3 / 4–5 / 6–9) | High vs low skill |
| Urban/rural | Survey-defined | Digital access proxy |

### 5.2 Baseline formality as the central LAC-specific test — **[REVISED — Fix 3]**

The librarian-critic flagged informality × technology as the paper's under-served contribution. **Round 2 elevates *baseline* (not contemporaneous) formality to a co-primary test.**

**Rationale for baseline.** Contemporaneous $F_{ict}$ is itself an outcome of LLM exposure (a worker may transition formal→informal because of treatment). Conditioning on a post-treatment outcome is a bad control \citep{AcemogluRestrepo2018_race}-style endogeneity. **Baseline formality $F_{i,2021}$** — the worker's formality status as of the last pre-2023 observation — is the econometrically defensible partition.

**Imputation protocol for $F_{i,2021}$ by data structure:**

| Survey type | Countries | $F_{i,2021}$ construction |
|---|---|---|
| **True panel** (worker followed across waves) | None among our 7 with full pre-2023 panel structure | (n/a) |
| **Rotating panel** | Mexico ENOE (5-quarter rotation) | Last observed pre-2023Q1 wave for each individual; if no pre-2023 wave (entered after Q1 2023), drop from baseline-formality analysis (kept in main DiD via 0/1 score for sensitivity) |
| **Repeated cross-section** | Colombia GEIH, Peru ENAHO, Chile ENE, Costa Rica ECE, Ecuador ENEMDU, Uruguay ECH | Cell imputation: $\hat F_{i,2021} = $ share of formal workers in 2021 within the worker's (4-digit ISCO occupation × 5-year age bin × gender × education tier × urban) cell. Documented and reported as imputed; sensitivity analysis using 3-digit ISCO cell |

**Specification (primary):**

$$
Y_{ict} = \tau_F \cdot (E_{o(i)} \cdot \text{Post}_t \cdot F_{i,2021}) + \tau_I \cdot (E_{o(i)} \cdot \text{Post}_t \cdot (1-F_{i,2021})) + X_{ict}'\gamma + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}.
$$

The four pre-committed narratives (A–D) in §7 are framed around $\tau_F$ and $\tau_I$ — baseline-formality coefficients.

**Separate exercise (clearly labeled, not structural decomposition).** A descriptive complement reports the joint distribution of LLM treatment and *contemporaneous* formality transitions ($F_{ict}$): we tabulate the share of high-exposure workers who transition formal→informal post-2023 vs. low-exposure workers, framed as a *descriptive joint distribution* and not as a causal decomposition. Paper 2 uses contemporaneous formality status as an *outcome* (not an interaction), which is the econometrically clean treatment.

### 5.3 Data-driven heterogeneity

Causal forests \citep{AtheyWager2018_forests} as exploratory CATE estimator. Top-5 drivers by variable importance; framed as exploratory, not pre-registered.

---

## §6. Distributional Analysis (Paper 2)

### 6.1 RIF regressions \citep{FirpoFL2009_rif}

For each unconditional quantile $\pi \in \{10, 25, 50, 75, 90\}$:

$$
\text{RIF}_{ict}^{(\pi)} \;=\; \tau^{(\pi)} \cdot (E_{o(i)} \cdot \text{Post}_t) + X_{ict}'\gamma^{(\pi)} + \alpha_{oc} + \alpha_{ct} + \varepsilon_{ict}^{(\pi)}.
$$

H3 test: $\tau^{(90)} - \tau^{(10)}$.

### 6.2 Oaxaca-Blinder decomposition

Decompose pre/post wage distribution change into composition vs. wage-structure components.

### 6.3 Social protection outcomes

| Outcome | Surveys | Construction |
|---|---|---|
| Formal employment | All 7 | ILO 2013 framework |
| Pension contribution | ENOE, ENAHO, ECE, ECH | Individual flag |
| Health insurance | GEIH, ENE, ENAHO | Coverage indicator |
| Written contract | GEIH, ENOE, ENAHO | Contract flag |
| Self-employment | All | Status |
| Unemployment | All | LF status |

Same DiD spec as Paper 1 primary; multiple-testing correction per §10.7.

---

## §7. Response to Humlum & Vestergaard (2025) — The "Reference Class to Beat"

\citet{HumlumVestergaard2025_llm} find effects <2% on earnings/hours in Denmark two years post-launch. Pre-committed narratives, **now four** (Round 2), framed around baseline formality $\tau_F, \tau_I$:

### 7.1 Narrative A — LAC effects larger than Denmark (informality amplifies)

**Pattern:** Aggregate $|\bar\tau| > 2\%$; informal channel $\tau_I < \tau_F < 0$.

**Frame:** "Informality amplifies displacement." Same shock, different institutional contexts; Denmark's buffers (wage bargaining, UI, formal labor market) attenuate; LAC's fragmented markets reveal the shock sharply.

**Target:** JLE / JHR.

### 7.2 Narrative B — LAC effects similar to Denmark (null)

**Pattern:** Small $|\bar\tau|$, often indistinguishable from zero.

**Frame:** First LAC null-replication of Humlum-Vestergaard. In a region with >50% informality, the absence of detectable short-run effects is informative: either adoption is too slow yet, or LLM substitution does not aggregate into measurable labor outcomes in 18 months.

**Target:** AEJ:Applied / RESTAT.

### 7.3 Narrative C — Null in formal, large in informal

**Pattern:** $\tau_F \approx 0$, $\tau_I$ meaningfully negative.

**Frame:** "The channel OECD evidence misses." Denmark has near-zero informal employment; their design cannot detect informal-sector effects. Genuine novel mechanism + methodological validity.

**Target:** JLE primary.

### 7.4 Narrative D — Complementarity dominates: positive wage effect in tertiary/urban formal — **[ADDED — Fix 7]**

**Pattern:** $\tau > 0$ on log wages for high-exposure occupations, especially concentrated in tertiary-educated urban formal workers ($\tau_F^{\text{tertiary,urban}} > 0$); employment effects near zero.

**Frame:** "LLMs in LAC act as a skill-biased productivity enhancer for the formal-educated segment, consistent with the US Brynjolfsson/Chen evidence on customer-service productivity gains. Contribution: documenting that AI-productivity gains in LAC bypass the informal majority — a stratification-of-gains result. The same technology that lifts wages in Denmark and the US lifts only the protected formal segment in LAC, leaving the median worker untouched."

**Target if realized:** AEJ:Applied or JHR.

### 7.5 Pre-commitment

The four narratives are committed in the PAP **before running the full analysis**. Which narrative the paper emphasizes is determined by the empirical pattern, not p-hacked across narratives.

### 7.6 External validity (added Round 2)

Beyond LAC, the formality channel speaks to other developing regions with similar dual-labor-market structure: sub-Saharan Africa (informality 70–85% of employment) and South Asia (informality 80%+ in India, Bangladesh, Pakistan). To the extent that the LAC informality-buffering or informality-displacement pattern obtains, it would project to these settings, with the caveat that LAC has higher digital penetration than most SSA/SA countries, so the LAC pattern is likely a leading indicator. We commit to a one-paragraph external-validity discussion in the conclusion.

---

## §8. Sample, Data, and Variables

### 8.1 Time window

**Post-COVID steady-state sample.** Pre-treatment: 2021Q1–2022Q3 (7 quarters). Buffer (dropped): 2022Q4 (ChatGPT launched 30 Nov 2022; Q4 averages are 2/3 pre-launch, biasing τ toward zero if included as treated). Post-treatment: 2023Q1–2025Q4 (12 quarters). Primary unit of time: annual for the 7-country panel (2021, 2022, 2023, 2024, 2025 — 5 years); quarterly for the 5-country event study.

**Deliberate design choice:** We exclude the 2015–2020 pre-COVID period even where data exist. Rationale: COVID differentially affected high-exposure cognitive occupations (remote-work migration, differential sectoral reallocation) vs low-exposure manual/service occupations (in-person disruption, informalization). Including pre-COVID periods would compare labor markets operating in two structurally different equilibria, violating the comparability requirement for the DiD control group. Starting from 2021Q1 ensures both the treatment and control time series are drawn from the post-COVID steady state. This framing aligns with \citet{BergBZ2018_ai_inequality} on regime-shift identification and with the post-COVID labor-market literature documenting occupation-specific COVID responses.

**Trade-off acknowledged:** 7 pre-period quarters is shorter than the canonical DiD literature. This is mitigated by: (i) elevating Honest-DiD bounds (\citet{RambachanRoth2023_honest}) from robustness to core identification (§4.3) — the method is designed for short pre-periods; (ii) replacing temporal placebo tests (2019, 2021) with cross-sectional placebos on ζ=0 occupations; (iii) placebo outcomes tests on variables that should not respond to LLM exposure (hours worked by agricultural manual laborers); (iv) extended post-period (12 quarters vs typical 4-8) compensates for shorter pre-period in aggregate sample size.

### 8.1.1 Survey-frequency harmonization

Seven surveys span three native frequencies. Harmonization protocol (executed in `scripts/R/02_harmonize_surveys.R`):

| Country | Survey | Native frequency | Harmonization to quarterly |
|---------|--------|------------------|----------------------------|
| Chile | ENE | Monthly (rolling-quarter trimestre móvil) | Non-overlapping **calendar** quarters: EFM (Q1), AMJ (Q2), JAS (Q3), OND (Q4) — aligns with Mexico/Costa Rica/Colombia/Ecuador calendar-quarter convention and keeps OND 2022 cleanly as the buffer drop |
| Colombia | GEIH | Monthly | Pool 3 months per quarter; stack observations |
| Ecuador | ENEMDU | Monthly (continuous since 2020) | Pool 3 months per quarter; stack observations |
| Costa Rica | ECE | Quarterly native | Use as-is |
| Mexico | ENOE | Quarterly native | Use as-is |
| Peru | ENAHO | Annual | Use as-is (annual analysis only) |
| Uruguay | ECH | Annual | Use as-is (annual analysis only) |

For annual aggregation, we average quarterly cell means weighted by survey expansion factors. Monthly-to-quarterly stacking preserves all original observations and the cross-sectional weighting within the quarter.

### 8.2 Occupation coding

- **Primary:** ISCO-08 4-digit (~400 codes/country).
- **Fallback:** 3-digit (~130 codes) — declarative rule when 4-digit cell size $< 100$ obs per country-year (§14 Item 2 closed).
- Crosswalk: SOC-2010 → ISCO-08 per \citet{Azuara2024_idb_ai} validated for Chile/Mexico/Peru; M1 deliverable for Colombia/Costa Rica/Ecuador/Uruguay.

### 8.3 Sample-size diagnostics

Diagnostic table per country × year: number of 4-digit occupations, median/min cell size, share of workers in cells <100 obs. Auto-fallback to 3-digit if a country has >20% of workers in small cells. Decision rule executed in scripts.

### 8.4 Exposure variables

Primary: Eloundou $\zeta$. Robustness: $\alpha$, $\beta$, Webb 2020, Felten AIOE, Handa realized-Claude-usage.

### 8.5 Outcomes

**Paper 1:** employment indicator (LPM primary, logit robustness with boundary check for high-employment cells), weekly hours, log hourly wage. **Paper 2:** RIF percentiles, formal/informal status, pension, health, contract, self-employment, unemployment.

### 8.6 Controls

Individual: age, age², gender, 4 education dummies, urban, household head, # children. Occupation: routine-task intensity (Autor-Levy-Murnane), pre-2019 mean wage. Country × time: $\alpha_{ct}$.

### 8.7 Wage deflation and comparability

**[REVISED — Fix 9, §14 Item 6 closed]** PRIMARY: within-country log wage (deviation from country-year mean) for pooled regressions — keeps the unit interpretable and avoids PPP measurement noise driving cross-country contrasts. SECONDARY: 2019 USD PPP via WDI conversion factors, used only for cross-country comparison tables (descriptive Table 1, not headline regressions). Country-month CPI deflation throughout.

---

## §9. Statistical Power

### 9.1 MDE calculation

Pooled MDE for log wages with $\sigma_Y \approx 0.6$, ~400 occupation clusters × 7 countries × 3+ post years:

$$
\text{MDE} \approx 2.8 \cdot \frac{\sigma_Y}{\sqrt{N_{\text{clusters}} \cdot n_{\text{per cluster}} / \text{DEFF}}} \approx 0.5\text{--}1.0\%
$$

We can detect a 1% wage effect at 80% power — well below Hartley/Chen and just above the Humlum-Vestergaard null zone. Denmark-null results would be detectable as "not distinguishable from zero."

### 9.2 Country-level power

Per-country MDE 2–3% in Uruguay, Costa Rica (smaller samples). Pooled estimates primary; country-specific underpowered cells flagged in heterogeneity tables.

### 9.3 Why 7 countries beats 1

7× cluster count vs. single country; pooled ACRT strictly more precise.

---

## §10. Pre-Analysis Plan (PAP) Checklist

Per \citet{Burlig2018_pap} guidance for non-experimental PAPs.

### 10.1 Hypotheses

- **H1:** $\bar\tau^{\text{ACRT}} < 0$ on employment and hours.
- **H2:** $|\bar\tau_{\log w}|_{\text{LAC}} < |\tau_{\log w}|_{\text{Hartley/Chen}}$, with non-overlapping CIs.
- **H3:** $\tau^{(90)} > \tau^{(10)}$ in RIF.
- **H4:** CATTs heterogeneous across {gender, education, age, baseline formality} at 10% after MTC.

### 10.2 Sample restrictions

Working-age (15–65); exclude student-only status; exclude ISCO major group 0 (military); exclude occupations with missing/imputed Eloundou at <3-digit; exclude negative/zero wages; winsorize log hourly wages at 1% tails country-year specific.

### 10.3 Pre-specified estimator

Primary: CGBS 2024 continuous DiD; parametric companion with $\alpha_{oc}, \alpha_{ct}$; occupation-clustered SE with wild bootstrap when clusters <50.
Secondary: binary CS, SA event study, Bartik. DDD as gated triangulation.
Robustness: Honest-DiD, Oster bounds, alternative exposures, alternative ISCO levels, alternative weighting.

### 10.4 Heterogeneity

Per §5.1: country, baseline formality (primary), gender, education, age, sector, skill, urban/rural. Causal forest exploratory.

### 10.5 Robustness tests

Honest-DiD $\bar M$ bounds (core given short pre-period, not merely robustness); cross-sectional placebo on $\zeta=0$ occupations; placebo outcomes on LLM-irrelevant variables (agricultural manual hours); alternative exposures (Webb, Felten, Handa); drop-one-country (Mexico nearshoring); alternative cutoffs; alternative controls; alternative cluster structures; Bartik with 2019 vs 2021 shares; DDD with placebo-demeaned Trends.

### 10.6 What counts as a null

$|\hat{\bar\tau}| < 1\%$ on employment and $<2\%$ on wages; 95% CI includes zero; Honest-DiD $\bar M < 1$. Triggers Narrative B; if both aggregate and baseline-formality interaction are null, paper reframed as first LAC null-replication of Humlum-Vestergaard.

### 10.7 Multiple-testing correction — **[REVISED — explicit tree]**

The MTC tree:

```
LEVEL 1 — Primary outcomes (3): employment, hours, log wage
   No correction within (ex-ante co-primary).

LEVEL 2 — Secondary distributional outcomes (Paper 2, 6 outcomes):
   formal employment, pension, health, contract, self-employment, unemployment.
   Romano-Wolf stepdown WITHIN this family.

LEVEL 3 — Heterogeneity dimensions (8):
   country, baseline formality, gender, education, age, sector, skill, urban/rural.
   For each dimension, Romano-Wolf stepdown WITHIN dimension across subgroup ATTs.
   Bonferroni ACROSS dimensions as conservative second layer (target FWER 10%).

LEVEL 4 — Causal forest CATEs:
   Reported with honest CIs (Athey-Wager 2018) — no further correction (exploratory, not pre-registered).
```

### 10.8 Pre-registration timing

OSF pre-registration in M3, before running CGBS continuous DiD on 2023+ data.

---

## §11. Implementation Plan

### 11.1 Software stack

R 4.4+. Packages: `fixest`, `did` (continuous extension), `HonestDiD`, `rifreg`/`dineq`, `grf`, `sensemakr`, `bacondecomp`, `ShiftShareSE`, `fwildclusterboot`, `haven`, `dplyr`, `data.table`, `survey`. Auxiliary: Python (Cloudflare Radar API if used); Stata 18 (`csdid`, `jwdid` cross-checks).

### 11.2 Code organization

```
scripts/R/
├── 00_master.R
├── 01_data_prep/         # crosswalk, exposure, harmonize, baseline formality imputation
├── 02_descriptive/
├── 03_did_primary/       # CGBS, CS, SA
├── 04_robustness/        # Honest-DiD, placebos, DDD (gated), Bartik, alt exposure, Oster
├── 05_heterogeneity/     # subgroups (baseline F primary), causal forest
├── 06_paper2/            # RIF, Oaxaca, social protection
└── 99_tables_figures/
```

### 11.3 Computational resources

Local workstation sufficient. Causal forests ~2h/outcome; CGBS ~30min/outcome; Honest-DiD ~4h total.

### 11.4 Replication package

Per JLE standard \citep{Vilhuber2020_reproducibility}: raw-data pointers (license-restricted), harmonized panel as CSV+parquet (where permitted), numbered R scripts, `Makefile`, `renv.lock`, pinned `sessioninfo()`.

---

## §12. Critical Risks to the Design

(Unchanged structure; updated to reflect Round 2 revisions.)

### 12.1 Data risks

| Risk | Detection | Mitigation | Fallback |
|---|---|---|---|
| ISCO crosswalk <80% match | Match-rate diagnostic | Manual patches | 3-digit; drop country |
| 4-digit cells too small | Sample-size diagnostic | Auto-fallback to 3-digit | Pool small countries |
| Google Trends near-zero variance | $\sigma(A_c)/\bar A_c < 0.20$ threshold (§3.3) | Drop DDD from main paper | Lean on placebo + Bartik |
| Survey methodology breaks 2020–2022 | Documentation audit | Sample-break FE | Per-country separate analysis |

### 12.2 Identification risks

| Risk | Detection | Mitigation | Fallback |
|---|---|---|---|
| Pre-trends fail | Event study + $F$-test | Honest-DiD primary; document $\bar M$ | Synthetic control; descriptive pivot |
| Placebos "work" | Placebo spec | Diagnose confounder; condition | Limitation note |
| Spillovers dominate | Industry-FE robustness | Bound and report both | Interpret as lower bound |
| Exposure measures disagree | Multi-exposure table | Emphasize consensus | Frame around Handa realized usage |
| Oster bound includes zero | `sensemakr` $\delta=1, R^2_{\max}=1.3R^2$ | Require $\bar M \geq 2$ to retain | Demote headline to robustness |

### 12.3 Publication risks

| Risk | Detection | Mitigation | Fallback |
|---|---|---|---|
| Replicate Humlum-Vestergaard null | Aggregate $\bar\tau$ tight on 0 | Narrative B (§7.2) | Downshift JLE → AEJ:Applied |
| Driven by 1–2 countries | Drop-one table | Heterogeneity feature | Single-country deep dive |
| Baseline-formality channel null | $\tau_F = \tau_I$ test | Narratives A or B | Reframe as precise zero |
| Referee demands structural | At review | Defend reduced-form scope | Stripped task-based appendix |

---

## §13. Timeline

| Months | Milestone |
|---|---|
| M1 | Data harmonization, ISCO validation, baseline-formality imputation pipeline |
| M2 | Exposure imputation; descriptive stats; pre-trend plots |
| M3 | **OSF pre-registration** |
| M4–M5 | Primary DiD (CGBS, CS, SA); pooled and country-by-country |
| M6 | Robustness (Honest-DiD, placebos, DDD-gated, Bartik, alt exposures, Oster) |
| M7 | Heterogeneity (baseline formality primary; causal forests) |
| M8 | Paper 2 (RIF, Oaxaca, social protection) |
| M9–M10 | Paper 1 draft |
| M11 | Paper 2 draft |
| M12 | Pre-submission review, seminar, JLE submission |

---

## §14. Open Decisions — **[REVISED — Fix 9: Most items closed]**

Closed (decisions, not open items):

- **Item 2 — 4-digit vs 3-digit ISCO.** CLOSED. 4-digit primary; declarative fallback rule to 3-digit when cell size < 100 observations per country-year.
- **Item 3 — 2022Q4 buffer.** CLOSED. Drop 2022Q4 as primary; include as robustness (§4.2 Fix 6).
- **Item 4 — Bolivia / Dominican Republic / Barbados.** CLOSED. Excluded due to ISCO incompatibility. Not revisiting.
- **Item 6 — USD PPP vs within-country log wage.** CLOSED. Within-country log wage as primary; USD PPP for cross-country comparison tables only (§8.7).
- **Item 7 — Humlum-Vestergaard bibkey.** CLOSED. `HumlumVestergaard2025_llm`.

Genuinely open (require user input or implementation-stage data probing):

- **Item 1 — Adoption-intensity measure for triple-diff (§3.3).** Google Trends primary, with two secondaries from: app-store rankings, Cloudflare Radar API traffic, World Bank Business Pulse 2023. Selection depends on data-access probes in M1–M2.
- **Item 5 — Bartik unit of observation (§3.4).** Local labor market = province (Mexico, Peru, Colombia, Ecuador), region (Chile), canton (Costa Rica), department (Uruguay). Harmonize to ~100–150 markets/country. Mapping table is an M1 deliverable.

---

## Files referenced

- Research spec: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/research_spec_genai_lac.md`
- Decision record: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/decisions/discovery_genai_lac.md`
- Literature review: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/lit_review_genai_lac.md`
- Librarian-critic report: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/lit_review_critic_genai_lac.md`
- Strategy memo R1 critic report: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/strategy_memo_critic_genai_lac.md`
- Domain profile: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/.claude/references/domain-profile.md`
- Bibliography: `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/Bibliography_base.bib`

---

## Revision Log — Round 2

Responding to strategist-critic R1 (84/100, REVISE). All 10 required fixes applied; recommended improvements integrated where flagged.

### Required fixes — applied

| # | Fix | Location(s) in revised memo | Status |
|---|---|---|---|
| 1 | ACRT estimand — defend score-as-dose via Handa 2025 | §1.2 (added interpretive caveat paragraph) | Fully addressed |
| 2 | FE identification table | §2.2 (replaces hand-wavy paragraph with 3-row table) | Fully addressed |
| 3 | Baseline formality $F_{i,2021}$ as primary; imputation protocol; demote contemporaneous to descriptive joint distribution | §5.2 (rewritten); §5.1 (table updated) | Fully addressed |
| 4 | DDD demoted to triangulation; variance threshold; placebo-demeaning by cryptocurrency Trends | §3.3 (rewritten); §3.6 (status column updated) | Fully addressed |
| 5 | Bartik: explicit time structure; Rotemberg weights; top-occupation-drop robustness; share-period mismatch acknowledged | §3.4 (rewritten with equations and protocol) | Fully addressed |
| 6 | Invert 2022Q4 — drop as primary, include as robustness | §2.1, §4.2 | Fully addressed |
| 7 | Add Narrative D (complementarity-dominates / Brynjolfsson-Chen) | §7.4 (new subsection) | Fully addressed |
| 8 | Resolve 5 placeholder citations | Bibliography appended; memo updated to use `SolonHW2015_weight`, `AbadieAIW2023_cluster`, `BergBZ2018_ai_inequality`, `Burlig2018_pap`, `Vilhuber2020_reproducibility` | Fully addressed |
| 9 | Close §14 false-open decisions (Items 2, 3, 4, 6, 7) | §14 reorganized into Closed vs Open | Fully addressed |
| 10 | Wild cluster bootstrap for <50 clusters | §2.5 (added paragraph; `fwildclusterboot` added to §11.1) | Fully addressed |

### Recommended improvements — integrated

- Oster bounds: §4.4 with $\delta = 1, R^2_{\max} = 1.3 R^2$; failure criterion (identified set contains zero) integrated into §12.2 risks.
- External-validity paragraph: §7.6 (sub-Saharan Africa, South Asia analogues with caveats).
- Multiple-testing tree explicit: §10.7 rewritten as a four-level tree.
- LPM boundary check: §8.5 ("LPM primary, logit robustness with boundary check for high-employment cells").

### Recommended improvements — partially addressed

- SUTVA quantitative bound (within- vs cross-industry): §4.5 retains the qualitative defense (industry-FE placebo, firm-size heterogeneity) plus the \citet{BergBZ2018_ai_inequality} narrative bound; a fully quantitative within-vs-cross-industry decomposition is deferred to the analysis stage when data structure is known. Flagged as residual.

### Residual risks

1. **Score-as-dose interpretation (§1.2).** Even with Handa 2025 validation, a hostile referee may insist that predicted exposure is a measurement-with-error problem requiring an errors-in-variables correction. Mitigation: report Handa-realized-usage as a robustness exposure measure (already in §8.4); if magnitudes shift, lead with Handa.
2. **Baseline-formality cell imputation (§5.2).** For 6 of 7 countries we impute $\hat F_{i,2021}$ from cell shares, not from individual histories. This introduces measurement error in the interaction. Mitigation: report Mexico ENOE (rotating panel, cleanest baseline) as the within-paper benchmark; if Mexico's baseline-F effects diverge from cell-imputed countries, document and discuss.
3. **DDD diagnostic cutoffs ($\sigma/\bar A_c < 0.20$, $\bar M \geq 2$).** Thresholds are pre-committed but somewhat arbitrary. Robustness: report results at $0.15$ and $0.25$, and at $\bar M = 1.5$ and $2.5$, in an appendix.
4. **Bartik share-period gap (2019 → 2023).** Acknowledged in §3.4. If a referee pushes on share endogeneity post-COVID, fallback is to use 2015–2019 average shares as the primary.
5. **External validity beyond LAC (§7.6).** One paragraph is the minimum; a hostile referee may demand more. Mitigation: a more developed external-validity discussion can be added at the writer phase if Narratives A or C are realized.

The design is ready for the coder phase. Round 2 revisions do not require re-running the discovery or literature phases.

*End of strategy memo R2. Re-review by strategist-critic to follow.*
