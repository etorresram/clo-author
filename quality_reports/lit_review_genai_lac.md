# Literature Review — Gen AI & LAC Labor Markets

**Project:** Labor Market and Distributional Impact of Generative AI — Causal Evidence for Latin America
**Author:** Eric Torres (PUCP)
**Phase:** `/discover lit` (librarian)
**Date:** 2026-04-20

Proximity scale: **1** = directly competes · **2** = closely related (LLM/AI, different method/setting) · **3** = related (AI/automation & employment, different angle) · **4** = background (theory/method/context) · **5** = tangentially related.

Seminal references already catalogued in `Bibliography_base.bib` (Eloundou 2023, Azuara 2024, Hartley 2024, Chen 2025, Hui 2024, Liu 2025, Handa 2025, Brynjolfsson 2023, Callaway-Sant'Anna 2021, Sun-Abraham 2021, Goodman-Bacon 2021, Callaway-GB-Sant'Anna 2024, Borusyak-Jaravel-Spiess 2024, Firpo-Fortin-Lemieux 2009, Goldsmith-Pinkham-Sorkin-Swift 2020, Acemoglu-Restrepo 2020, Acemoglu-Autor 2011, Webb 2020, Felten 2023, Ciaschi 2025, Egana-del Sol 2025, Benitez-Parrado 2024, World Bank 2024, etc.) are **not** re-summarized here except where their positioning in the frontier map requires it.

---

## Task 1 + 2 · Inventory of Folder PDFs (32 files)

### A. Directly-related / closest-competitor papers (Proximity 1–2)

Most of the proximity-1 folder PDFs are **already in `Bibliography_base.bib`**. Summaries below are positioning notes, not duplicates.

#### Azuara, Ripani & Torres (2024) — "AI and the Increase of Productivity and Labor Inequality in LAC" [IDB]
- **Proximity:** 1 (antecedent — co-authored by project PI)
- **Contribution:** Estimates *potential* LLM exposure for Chile, Mexico, Peru; documents exposure tilts toward formal, female, urban, educated workers.
- **Identification:** **Descriptive** — exposure only, no causal design.
- **Relevance:** Direct predecessor. This project extends from 3 countries → 7, and from exposure → **causal DiD**.

#### Hartley, Jolevski, Melo & Moore (2024) — "Labor Market Effects of Generative AI" [SSRN]
- **Proximity:** 1
- **Contribution:** US CPS, DiD around ChatGPT launch with Eloundou exposure; finds measurable wage responses in high-exposure occupations.
- **Identification:** DiD, binary exposure cutoff at median; TWFE + event study.
- **Relevance:** **The closest methodological competitor.** Paper 1 replicates the design for LAC and contrasts magnitudes.

#### Chen, Kane, Kozlowski, Kuniesvky & Evans (2025) — "The (Short-Term) Effects of LLMs on Unemployment and Earnings" [arXiv 2509.15510]
- **Proximity:** 1
- **Contribution:** US, synthetic DiD; finds ~$89/week earnings increase in high-exposure occupations; unemployment unchanged.
- **Identification:** Synthetic DiD with Eloundou exposure.
- **Relevance:** Direct contrast point. H2 (LAC wage complementarity muted) is tested against this benchmark.

#### Hui, Reshef & Zhou (2024) — "Short-Term Effects of Generative AI on Employment" [*Org Science*]
- **Proximity:** 1
- **Contribution:** Upwork/online labor market; DiD shows demand for writing/translation drops 20–50% post-ChatGPT; earnings fall 2–5%.
- **Identification:** DiD across skill categories; ChatGPT launch as shock.
- **Relevance:** Strongest evidence of **displacement** — a natural "upper bound" for LAC-formal-sector effects given higher adoption in online/gig markets.

#### Liu, Xu, Nan, Li & Tan (2025) — "'Generate' the Future of Work Through AI" [arXiv 2308.05201]
- **Proximity:** 1
- **Contribution:** Online labor market data; DiD; binary p50 exposure cutoff.
- **Identification:** DiD, treatment = high-exposure.
- **Relevance:** Methodological template for binary robustness spec.

#### Humlum & Vestergaard (2025) — "Large Language Models, Small Labor Market Effects" / "Still Waters, Rapid Currents" [NBER WP 33777]
- **Proximity:** 1 — **critical addition, not in current bib**
- **Contribution:** Denmark admin data linked to adoption survey of 100k workers across 11 exposed occupations. DiD rules out effects >2% on earnings/hours two years post-launch. Adoption widespread but time-savings only 2.8%.
- **Identification:** DiD at worker and workplace level; adoption survey provides first-stage on actual usage.
- **Relevance:** **The most important recent paper the folder is missing.** Key contrast: Denmark = high-adoption, strong-formal-labor context yet near-zero effects. If LAC effects are small, Humlum-Vestergaard is the natural cite; if LAC effects are large, the contrast with Denmark (adoption high, effects null) must be explained.

#### Brynjolfsson, Li & Raymond (2023) — "Generative AI at Work" [NBER 31161]
- **Proximity:** 1
- **Contribution:** RCT in customer-service call center; 14% productivity increase, concentrated among less-skilled workers.
- **Identification:** Firm-level RCT — cleanest causal identification in the literature.
- **Relevance:** Benchmark for complementarity channel. External validity to LAC is unclear; cited as motivating evidence, not direct comparison.

#### Handa et al. (2025) — "Which Economic Tasks Are Performed with AI? Evidence from Claude Conversations" [arXiv 2503.04761]
- **Proximity:** 2
- **Contribution:** Maps actual Claude API usage to O*NET tasks — reveals what tasks AI is *actually* performing vs the Eloundou predicted.
- **Identification:** Descriptive (observational usage data).
- **Relevance:** Use as robustness check — does realized-task exposure predict LAC outcomes better than predicted exposure?

#### Eloundou, Manning, Mishkin & Rock (2023/2024) — "GPTs are GPTs" [arXiv + *Science* 2024]
- **Proximity:** 1 (for the measure)
- **Contribution:** Occupational exposure scores α, β, ζ for US SOC occupations.
- **Identification:** Human + GPT-4 rubric scoring of O*NET tasks.
- **Relevance:** **Core treatment variable.** α = direct exposure; ζ = upper-bound. Project uses ζ.

#### Agrawal, Gans & Goldfarb (2019) — "AI: The Ambiguous Labor Market Impact of Automating Prediction" [*JEP*]
- **Proximity:** 3
- **Contribution:** Theory — AI as prediction machine; ambiguous net effect on labor demand.
- **Identification:** Theoretical.
- **Relevance:** Motivates the displacement-vs-complementarity framing.

#### Georgieff (2024) — "AI and Wage Inequality" [OECD AI Papers 13]
- **Proximity:** 2
- **Contribution:** Cross-country analysis; finds high-exposure occupations show greater wage dispersion especially at top.
- **Identification:** Descriptive cross-country correlations.
- **Relevance:** Motivates Paper 2 distributional framing.

---

### B. Theoretical foundations & canonical automation literature (Proximity 3–4)

#### Autor, Levy & Murnane (2003) — "The Skill Content of Recent Technological Change" [*QJE*]
- **Proximity:** 3 · **Method:** descriptive decomposition
- **Contribution:** RBTC framework; computers automate routine cognitive tasks.
- **Relevance:** The framework **LLMs break** — non-routine cognitive tasks now affected. Essential citation in Introduction and Theoretical Framework.

#### Acemoglu & Restrepo (2018) — "The Race Between Man and Machine" [*AER* 108(6)]
- **Proximity:** 4 · **Method:** theoretical
- **Contribution:** Automation + reinstatement framework; balanced-growth path requires new-task creation.
- **Relevance:** **Theoretical backbone** (displacement vs reinstatement). Currently missing from `Bibliography_base.bib` — add.

#### Acemoglu & Restrepo (2018, NBER WP 24196) — "AI, Automation, and Work"
- **Proximity:** 4 · **Method:** theoretical extension
- **Contribution:** Applies task-based framework to AI.
- **Relevance:** Companion to the 2018 AER paper.

#### Acemoglu & Restrepo (2022) — "Tasks, Automation, and the Rise in US Wage Inequality" [*Econometrica* 90(5)]
- **Proximity:** 3 · **Method:** task-displacement regressions
- **Contribution:** 50–70% of 1980–2016 US wage-structure changes explained by task displacement in automating industries.
- **Relevance:** **Paper 2 core citation** — same mechanism, new technology. Missing from base bib.

#### Acemoglu & Restrepo (2020) — "Robots and Jobs" [*JPE*] (already in bib)
- **Proximity:** 3 · **Method:** IV shift-share.
- **Relevance:** Methodological template for robustness — include robot exposure as a pre-period control.

#### Agrawal, Gans & Goldfarb (2019) [folder /AUTOMATION/]
- See above (A).

#### Folder /AUTOMATION/ misc (Frey-Osborne-era forecasting papers, firm-level China/Taiwan papers)
- **Proximity:** 4–5
- **Verdict:** Background context only; cite at most 1–2 in Introduction.

---

### C. DiD methodology (Proximity 4 · already in bib except as noted)

- **Callaway & Sant'Anna (2021)** — CS estimator, primary secondary estimator.
- **Callaway, Goodman-Bacon & Sant'Anna (2024)** — Continuous DiD, **primary estimator**.
- **Sun & Abraham (2021)** — Event study estimator.
- **Goodman-Bacon (2021)** — TWFE decomposition.
- **Borusyak, Jaravel & Spiess (2024)** — Imputation estimator.
- **de Chaisemartin & D'Haultfœuille (2020)** — TWFE critique.
- **Rambachan & Roth (2023)** — **MISSING from bib.** Honest-DiD partial-identification under pre-trend violations. *Essential for robustness section.* Proximity 4, but functionally required for the paper's defense of parallel trends.
- **Roth, Sant'Anna, Bilinski & Poe (2023)** — **MISSING from bib.** Synthesis of modern DiD. Cite once as "modern DiD survey."

#### DiD_slides_LACEA_handout.pdf (folder)
- **Proximity:** 5 — teaching slides, not citable.

---

### D. Systematic reviews & context (Proximity 4–5)

#### Budhwar & Malik (2023) — AI on employee skills/well-being
#### Filippucci et al. (2022) — AI and work, critical review
- **Proximity:** 4
- **Relevance:** Reference in Introduction's "this literature is growing rapidly" paragraph. Not core.

---

### E. AI skills-demand (folder /skills/) — Proximity 4–5

- **Alekseeva et al. (2021)** — *Labour Economics* — demand for AI skills; cite as "AI adoption measured through postings."
- Other 4 papers (China manufacturing, Denmark skills, statistics, China employment structure): **Proximity 5.** Do not cite unless a specific numerical claim requires it.

---

### F. Country-level firm-data papers (Proximity 4–5)

- Yang 2022 (Taiwan firm panel), China AI labor 2020, BRICS governance 2024, virtual-agglomeration 2024, industrial structure 2024, banking/accounting 2022, pandemic comparison 2021, digital-economy 2023.
- **Verdict:** Heterogeneous quality, mostly Chinese-journal descriptive work. **Proximity 5.** Cite 0–1 of these.

---

### G. The "(IMPORTANTE)" paper in root folder

**"Artificial Intelligence and Employment: New Cross-Country Evidence 2022"** — most likely Georgieff & Hyee (OECD 2022, *Frontiers in AI*).
- **Proximity:** 2
- **Contribution:** Cross-country (OECD) analysis of AI exposure and employment; modest negative effects on hours in non-high-skill occupations.
- **Relevance:** Cross-country precedent that the current paper **extends to LAC**. Metadata needs confirmation (flagged UNVERIFIED in bib).

---

## Task 3 · Gap search — missing recent & methodological literature

### Critical additions (must add to bib before drafting):

1. **Humlum & Vestergaard (2025a,b)** — *Still Waters* / *Large Language Models, Small Labor Market Effects*. Denmark admin data, DiD, null effects. The single most important missing reference.
2. **Rambachan & Roth (2023)** — Honest DiD (*RES*). Required for pre-trends robustness.
3. **Roth, Sant'Anna, Bilinski & Poe (2023)** — DiD synthesis (*JoE*). One-shot cite in Methods.
4. **Acemoglu & Restrepo (2022)** — Task displacement & wage inequality (*Econometrica*). Paper 2's core mechanism citation.
5. **Acemoglu & Restrepo (2018)** — Race Between Man and Machine (*AER*). Theoretical backbone — **surprisingly missing** from the current bib despite being cited indirectly via AR 2020.
6. **Liu, Wang & Yu (2025)** — World Bank WP 11263; 285M US job postings, 12% decline in high-AI-exposure postings, rising to 18% by year 3. Strong demand-side evidence.
7. **Cui, Demirer, Jaffe et al. (2025)** — 3 RCTs, 4,867 software developers, +26% task completion. Benchmark complementarity estimate for high-skill cognitive work.
8. **Acemoglu, Autor, Hazell & Restrepo (2022)** — "AI and Jobs: Evidence from Online Vacancies" (*JLE*). Direct precedent for occupation-level exposure DiD; relevant for positioning in JLE.
9. **Agrawal-Gans-Goldfarb (2019)** — *JEP*. Already in folder, just not in bib yet.

### Nice-to-have (add if space):

- **Wiles (2025)** — "Generative AI and Labor Market Matching Efficiency" (Boston U WP). AI-drafted job posts: more postings, no more matches. Supports "reallocation, not destruction" frame.
- **Humlum & Vestergaard (2025, PNAS)** — Unequal adoption by gender/age/experience. Supports H4.

### Verified as present — don't duplicate:

Callaway/Sant'Anna (2021, 2024), Goodman-Bacon, Sun-Abraham, Borusyak-Jaravel-Spiess, Felten-Raj-Seamans, Webb, Azuara, Eloundou, Hartley, Chen, Hui, Liu, Brynjolfsson, Firpo-Fortin-Lemieux, Goldsmith-Pinkham et al., Oster, Athey-Wager, Handa, Ciaschi, Egana-del Sol, Benítez-Parrado, World Bank, Georgieff (OECD).

### Informal-sector + technology (LAC angle)

The current bib is thin here. Recommended additions (not yet verified in the folder — add via search):
- **Faber, Sarto & Tabellini (2022)** / **Artuc, Bastos & Rijkers (2023)** — local labor markets, automation in Brazil/Mexico.
- **"The impact of robots in Latin America"** (*World Development*, 2023) — robot exposure in LAC; informal-sector buffering.
- **IMF WP 2024/219** — "What Can AI Do for Stagnant Productivity in LAC?"
- **ILO (2024)** — GenAI jobs in LAC (ILO–World Bank joint publication).

These are **not in the folder** but should be added during drafting for the informality section.

---

## Task 4 · Frontier Map

### What's established

- **Exposure measures exist and converge:** Eloundou ζ scores, Felten AIOE, Webb patent-based, Handa realized-usage — all rank occupations similarly at the coarse level. High-exposure = cognitive, language-intensive, clerical/professional.
- **Adoption is rapid but uneven:** Humlum-Vestergaard (Denmark) documents ~50% adoption in exposed occupations within 18 months. Adoption skewed male, young, educated (PNAS 2025).
- **Short-term US effects on prices/demand are negative and small for substitutable tasks:** Hui 2024 (online writing −20% to −50%), Liu-Wang-Yu 2025 (job postings −12% rising to −18%), Demirol-type freelancer studies (−2% to −5%).
- **Firm-level RCTs show productivity gains concentrated among lower-skilled within treated occupations:** Brynjolfsson 2023 (+14% call-center), Cui-Demirer 2025 (+26% software developers, larger gains for juniors).
- **Cross-country OECD evidence:** Georgieff & Hyee 2022 — modest employment effects, concentrated in non-high-skill.

### What's contested

- **Net employment effect:** Hartley (US, negative hours), Chen 2025 (US, positive earnings, flat unemployment), Humlum-Vestergaard (Denmark, null earnings/hours). Sign of the wage effect is **unresolved**.
- **Who benefits/loses:** Brynjolfsson/Cui (low-skill within-occupation gains) vs Georgieff/OECD (high-skill capture gains via complementarity). The distributional story has two competing claims.
- **Adoption vs exposure:** Is predicted-exposure (Eloundou) a good proxy for realized usage (Handa)? The literature has not settled this.
- **Duration:** All current causal estimates are short-run (1–3 years). No paper has medium-run estimates.

### What's missing (where THIS paper fits)

1. **Causal evidence for LAC — none exists.** All LAC papers are exposure-only or descriptive (Azuara 2024, Benítez-Parrado 2024, Ciaschi 2025, Egaña-del Sol 2025, World Bank 2024, IMF 2024).
2. **Effects in high-informality contexts.** No paper examines whether informal workers are buffered from or amplified by displacement. The LAC context has the largest informal sector among regions with survey data of the needed granularity.
3. **Cross-country heterogeneity in adoption × exposure.** Georgieff-Hyee 2022 is OECD-only. A 7-country LAC design with within-region adoption variation (Google Trends) is new.
4. **Continuous-treatment DiD applied to AI.** Hartley, Chen, Hui, Liu all use binary cutoffs. Callaway-GB-Sant'Anna 2024 continuous DiD with Eloundou ζ is methodologically novel in this literature.
5. **Distributional analysis (Paper 2).** Only Georgieff 2024 and Acemoglu-Restrepo 2022 touch this — the latter for pre-LLM automation. RIF regressions applied to LLM exposure in a cross-country LAC panel are new.
6. **Honest-DiD robustness.** No AI-labor paper has yet applied Rambachan-Roth 2023 bounds. Doing so pre-emptively answers referee concerns.

---

## Task 5 · Positioning

### Against the direct competitors

- **vs Hartley et al. (2024):** Same design (DiD, Eloundou, ChatGPT shock), different country sample. Sell as "external validity to an adoption-heterogeneous, high-informality setting" — *not* as a US replication.
- **vs Chen et al. (2025):** They find positive earnings. We test whether complementarity holds in LAC. H2 is a **falsifiable contrast hypothesis** — if LAC replicates Chen, the paper's frame shifts to "surprising external validity"; if not, to "structure-of-labor-market moderates LLM effects." Either way, a substantive result.
- **vs Hui, Reshef & Zhou (2024):** Their setting (Upwork/global online market) is already partially LAC-relevant — many Upwork workers are LAC. Use Hui as the "upper-bound" benchmark: online-formal/nearshoring workers face the Hui-magnitude effect; domestic informal workers face something smaller.
- **vs Humlum-Vestergaard (2025):** **This is the reference class to beat.** They find null effects in Denmark — a high-adoption, strong-formal-labor context. If LAC also shows null, the explanation is "even with variation, early-stage LLM shock is too small to register in administrative data." If LAC shows effects, LAC-specific mechanisms (lower baseline protection, more informality → larger raw adjustments) become the story. The paper needs to position explicitly against Humlum-Vestergaard in the Introduction.
- **vs Azuara, Ripani & Torres (2024):** Extend 3 → 7 countries; exposure → causal; add distributional. Low-risk framing — the PI co-authored the antecedent.
- **vs Brynjolfsson et al. (2023):** Out-of-sample — their RCT in US customer service is an *upper bound* on the complementarity channel; LAC partial-equilibrium estimates from surveys cannot exceed the firm-level RCT.

### One-sentence pitch (for editor desk-review)

> "Using harmonized labor force surveys from seven Latin American countries and modern continuous-treatment difference-in-differences, this paper provides the first causal estimates of how the launch of ChatGPT affected employment and wages in a developing-region labor market, and documents that exposure-to-LLM effects are substantially smaller and more concentrated in the informal sector than estimates from the US and Denmark — a finding that informs AI-policy debates in regions where over half the labor force lacks formal protection."

### Target journals — editor-aware ranking

1. **Journal of Labor Economics (JLE)** — Best primary fit. Acemoglu-Autor-Hazell-Restrepo (2022, *JLE*) is the direct precedent. JLE has published AI-occupational-exposure DiD. Submit here first.
2. **Journal of Human Resources (JHR)** — Strong fit, especially for Paper 2 (distributional, equity-focused).
3. **AEJ: Applied** — If the identification is the strongest dimension of the paper (continuous DiD + Honest DiD + multiple exposure measures + shift-share). Harder but viable.
4. **RESTAT** — For Paper 1 if the cross-country panel structure is the headline feature.
5. **Journal of Development Economics** — Viable backup given the informality angle; slightly lower tier for labor-focused work.
6. **Labour Economics** — Safe fallback. Would accept the paper with a first-round R&R.
7. **ILR Review** — Appropriate if framed as labor-institutions-meet-AI.

**Aspirational (only with strong results + top identification):** *AER Insights* (short-paper format suits a clean contrast result); *QJE* is unlikely for a cross-country descriptive-DiD paper without structural novelty.

### Key positioning risks to pre-empt

- **"Just a replication of Hartley/Chen for LAC"** → Emphasize (i) cross-country heterogeneity as identification, (ii) informal-formal contrast, (iii) continuous DiD methodology.
- **"LAC adoption is too low for detectable effects"** → Google Trends first-stage; global-task-reallocation channel; heterogeneity by internet penetration.
- **"Eloundou is a US measure"** → Task content is predetermined, not a function of adoption. Robustness with Webb 2020 and Felten 2023. Pre-empt by citing Handa 2025 realized-exposure as alternative.
- **"Null results anywhere"** → Pre-register the null as informative (adoption-limits-effects mechanism). Reference Humlum-Vestergaard as a null-finding precedent.

---

## Files produced

- `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/lit_review_genai_lac.md` (this file)
- `/Users/etorresram/Documents/Claude/Claude code/clo-author/.claude/worktrees/eager-mendel/quality_reports/bibtex_new_entries.bib` (new entries for merge)

## Flagged items for user confirmation

1. Metadata UNVERIFIED for the following filenames (confirm via pdftotext before citing):
   - `(IMPORTANTE) Artificial Intelligence and Employment- New Cross-Country Evidence 2022.pdf` — very likely Georgieff & Hyee 2022, *Frontiers in AI*.
   - `Measuring the occupational impact of AI- tasks, cognitive abilities and AI benchmarks 2021.pdf` — likely Tolan, Pesole, Martínez-Plumed et al., JRC/EU.
   - Folder `/reviews/` entries — authorship to be confirmed.
2. Confirm which of the `/skills/` and miscellaneous firm-level papers (China, Taiwan, BRICS) the user actually wants to cite. Recommendation: cite at most 1 (Alekseeva 2021, *Labour Economics*) and drop the rest from the working bib.
3. The two Humlum-Vestergaard versions (NBER WP 33777 "Still Waters" vs "Large Language Models, Small Labor Market Effects" BFI WP 2025-56) may be the same paper retitled — verify which is the canonical reference at time of drafting.

---

*End of librarian report. The paired librarian-critic scores this artifact per `quality.md`.*
