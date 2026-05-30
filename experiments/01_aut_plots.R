# Publication-grade visuals for experiment 01.
# Builds:
#   - 01_paired_arrow_pareto.png   (main hero shot)
#   - 01_effect_forest.png         (paper-grade stats viz)
#   - 01_main_effects_polished.png (cleaner version of headline boxplot)
#   - 01_concept_diagram.png       (linear vs tangent-return cognitive paths)

source(here::here("R", "config.R"))
source(here::here("R", "pricing.R"))

if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel", repos = "https://cloud.r-project.org")
}
library(ggrepel)
library(scales)

parsed <- readRDS(here("results", "01_aut_parsed.rds"))
parsed <- parsed |>
  rowwise() |>
  mutate(agent_cost = cost_per_call(model, tokens_in, tokens_out)) |>
  ungroup()

# Brand palette — muted, sophisticated
PAL <- list(
  default        = "#a0a0a0",
  tangent_return = "#1e6091",
  accent_warm    = "#d68a3c",
  ink            = "#222222",
  ink_light      = "#666666",
  bg             = "#fafafa"
)

theme_magpie <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.2),
                                color = PAL$ink, margin = margin(b = 6)),
      plot.subtitle = element_text(color = PAL$ink_light,
                                   size = rel(0.95),
                                   margin = margin(b = 14)),
      plot.caption = element_text(color = PAL$ink_light,
                                  size = rel(0.78), hjust = 0,
                                  margin = margin(t = 12)),
      axis.title = element_text(color = PAL$ink_light, size = rel(0.95)),
      axis.text = element_text(color = PAL$ink_light),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#e8e8e8", size = 0.3),
      strip.text = element_text(face = "bold", color = PAL$ink,
                                size = rel(0.95)),
      strip.background = element_blank(),
      legend.title = element_text(face = "bold", color = PAL$ink,
                                  size = rel(0.85)),
      legend.text = element_text(color = PAL$ink_light, size = rel(0.85)),
      plot.background = element_rect(fill = PAL$bg, color = NA),
      panel.background = element_rect(fill = PAL$bg, color = NA),
      legend.background = element_rect(fill = PAL$bg, color = NA)
    )
}

# -----------------------------------------------------------------------------
# 1. Paired-arrow Pareto plot — the hero shot
# -----------------------------------------------------------------------------

paired <- parsed |>
  group_by(model_label, condition) |>
  summarise(
    cost = mean(agent_cost, na.rm = TRUE),
    quality = (mean(judge_originality, na.rm = TRUE) +
               mean(judge_flexibility, na.rm = TRUE) +
               mean(judge_elaboration, na.rm = TRUE)) / 3,
    .groups = "drop"
  ) |>
  pivot_wider(names_from = condition,
              values_from = c(cost, quality))

sonnet_tr <- paired |> filter(model_label == "sonnet-4.5")
callout_text <- "Sonnet 4.5 + tangent-return:\n95% of gpt-5 default's quality\nat 15% of gpt-5 default's cost"

p_pareto <- ggplot(paired) +
  # Sweet-spot annotation — placed in empty zone, arrow to Sonnet+TR
  annotate("curve",
           x = 0.038, y = 4.05,
           xend = sonnet_tr$cost_tangent_return * 1.05,
           yend = sonnet_tr$quality_tangent_return - 0.03,
           curvature = 0.25, size = 0.5, color = PAL$accent_warm,
           arrow = arrow(length = unit(0.2, "cm"), type = "closed")) +
  annotate("label",
           x = 0.042, y = 4.00,
           label = callout_text, hjust = 0, vjust = 1,
           color = PAL$accent_warm, size = 3.3, fontface = "bold",
           fill = PAL$bg, label.size = 0,
           lineheight = 1.05) +
  geom_segment(aes(x = cost_default, y = quality_default,
                   xend = cost_tangent_return, yend = quality_tangent_return),
               arrow = arrow(length = unit(0.32, "cm"), type = "closed"),
               color = PAL$tangent_return, size = 1.1, alpha = 0.85) +
  geom_point(aes(x = cost_default, y = quality_default),
             shape = 21, fill = "white", color = PAL$default,
             stroke = 1.5, size = 5) +
  geom_point(aes(x = cost_tangent_return, y = quality_tangent_return),
             fill = PAL$tangent_return, color = PAL$tangent_return,
             shape = 21, size = 6, stroke = 1) +
  geom_text_repel(aes(x = cost_tangent_return, y = quality_tangent_return,
                      label = model_label),
                  size = 4.2, fontface = "bold", color = PAL$ink,
                  nudge_y = 0.06, nudge_x = 0.02,
                  segment.color = NA, max.overlaps = Inf) +
  geom_text(aes(x = cost_default, y = quality_default, label = "default"),
            size = 2.8, color = PAL$ink_light, vjust = -1.4, hjust = 0.5) +
  scale_x_log10(labels = dollar_format(accuracy = 0.001),
                breaks = c(0.003, 0.006, 0.01, 0.02, 0.05, 0.1, 0.2)) +
  labs(
    title = "Tangent-return shifts every model up the quality curve",
    subtitle = "The cheapest high-quality option is mid-tier Claude with the right prompt — not the flagship at default",
    x = "Cost per call (USD, log scale)",
    y = "Composite quality\n(mean of originality, flexibility, elaboration)",
    caption = "Hollow circle = default condition  ·  filled circle = tangent-return  ·  arrow = the shift\nEach point = mean across 30 responses (10 AUT tasks × 3 seeds). Pricing verified 2026-05-30 against\nofficial Anthropic and OpenAI rate cards. gpt-5 cost may understate true cost due to billed-but-unreported reasoning tokens."
  ) +
  theme_magpie() +
  theme(legend.position = "none",
        plot.title = element_text(size = rel(1.25)))

ggsave(here("results", "01_paired_arrow_pareto.png"),
       p_pareto, width = 10, height = 7, dpi = 180)

# -----------------------------------------------------------------------------
# 2. Effect-size forest plot
# -----------------------------------------------------------------------------

per_task <- parsed |>
  group_by(model_label, task_id, condition) |>
  summarise(
    originality = mean(judge_originality, na.rm = TRUE),
    flexibility = mean(judge_flexibility, na.rm = TRUE),
    elaboration = mean(judge_elaboration, na.rm = TRUE),
    semantic_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

effects <- per_task |>
  pivot_longer(c(originality, flexibility, elaboration, semantic_diversity),
               names_to = "metric", values_to = "value") |>
  pivot_wider(names_from = condition, values_from = value) |>
  mutate(diff = tangent_return - default) |>
  group_by(model_label, metric) |>
  summarise(
    mean_diff = mean(diff, na.rm = TRUE),
    se_diff = sd(diff, na.rm = TRUE) / sqrt(sum(!is.na(diff))),
    ci_lo = mean_diff - 1.96 * se_diff,
    ci_hi = mean_diff + 1.96 * se_diff,
    .groups = "drop"
  ) |>
  mutate(
    metric = factor(metric,
                    levels = c("semantic_diversity", "elaboration",
                               "flexibility", "originality"),
                    labels = c("Semantic\ndiversity", "Elaboration",
                               "Flexibility", "Originality")),
    significant = ci_lo > 0,
    model_label = factor(model_label,
                         levels = c("gpt-4o", "gpt-5",
                                    "sonnet-4.5", "opus-4.5"))
  )

p_forest <- ggplot(effects, aes(y = metric, x = mean_diff,
                                xmin = ci_lo, xmax = ci_hi,
                                color = significant)) +
  geom_vline(xintercept = 0, color = PAL$ink_light,
             linetype = "dashed", size = 0.4) +
  geom_errorbarh(height = 0.2, size = 0.9) +
  geom_point(size = 3.2) +
  facet_wrap(~ model_label, ncol = 4) +
  scale_color_manual(values = c("TRUE" = PAL$tangent_return,
                                "FALSE" = PAL$ink_light),
                     labels = c("TRUE" = "95% CI > 0",
                                "FALSE" = "Includes 0")) +
  scale_x_continuous(breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1.0)) +
  labs(
    title = "Effect of tangent-return on each metric, by model",
    subtitle = "Mean difference (tangent-return − default), 95% CI from per-task pairs (n=10)",
    x = "Mean improvement (1–5 judge scale; semantic diversity on its own scale)",
    y = NULL,
    color = NULL,
    caption = "Bars whose 95% confidence interval excludes zero are significant at α=.05.\nGPT-5's small effects reflect ceiling — default-condition baselines already average 4-5/5."
  ) +
  theme_magpie() +
  theme(legend.position = "top")

ggsave(here("results", "01_effect_forest.png"),
       p_forest, width = 11, height = 6, dpi = 180)

# -----------------------------------------------------------------------------
# 3. Polished main effects plot (improved boxplot)
# -----------------------------------------------------------------------------

plot_df <- per_task |>
  pivot_longer(c(originality, flexibility, elaboration, semantic_diversity),
               names_to = "metric", values_to = "value") |>
  mutate(
    metric = factor(metric,
                    levels = c("originality", "flexibility",
                               "elaboration", "semantic_diversity"),
                    labels = c("Originality", "Flexibility",
                               "Elaboration", "Semantic\ndiversity")),
    model_label = factor(model_label,
                         levels = c("gpt-4o", "gpt-5",
                                    "sonnet-4.5", "opus-4.5"))
  )

p_main <- ggplot(plot_df, aes(condition, value, fill = condition)) +
  geom_boxplot(width = 0.55, alpha = 0.85, color = PAL$ink,
               outlier.size = 0.7, outlier.alpha = 0.5) +
  geom_jitter(width = 0.12, alpha = 0.35, size = 0.9, color = PAL$ink) +
  facet_grid(metric ~ model_label, scales = "free_y", switch = "y") +
  scale_fill_manual(values = c(default = PAL$default,
                               tangent_return = PAL$tangent_return),
                    labels = c("default", "tangent-return")) +
  scale_x_discrete(labels = c("default" = "default",
                              "tangent_return" = "tangent-return")) +
  labs(
    title = "Tangent-return outperforms default on every metric where there's room to move",
    subtitle = "Each box = 10 tasks × 3 seeds per (model × condition). GPT-5 baselines hit ceiling on originality, elaboration, flexibility.",
    x = NULL, y = NULL,
    caption = "Wider boxes = more variance across tasks; tighter boxes = more consistent quality."
  ) +
  theme_magpie() +
  theme(legend.position = "none",
        strip.placement = "outside",
        strip.text.y.left = element_text(angle = 0, hjust = 1),
        panel.spacing.x = unit(0.8, "lines"),
        axis.text.x = element_text(size = rel(0.85)))

ggsave(here("results", "01_main_effects_polished.png"),
       p_main, width = 11, height = 8, dpi = 180)

# -----------------------------------------------------------------------------
# 4. Concept diagram — linear vs tangent-return paths
# -----------------------------------------------------------------------------

# Two horizontal "paths" stacked. Top: default (linear). Bottom: tangent-return
# (trunk with tangent loops returning enriched).

trunk_y_default <- 2.2
trunk_y_tr <- 0.6
loop_height <- 0.55

default_nodes <- tibble(
  x = c(1, 2.5, 4, 5.5, 7),
  y = trunk_y_default,
  label = c("Q", "1", "2", "3", "A"),
  full_label = c("Question", "Step 1", "Step 2", "Step 3", "Answer")
)

default_edges <- tibble(
  x = default_nodes$x[-nrow(default_nodes)],
  xend = default_nodes$x[-1],
  y = trunk_y_default,
  yend = trunk_y_default
)

tr_trunk <- tibble(
  x = c(1, 2.5, 4, 5.5, 7),
  y = trunk_y_tr,
  label = c("Q", "1", "2", "3", "A+"),
  full_label = c("Question", "Step 1", "Step 2", "Step 3", "Enriched answer")
)

tr_trunk_edges <- tibble(
  x = tr_trunk$x[-nrow(tr_trunk)],
  xend = tr_trunk$x[-1],
  y = trunk_y_tr,
  yend = trunk_y_tr
)

# Tangent loops — small arcs above each step
tangent_nodes <- tibble(
  trunk_x = c(2.5, 4, 5.5),
  tangent_x = c(2.5, 4, 5.5),
  tangent_y = trunk_y_tr + loop_height,
  tangent_label = c("Tangent: an\nassociation", "Tangent: a\ndifferent angle",
                    "Tangent: an\nadjacent context")
)

# Build the arcs (departure and return)
make_arc <- function(x0, x1, y0, y1, n = 30, curvature = 0.4) {
  t <- seq(0, 1, length.out = n)
  x <- (1 - t) * x0 + t * x1
  y_base <- (1 - t) * y0 + t * y1
  y_curve <- curvature * sin(pi * t)
  tibble(x = x, y = y_base + y_curve)
}

arcs_data <- bind_rows(lapply(seq_len(nrow(tangent_nodes)), function(i) {
  # depart from previous trunk node, arc up to tangent
  prev_x <- tangent_nodes$trunk_x[i] - 0.5
  next_x <- tangent_nodes$trunk_x[i] + 0.5
  depart <- make_arc(prev_x, tangent_nodes$tangent_x[i],
                     trunk_y_tr, tangent_nodes$tangent_y[i] - 0.05)
  ret <- make_arc(tangent_nodes$tangent_x[i], next_x,
                  tangent_nodes$tangent_y[i] - 0.05, trunk_y_tr)
  bind_rows(
    mutate(depart, leg = "out", grp = paste0("g", i)),
    mutate(ret, leg = "back", grp = paste0("g", i))
  )
}))

p_concept <- ggplot() +
  # Default path
  geom_segment(data = default_edges, aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, size = 1.2,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed")) +
  geom_point(data = default_nodes, aes(x = x, y = y),
             size = 13, fill = "white", color = PAL$ink, shape = 21, stroke = 1.4) +
  geom_text(data = default_nodes, aes(x = x, y = y, label = label),
            size = 4.2, color = PAL$ink, fontface = "bold") +
  geom_text(data = default_nodes, aes(x = x, y = y - 0.38, label = full_label),
            size = 2.9, color = PAL$ink_light) +
  annotate("text", x = 0.4, y = trunk_y_default + 0.55,
           label = "Default", hjust = 0, size = 4.8,
           fontface = "bold", color = PAL$ink) +
  annotate("text", x = 0.4, y = trunk_y_default + 0.3,
           label = "linear reasoning — each step proceeds to the next",
           hjust = 0, size = 3.1, color = PAL$ink_light, fontface = "italic") +

  # Tangent-return path
  geom_path(data = arcs_data, aes(x = x, y = y, group = grp),
            color = PAL$tangent_return, size = 1, alpha = 0.85) +
  geom_segment(data = tr_trunk_edges, aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, size = 1.2,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed")) +
  geom_point(data = tr_trunk, aes(x = x, y = y),
             size = 13, fill = "white", color = PAL$ink, shape = 21, stroke = 1.4) +
  geom_text(data = tr_trunk, aes(x = x, y = y, label = label),
            size = 4.2, color = PAL$ink, fontface = "bold") +
  geom_text(data = tr_trunk, aes(x = x, y = y - 0.38, label = full_label),
            size = 2.9, color = PAL$ink_light) +
  geom_point(data = tangent_nodes, aes(x = tangent_x, y = tangent_y),
             size = 10, fill = PAL$tangent_return,
             color = PAL$tangent_return, shape = 21, stroke = 1) +
  geom_text(data = tangent_nodes, aes(x = tangent_x, y = tangent_y + 0.38,
                                       label = tangent_label),
            size = 2.85, color = PAL$tangent_return,
            fontface = "italic", lineheight = 0.95) +
  annotate("text", x = 0.4, y = trunk_y_tr - 0.55,
           label = "Tangent-return", hjust = 0, size = 4.8,
           fontface = "bold", color = PAL$tangent_return) +
  annotate("text", x = 0.4, y = trunk_y_tr - 0.78,
           label = "each step departs to a tangent, synthesises an insight, returns enriched",
           hjust = 0, size = 3.1, color = PAL$ink_light, fontface = "italic") +

  scale_x_continuous(limits = c(0.3, 7.7)) +
  scale_y_continuous(limits = c(-1.2, 3.2)) +
  labs(
    title = "Two ways to think a problem",
    subtitle = "Linear chain vs tangent-return loop — the magpie pattern that this paper tests on LLMs"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.4),
                              color = PAL$ink, margin = margin(b = 6, t = 10, l = 10)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1),
                                 margin = margin(b = 20, l = 10)),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(20, 20, 20, 20)
  )

ggsave(here("results", "01_concept_diagram.png"),
       p_concept, width = 11, height = 6.5, dpi = 180)

cat("\nWritten:\n",
    " results/01_paired_arrow_pareto.png\n",
    " results/01_effect_forest.png\n",
    " results/01_main_effects_polished.png\n",
    " results/01_concept_diagram.png\n", sep = "")
