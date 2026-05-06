# Literature Review — librarian-critic Report

**Date:** 2026-04-20
**Severity:** MEDIUM (Discovery phase)
**Target:** `lit_review_genai_lac.md` + `bibtex_new_entries.bib`
**Score:** 86/100 — **APPROVED FOR MERGE** with 4 required fixes

---

## Summary

Strong literature review for an early-phase project. The Librarian correctly identifies the single most important missing paper (Humlum-Vestergaard 2025), flags the missing modern DiD methods refs (Rambachan-Roth, Roth et al.), and adds AR 2022 Econometrica + AR 2018 AER. The frontier map is honest and well-scoped. Positioning against Hartley/Chen/Humlum is sharp and defensible. JLE-primary recommendation is well-grounded (AAHR 2022 is indeed in JLE). Proximity scores are largely well-calibrated.

Main deductions: (i) thin informality × technology literature — the paper's key contribution and most under-served section, (ii) BibTeX entries including a known error (mislabeled duplicate), (iii) some missing recent 2024-2026 causal/adjacent work.

---

## Required Fixes Before Merge

1. **Fix or delete** `DemirolRoussille2025_freelancer` — currently mislabeled duplicate of Hui et al. Delete (preferred) or replace with correct Demirol-Roussille entry.
2. **Resolve** Humlum-Vestergaard versioning — collapse to single canonical entry keyed `HumlumVestergaard2025_llm`.
3. **Verify** Georgieff & Hyee 2022 metadata before merge (Frontiers in AI is predatory-adjacent; confirm OECD-authored piece).
4. **Move** 4 low-proximity UNVERIFIED entries (Yang, Giuntella, Filippucci, Budhwar) to commented placeholder block.

## Recommended Improvements (Non-Blocking)

1. **Add informality-tech literature** before drafting Paper 1 §2: Faber 2020 (JIE), Artuc-Bastos-Rijkers 2023, Maloney-Molina 2019/2025, Beylis 2020 (World Bank COVID/tech LAC), Bustelo-Suaya-Vezza (IDB).
2. **Add 2024 adoption/experimental papers**: Bick-Blandin-Deming 2024 (NBER 32966), Noy-Zhang 2023 (Science), Peng et al. 2023 (Copilot RCT), Dell'Acqua et al. 2023 (BCG × GPT-4).
3. **Scan** for recent Aghion-Jaravel or Acemoglu-Autor-Johnson piece on AI and inequality.
4. **Re-label** AR 2018 NBER 24196 annotation to clarify it is the distinct "AI, Automation and Work" piece.

---

## Detailed Issues

### 1. Informality × technology literature thin (-6)
Section F ("Informal-sector + technology") is only four bullet points, all marked "not yet verified." Given this is the paper's central differentiating contribution, the Librarian should have surfaced Faber (2020, JIE) — canonical Mexico robot-exposure paper — plus Artuc-Bastos-Rijkers, Maloney-Molina, Beylis, Bustelo-Suaya-Vezza. This is the exact gap a JLE/JHR referee will flag.

### 2. Missing 2024-2026 recent papers (-4)
Noy-Zhang (2023, *Science*), Peng-Kalliamvakou-Cihon-Demirer (2023, Copilot RCT), Dell'Acqua et al. (2023, HBS BCG × GPT-4 "jagged frontier"), Bick-Blandin-Deming (2024, NBER 32966 adoption measurement) — all foundational in this literature and curiously absent.

### 3. BibTeX error: mislabeled duplicate (-5)
`DemirolRoussille2025_freelancer` has `author = {Hui, Xiang and Reshef, Oren and Zhou, Luofeng}` — same paper as `Hui2024_online_labor` already in base bib.

### 4. Too many UNVERIFIED in single deliverable (-2)
7/20 new entries flagged UNVERIFIED (35%). Acceptable for background entries, but high-proximity entries (Georgieff-Hyee) must be verified before merge.

### 5. Humlum duplicate not resolved (-2)
`HumlumVestergaard2025_still_waters` (NBER 33777) and `HumlumVestergaard2025_large_small` (BFI 2025-56) almost certainly same paper.

### 6. Minor methods gap (-1)
de Chaisemartin & D'Haultfœuille have a 2024 Restud/WP more current than their 2020 AER. Not critical — Callaway-Sant'Anna and Roth et al. 2023 cover the territory.

---

## What the Librarian Got Right

- Correctly prioritized Humlum-Vestergaard 2025 as THE most important missing reference.
- Rambachan-Roth 2023 + Roth-SantAnna-Bilinski-Poe 2023 correctly identified as must-adds for parallel trends defense.
- AR 2018 AER and AR 2022 Econometrica correctly flagged as missing theoretical backbone.
- AAHR 2022 (JLE) correctly identified as precedent paper → supports JLE-primary targeting.
- Frontier map is honest; the six "missing" items position the paper without overclaiming.
- Proximity scores well-calibrated overall.
- Positioning's "Humlum as reference class to beat" framing is exactly right.
- Journal ranking is realistic (JLE first, AEJ:Applied aspirational-but-viable, QJE flagged unlikely).

---

## Score Breakdown

| Item | Deduction |
|------|-----------|
| Informality literature thin | -6 |
| Missing 2024-2026 papers | -4 |
| BibTeX mislabeled duplicate | -5 |
| UNVERIFIED bloat | -2 |
| Humlum duplicate unresolved | -2 |
| Minor methods gap | -1 |
| **Bonus: exceptional positioning/pitch** | +6 |
| **Final** | **86/100** |

---

## Verdict

**APPROVED** for merge into `Bibliography_base.bib` after 4 Required Fixes. User can proceed to `/strategize` with this literature base; close the informality-literature gap during Strategy → Writing phase. No escalation.
