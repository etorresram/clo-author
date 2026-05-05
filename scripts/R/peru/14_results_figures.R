# ==============================================================================
# 14_results_figures.R
# ==============================================================================
# Project: The Labor Market and Distributional Impact of Generative AI
# Stage:   Peru pipeline, Phase 14 (publication-grade figures)
#
# Produces three figures for the Results section:
#
#   fig_event_study_3panel      Event study panel for log_emp, log_wage, hours
#   fig_heterogeneity_formal    Coefficient plot of tau_F vs tau_I (3 outcomes)
#   fig_beta_distribution       Density of beta exposure by formality stratum
#
# Output: paper/figures/peru/*.pdf
# ==============================================================================

library(here)
library(data.table)
library(ggplot2)
library(patchwork)

out_dir <- here("data", "cleaned", "peru")
fig_dir <- here("paper", "figures", "peru")

es_results  <- readRDS(file.path(out_dir, "event_study_results.rds"))
het_results <- readRDS(file.path(out_dir, "heterogeneity_formality.rds"))
panel       <- readRDS(file.path(out_dir, "epen_with_exposure.rds"))

# ==============================================================================
# Figure 1: Three-panel event study
# ==============================================================================
mk_es_panel <- function(tidy_dt, ylab, ylim_pad = 0.05) {
  setorder(tidy_dt, k)
  ggplot(tidy_dt, aes(x = k, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "darkred", linewidth = 0.5) +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.25, linewidth = 0.45) +
    scale_x_continuous(breaks = seq(-7, 12, 2)) +
    labs(x = NULL, y = ylab) +
    theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold", size = 11),
          axis.title.y = element_text(size = 9))
}

p1 <- mk_es_panel(es_results$tidy$log_employment,
                  expression(theta[k] * "  log empleo")) +
      ggtitle("(a) log empleo")

p2 <- mk_es_panel(es_results$tidy$mean_log_wage,
                  expression(theta[k] * "  log salario hora")) +
      ggtitle("(b) log salario hora")

p3 <- mk_es_panel(es_results$tidy$mean_hours,
                  expression(theta[k] * "  horas semanales")) +
      ggtitle("(c) horas semanales") +
      labs(x = "Trimestres relativos a t* (2022T4)")

es_combined <- p1 / p2 / p3 +
  plot_annotation(
    title = "Estudio de eventos por dosis de exposición",
    subtitle = "Lima Metropolitana, EPEN. Especificación Sun-Abraham. Línea roja: lanzamiento de ChatGPT.",
    caption = "Coeficientes son θ_k × β. Período de referencia: 2022T3 (k = -1). Buffer 2022T4 excluido. IC 95%, errores clusterizados en CIUO-08-4d.",
    theme = theme(plot.title = element_text(face = "bold", size = 12),
                  plot.subtitle = element_text(size = 9),
                  plot.caption = element_text(size = 8, color = "gray30"))
  )

ggsave(file.path(fig_dir, "fig_event_study_3panel.pdf"),
       es_combined, width = 7, height = 8)

# ==============================================================================
# Figure 2: Heterogeneity by formality (coefficient plot)
# ==============================================================================
# Extract tau_F, tau_I from the interaction models (Design 1, Phase 12)
extract_het <- function(mod, label) {
  ct <- summary(mod)$coeftable
  data.table(
    outcome = label,
    channel = c("Formal", "Informal"),
    estimate = c(ct["x_F", "Estimate"], ct["x_I", "Estimate"]),
    se       = c(ct["x_F", "Std. Error"], ct["x_I", "Std. Error"])
  )
}

het_dt <- rbindlist(list(
  extract_het(het_results$interaction$log_employment, "log empleo"),
  extract_het(het_results$interaction$mean_log_wage,  "log salario hora"),
  extract_het(het_results$interaction$mean_hours,     "horas semanales")
))
het_dt[, ci_lo := estimate - 1.96 * se]
het_dt[, ci_hi := estimate + 1.96 * se]
het_dt[, outcome := factor(outcome,
                           levels = c("log empleo", "log salario hora",
                                      "horas semanales"))]

fig_het <- ggplot(het_dt, aes(x = channel, y = estimate, color = channel)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  size = 0.6, linewidth = 0.7) +
  facet_wrap(~ outcome, scales = "free_y", nrow = 1) +
  scale_color_manual(values = c("Formal" = "#2c7fb8", "Informal" = "#d95f0e")) +
  labs(
    x = NULL,
    y = expression("Efecto por unidad de β después de ChatGPT"),
    title = "Heterogeneidad por formalidad de línea base (2021)",
    subtitle = expression("τ"[F] * " (canal formal) vs τ"[I] * " (canal informal)"),
    caption = "Coeficientes de la regresión interactuada (eq. eq:formality_interaction). IC 95% clusterizado en CIUO."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = 10),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(size = 8, color = "gray30"))

ggsave(file.path(fig_dir, "fig_heterogeneity_formal.pdf"),
       fig_het, width = 8, height = 4)

# ==============================================================================
# Figure 3: Beta distribution by formality (descriptive)
# ==============================================================================
panel <- panel[!is.na(beta) & !is.na(is_formal)]
panel[, formality_label := ifelse(is_formal == 1, "Formal", "Informal")]

# Use 2021 only for clean baseline picture
panel_2021 <- panel[year == 2021]

fig_beta <- ggplot(panel_2021, aes(x = beta, weight = weight_harmonized,
                                   fill = formality_label,
                                   color = formality_label)) +
  geom_density(alpha = 0.4) +
  scale_fill_manual(values = c("Formal" = "#2c7fb8", "Informal" = "#d95f0e")) +
  scale_color_manual(values = c("Formal" = "#2c7fb8", "Informal" = "#d95f0e")) +
  labs(
    x = expression("Exposición complementaria " * beta * " (Eloundou et al. 2023)"),
    y = "Densidad ponderada por empleo",
    fill = "Estatus formal", color = "Estatus formal",
    title = "Distribución de exposición a LLMs por formalidad de línea base",
    subtitle = "Lima Metropolitana, EPEN 2021",
    caption = "Densidad por kernel ponderada por el factor de expansión de la EPEN."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(size = 8, color = "gray30"))

ggsave(file.path(fig_dir, "fig_beta_distribution.pdf"),
       fig_beta, width = 7, height = 4)

cat("[DONE] Three figures saved to:", fig_dir, "\n")
list.files(fig_dir, pattern = "^fig_") |> print()
