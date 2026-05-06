# ==============================================================================
# 14_results_figures.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 14 (publication-grade figures)
#
# Style notes (matching fig1_chatgpt_intro.pdf):
#   - Grayscale only (black + grays). No color.
#   - Serif font via cairo_pdf for proper Spanish accent rendering.
#   - Minimal grid (horizontal only).
#   - Distinguish series by linetype/shape, not color.
#
# Output: paper/figures/peru/*.pdf
# ==============================================================================

library(here)
library(data.table)
library(ggplot2)
library(patchwork)

out_dir <- here("data", "cleaned", "peru")
fig_dir <- here("paper", "figures", "peru")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

es_results  <- readRDS(file.path(out_dir, "event_study_results.rds"))
het_results <- readRDS(file.path(out_dir, "heterogeneity_formality.rds"))
panel       <- readRDS(file.path(out_dir, "epen_with_exposure.rds"))

# --- Common theme matching fig1_chatgpt_intro -------------------------------
gray_theme <- function(base = 10) {
  theme_minimal(base_size = base, base_family = "serif") +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_line(color = "gray85", linewidth = 0.25,
                                        linetype = "dotted"),
      axis.line          = element_line(color = "black", linewidth = 0.3),
      axis.ticks         = element_line(color = "black", linewidth = 0.3),
      plot.title         = element_text(face = "plain", size = base + 1),
      plot.subtitle      = element_text(size = base - 1, color = "gray30"),
      plot.caption       = element_text(size = base - 2, color = "gray30",
                                        hjust = 0)
    )
}

# ==============================================================================
# Figure 1: Three-panel event study (grayscale, serif)
# ==============================================================================
mk_es_panel <- function(tidy_dt, ylab, title) {
  setorder(tidy_dt, k)
  ggplot(tidy_dt, aes(x = k, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed",
               color = "gray40", linewidth = 0.4) +
    geom_vline(xintercept = -0.5, linetype = "dashed",
               color = "black", linewidth = 0.4) +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                    color = "black", size = 0.25, linewidth = 0.45) +
    scale_x_continuous(breaks = seq(-7, 12, 2)) +
    labs(x = NULL, y = ylab, title = title) +
    gray_theme()
}

p1 <- mk_es_panel(
  es_results$tidy$log_employment,
  expression(theta[k] %.% beta ~ "(log empleo)"),
  "(a) log empleo"
)
p2 <- mk_es_panel(
  es_results$tidy$mean_log_wage,
  expression(theta[k] %.% beta ~ "(log salario hora)"),
  "(b) log salario hora"
)
p3 <- mk_es_panel(
  es_results$tidy$mean_hours,
  expression(theta[k] %.% beta ~ "(horas semanales)"),
  "(c) horas semanales"
) + labs(x = "Trimestres relativos a t* (2022T4)")

# Title/subtitle/caption are intentionally left out: they go in the LaTeX
# \caption{} in results.tex (matching the paper's style — see fig1).
es_combined <- p1 / p2 / p3

ggsave(file.path(fig_dir, "fig_event_study_3panel.pdf"),
       es_combined, width = 7, height = 8.5,
       device = function(file, ...) quartz(type = "pdf", file = file, ...))

# ==============================================================================
# Figure 2: Heterogeneity by formality (grayscale, distinguish by shape)
# ==============================================================================
extract_het <- function(mod, label) {
  ct <- summary(mod)$coeftable
  data.table(
    outcome  = label,
    channel  = c("Formal", "Informal"),
    estimate = c(ct["x_F", "Estimate"], ct["x_I", "Estimate"]),
    se       = c(ct["x_F", "Std. Error"], ct["x_I", "Std. Error"])
  )
}

het_dt <- rbindlist(list(
  extract_het(het_results$interaction$log_employment, "(a) log empleo"),
  extract_het(het_results$interaction$mean_log_wage,  "(b) log salario hora"),
  extract_het(het_results$interaction$mean_hours,     "(c) horas semanales")
))
het_dt[, ci_lo := estimate - 1.96 * se]
het_dt[, ci_hi := estimate + 1.96 * se]
het_dt[, outcome := factor(outcome, levels = c("(a) log empleo",
                                               "(b) log salario hora",
                                               "(c) horas semanales"))]
het_dt[, channel := factor(channel, levels = c("Formal", "Informal"))]

fig_het <- ggplot(het_dt, aes(x = channel, y = estimate, shape = channel)) +
  geom_hline(yintercept = 0, linetype = "dashed",
             color = "gray40", linewidth = 0.4) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "black", size = 0.7, linewidth = 0.7) +
  facet_wrap(~ outcome, scales = "free_y", nrow = 1) +
  scale_shape_manual(values = c("Formal" = 16, "Informal" = 17)) +
  labs(x = NULL, y = "Efecto por unidad de beta") +
  gray_theme() +
  theme(legend.position = "none",
        strip.text = element_text(size = 10),
        text = element_text(family = "serif"))

ggsave(file.path(fig_dir, "fig_heterogeneity_formal.pdf"),
       fig_het, width = 8, height = 4,
       device = function(file, ...) quartz(type = "pdf", file = file, ...))

# ==============================================================================
# Figure 3: Beta distribution by formality (grayscale, distinguish by linetype)
# ==============================================================================
panel <- panel[!is.na(beta) & !is.na(is_formal)]
panel[, formality_label := ifelse(is_formal == 1, "Formal", "Informal")]
panel[, formality_label := factor(formality_label,
                                  levels = c("Formal", "Informal"))]

panel_2021 <- panel[year == 2021]

fig_beta <- ggplot(panel_2021,
                   aes(x = beta, weight = weight_harmonized,
                       linetype = formality_label, fill = formality_label)) +
  geom_density(alpha = 0.25, color = "black", linewidth = 0.5) +
  scale_linetype_manual(values = c("Formal" = "solid",
                                   "Informal" = "dashed")) +
  scale_fill_manual(values = c("Formal" = "gray60",
                               "Informal" = "gray85")) +
  labs(x = "Exposicion complementaria beta",
       y = "Densidad ponderada por empleo",
       linetype = NULL, fill = NULL) +
  gray_theme() +
  theme(legend.position = "bottom",
        text = element_text(family = "serif"))

ggsave(file.path(fig_dir, "fig_beta_distribution.pdf"),
       fig_beta, width = 7, height = 4,
       device = function(file, ...) quartz(type = "pdf", file = file, ...))

cat("[DONE] Three figures saved to:", fig_dir, "\n")
list.files(fig_dir, pattern = "^fig_") |> print()
