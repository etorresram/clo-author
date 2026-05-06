# CLAUDE.md — Estado del Proyecto

**Proyecto:** IA Generativa y Mercados Laborales — Evidencia Causal y el Rol de la Informalidad en América Latina
**Autor:** Eric Torres (PUCP, Doctorado en Economía)
**Fecha:** 2026-05-06

---

## 1. Objetivo

Estimar el efecto causal del lanzamiento de ChatGPT (Nov-2022) sobre resultados laborales (empleo, horas, ingresos, formalidad) en **6 países LAC**: Costa Rica, Colombia, Ecuador, México, Perú y Uruguay.

- **Diseño:** DiD con tratamiento continuo (CGBS 2024) usando exposición ocupacional β de Eloundou et al. (2023).
- **Crosswalk:** O*NET SOC-2010 → SOC-2018 (bridge) → ISCO-08 → clasificadores nacionales.
- **Robustez:** Sun-Abraham, LP-DiD (Dube et al. 2023), Roth (2022) pretest, dCDH (2022).
- **Dos papers:** (1) efectos laborales agregados; (2) desigualdad y protección social (RIF, Oaxaca-Blinder).

---

## 2. Estado: Splicing Google Trends (pytrends)

**Propósito:** Figura 1 (motivación) — interés relativo por "ChatGPT" en los 6 países, 2020–2025.

**Estado:** Completado e imputado.

- Datos vía `pytrends` por bloques (límite Google: 5 términos por consulta).
- **Splicing:** series por país reescaladas con país pivote común para una sola escala 0–100 comparable.
- Imputación de huecos con interpolación lineal mensual.
- Outputs:
  - `data/cleaned/trends/trends_chatgpt_imputed.csv`
  - `data/cleaned/trends/trends_others_imputed.csv`
- Figura generada por `scripts/python/build_intro_trends_figure.py` → `paper/figures/descriptive/fig1_chatgpt_intro.pdf` (B&N, sobria).

---

## 3. Archivos Clave

### Paper
- `paper/main.tex` — fuente principal (español, APA 7, biblatex+biber).
- `paper/preambles/preamble.tex` — APA 7 (`maxbibnames=99, maxcitenames=2`), babel español.
- `paper/sections/introduction.tex` — 6 países, β como exposición primaria.
- `paper/sections/theoretical_framework.tex` — Acemoglu-Restrepo, P1–P4.
- `paper/sections/methodology.tex` — DiD país por país, EPEN caveat (Lima Met.), pretests.
- `paper/talks/asesor_presentation.tex` — Beamer B&N para asesor (entrega parcial).
- `Bibliography_base.bib` (root y `paper/`, sincronizadas).

### Datos Perú
- `/Users/etorresram/Desktop/Thesis files/raw_data/Peru/Trimestral/` — 20 .sav (EPE 2021Q1–2022Q3, EPEN 2022Q4–2025Q4).
- Programa Stata `epe2epen` (V3) — equivalencia Ficha Técnica + lowercase.
- Programa Stata `build_clean` (V2) — base de ocupados con variables en inglés.

### Crosswalks
- `/tmp/co95_cno2015_raw.txt` — borrador parcial CO-95 → CNO-2015 (~400 filas).
- `/Users/etorresram/Desktop/Thesis files/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx` — fuente autoritativa (pendiente de leer).
- `/Users/etorresram/Desktop/Thesis files/Clasificador_Nacional_de_Ocupaciones_9_de_febrero.pdf` — doc. técnico INEI.

### Scripts
- `scripts/R/03_build_exposure.R` — bridge SOC-2010↔SOC-2018, scores Eloundou (92/100).
- `scripts/python/build_intro_trends_figure.py` — Figura 1.
- `/tmp/recover_peru_epe.py` — recuperación URLs INEI.

---

## 4. Próximos Pasos

1. **Procesar** `Tablas_de_correspondencia_CNO_CIUO_CO.xlsx` — extraer mapeo autoritativo CO-95 ↔ CNO-2015 ↔ CIUO-08.
2. **Test empírico Perú** — verificar en Stata si EPE usa CO-95 (3 díg.) o ya CNO-2015; chequear `c308_cod` pre y post 2022Q4.
3. **Aplicar crosswalk** a EPE (2021Q1–2022Q3) para alinear con CNO-2015 (4 díg.) de EPEN.
4. **Construir panel limpio Perú** con códigos ocupacionales consistentes pre/post.
5. **Re-descargar** raw data de los 5 países restantes (CO, CR, EC, MX, UY).
6. **Mapear exposición β** a clasificador nacional de cada país (SOC-2018 → ISCO-08 → nacional).
7. **Estimar DiD** país por país (CGBS continuo) + meta-análisis pooled.
8. **Llenar abstract** (`XXX` placeholder en `main.tex`).

---

## Notas operativas

- Worktree activo: `/tmp/clo-paper-mods/` (no tocar `main` directamente).
- Sin em-dashes (—). Sin primera persona plural (we/our → I/my).
- `Bibliography_base.bib`: mantener sincronizado entre root y `paper/`.
