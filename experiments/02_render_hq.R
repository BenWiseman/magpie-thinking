# Re-render all post visuals at 300dpi with ragg.
# Also creates the LinkedIn banner image.

source(here::here("R", "config.R"))
source(here::here("R", "pricing.R"))
source(here::here("R", "plot_utils.R"))

library(ragg)

parsed <- readRDS(here("results", "01_aut_parsed.rds"))
ablation_parsed <- readRDS(here("results", "01a_ablations_parsed.rds"))

PAL <- list(
  default          = "#a0a0a0",
  default_examples = "#9e9e9e",
  default_long     = "#d68a3c",
  tangent_return   = "#1e6091",
  accent_warm      = "#d68a3c",
  ceiling          = "#7a7a7a",
  significant      = "#1e6091",
  ink              = "#222222",
  ink_light        = "#666666",
  bg               = "#fafafa",
  card_bg          = "#ffffff",
  card_border      = "#dadada"
)

theme_magpie_hq <- function(base_size = 14) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.2),
                                color = PAL$ink, margin = margin(b = 6)),
      plot.subtitle = element_text(color = PAL$ink_light, size = rel(0.95),
                                   margin = margin(b = 16)),
      plot.caption = element_text(color = PAL$ink_light, size = rel(0.78),
                                  hjust = 0, margin = margin(t = 14)),
      axis.title = element_text(color = PAL$ink_light, size = rel(0.95)),
      axis.text = element_text(color = PAL$ink_light),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#e8e8e8", linewidth = 0.3),
      strip.text = element_text(face = "bold", color = PAL$ink,
                                size = rel(0.95)),
      strip.background = element_blank(),
      plot.background = element_rect(fill = PAL$bg, color = NA),
      panel.background = element_rect(fill = PAL$bg, color = NA),
      legend.background = element_rect(fill = PAL$bg, color = NA)
    )
}

# =============================================================================
# 1. CONCEPT DIAGRAM (default vs tangent-return paths)
# =============================================================================

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
  y = trunk_y_default, yend = trunk_y_default
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
  y = trunk_y_tr, yend = trunk_y_tr
)
tangent_nodes <- tibble(
  trunk_x = c(2.5, 4, 5.5),
  tangent_x = c(2.5, 4, 5.5),
  tangent_y = trunk_y_tr + loop_height,
  tangent_label = c("Tangent: an\nassociation",
                    "Tangent: a\ndifferent angle",
                    "Tangent: an\nadjacent context")
)
make_arc <- function(x0, x1, y0, y1, n = 60, curvature = 0.4) {
  t <- seq(0, 1, length.out = n)
  x <- (1 - t) * x0 + t * x1
  y_base <- (1 - t) * y0 + t * y1
  y_curve <- curvature * sin(pi * t)
  tibble(x = x, y = y_base + y_curve)
}
arcs_data <- bind_rows(lapply(seq_len(nrow(tangent_nodes)), function(i) {
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
  geom_segment(data = default_edges, aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, linewidth = 1.3,
               arrow = arrow(length = unit(0.27, "cm"), type = "closed")) +
  geom_point(data = default_nodes, aes(x = x, y = y),
             size = 14, fill = "white", color = PAL$ink, shape = 21, stroke = 1.5) +
  geom_text(data = default_nodes, aes(x = x, y = y, label = label),
            size = 5, color = PAL$ink, fontface = "bold") +
  geom_text(data = default_nodes, aes(x = x, y = y - 0.4, label = full_label),
            size = 3.5, color = PAL$ink_light) +
  annotate("text", x = 0.4, y = trunk_y_default + 0.55,
           label = "Default", hjust = 0, size = 6,
           fontface = "bold", color = PAL$ink) +
  annotate("text", x = 0.4, y = trunk_y_default + 0.3,
           label = "linear reasoning: each step proceeds to the next",
           hjust = 0, size = 3.8, color = PAL$ink_light, fontface = "italic") +
  geom_path(data = arcs_data, aes(x = x, y = y, group = grp),
            color = PAL$tangent_return, linewidth = 1.1, alpha = 0.9) +
  geom_segment(data = tr_trunk_edges, aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, linewidth = 1.3,
               arrow = arrow(length = unit(0.27, "cm"), type = "closed")) +
  geom_point(data = tr_trunk, aes(x = x, y = y),
             size = 14, fill = "white", color = PAL$ink, shape = 21, stroke = 1.5) +
  geom_text(data = tr_trunk, aes(x = x, y = y, label = label),
            size = 5, color = PAL$ink, fontface = "bold") +
  geom_text(data = tr_trunk, aes(x = x, y = y - 0.4, label = full_label),
            size = 3.5, color = PAL$ink_light) +
  geom_point(data = tangent_nodes, aes(x = tangent_x, y = tangent_y),
             size = 11, fill = PAL$tangent_return,
             color = PAL$tangent_return, shape = 21, stroke = 1) +
  geom_text(data = tangent_nodes, aes(x = tangent_x, y = tangent_y + 0.4,
                                       label = tangent_label),
            size = 3.4, color = PAL$tangent_return,
            fontface = "italic", lineheight = 1) +
  annotate("text", x = 0.4, y = trunk_y_tr - 0.55,
           label = "Tangent-return", hjust = 0, size = 6,
           fontface = "bold", color = PAL$tangent_return) +
  annotate("text", x = 0.4, y = trunk_y_tr - 0.78,
           label = "each step departs to a tangent, synthesises an insight, returns enriched",
           hjust = 0, size = 3.8, color = PAL$ink_light, fontface = "italic") +
  scale_x_continuous(limits = c(0.3, 7.7)) +
  scale_y_continuous(limits = c(-1.2, 3.2)) +
  labs(title = "Two ways to think a problem",
       subtitle = "Linear chain vs tangent-return loop. The magpie pattern that this paper tests on LLMs.") +
  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.55),
                              color = PAL$ink,
                              margin = margin(t = 12, b = 6, l = 10)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1.05),
                                 margin = margin(b = 22, l = 10)),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(22, 22, 22, 22)
  )

save_plot_hq(p_concept, here("results", "01_concept_diagram.png"),
             width = 11, height = 6.5)

# =============================================================================
# 2. SCORECARDS
# =============================================================================

per_task <- parsed |>
  group_by(model_label, task_id, condition) |>
  summarise(
    originality = mean(judge_originality, na.rm = TRUE),
    flexibility = mean(judge_flexibility, na.rm = TRUE),
    elaboration = mean(judge_elaboration, na.rm = TRUE),
    semantic_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

paired_stats <- per_task |>
  pivot_longer(c(originality, flexibility, elaboration, semantic_diversity),
               names_to = "metric", values_to = "value") |>
  pivot_wider(names_from = condition, values_from = value) |>
  mutate(diff = tangent_return - default) |>
  group_by(model_label, metric) |>
  summarise(
    mean_default = mean(default, na.rm = TRUE),
    mean_tr      = mean(tangent_return, na.rm = TRUE),
    mean_diff    = mean(diff, na.rm = TRUE),
    p_value      = tryCatch(t.test(diff)$p.value, error = function(e) NA_real_),
    .groups = "drop"
  ) |>
  mutate(
    sig_class = case_when(
      is.na(p_value)             ~ "ns",
      mean_default >= 4.8        ~ "ceiling",
      p_value < 0.001            ~ "high",
      p_value < 0.01             ~ "mid",
      p_value < 0.05             ~ "low",
      TRUE                       ~ "ns"
    )
  )

model_verdict <- paired_stats |>
  group_by(model_label) |>
  summarise(
    n_high = sum(sig_class == "high"),
    n_mid_or_better = sum(sig_class %in% c("high", "mid")),
    n_ceiling = sum(sig_class == "ceiling"),
    verdict = case_when(
      n_ceiling >= 2 ~ "AT CEILING",
      n_mid_or_better >= 3 ~ "STRONG EFFECT",
      n_mid_or_better >= 1 ~ "SIGNIFICANT",
      TRUE ~ "NO EFFECT"
    ),
    .groups = "drop"
  )

model_order <- c("gpt-4o", "sonnet-4.5", "opus-4.5", "gpt-5")
paired_stats <- paired_stats |>
  mutate(model_label = factor(model_label, levels = model_order),
         metric = factor(metric,
                         levels = c("originality", "flexibility",
                                    "elaboration", "semantic_diversity"),
                         labels = c("Originality", "Flexibility",
                                    "Elaboration", "Semantic\ndiversity")))
model_verdict <- model_verdict |>
  mutate(model_label = factor(model_label, levels = model_order))

verdict_color <- c(
  "STRONG EFFECT" = PAL$significant,
  "SIGNIFICANT"   = PAL$tangent_return,
  "AT CEILING"    = PAL$ceiling,
  "NO EFFECT"     = PAL$default
)

metric_labels_pos <- tibble(
  metric = factor(c("Originality", "Flexibility", "Elaboration",
                    "Semantic\ndiversity"),
                  levels = c("Originality", "Flexibility", "Elaboration",
                             "Semantic\ndiversity")),
  y_pos  = c(4, 3, 2, 1)
)

fmt_pvalue <- function(p, sig_class) {
  if (!is.na(sig_class) && sig_class == "ceiling") return("ceiling")
  if (is.na(p)) return("—")
  if (p < 0.001) return("p < .001")
  if (p < 0.05)  return(sprintf("p = .%03d", min(999L, as.integer(round(p * 1000)))))
  return("n.s.")
}

scorecard_df <- paired_stats |>
  left_join(metric_labels_pos, by = "metric") |>
  rowwise() |>
  mutate(
    delta_label = if (as.character(metric) == "Semantic\ndiversity") {
      sprintf("%+0.3f", mean_diff)
    } else {
      sprintf("%+0.2f", mean_diff)
    },
    p_label = fmt_pvalue(p_value, sig_class),
    sig_color = if (sig_class %in% c("high", "mid")) PAL$tangent_return
                else if (sig_class == "low") PAL$accent_warm
                else if (sig_class == "ceiling") PAL$ceiling
                else PAL$ink_light
  ) |>
  ungroup()

p_scorecards <- ggplot(scorecard_df) +
  geom_rect(aes(xmin = 0, xmax = 1, ymin = 0.3, ymax = 5.7),
            fill = PAL$card_bg, color = PAL$card_border, linewidth = 0.4) +
  geom_text(aes(x = 0.05, y = y_pos, label = metric),
            hjust = 0, size = 3.5, color = PAL$ink_light,
            fontface = "plain", lineheight = 0.9) +
  geom_text(aes(x = 0.65, y = y_pos, label = delta_label, color = sig_color),
            hjust = 1, size = 6.2, fontface = "bold") +
  geom_text(aes(x = 0.70, y = y_pos, label = p_label),
            hjust = 0, size = 3.1, color = PAL$ink_light, fontface = "italic") +
  scale_color_identity() +
  facet_wrap(~ model_label, nrow = 1) +
  geom_text(data = model_verdict,
            aes(x = 0.5, y = 5.3, label = verdict,
                color = verdict_color[verdict]),
            hjust = 0.5, size = 4.6, fontface = "bold") +
  scale_x_continuous(limits = c(-0.02, 1.02), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0.2, 6.0), expand = c(0, 0)) +
  labs(
    title = "Tangent-return effects, by model",
    subtitle = "Mean lift over default condition (10 paired tasks per model). 3 of 4 models show robust effects; gpt-5's default baselines are at ceiling.",
    caption = "Numbers are mean(tangent_return − default) per metric. p-values from paired t-tests on per-task means. Ceiling = default-condition baseline ≥ 4.8/5, mathematically capped."
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.5), color = PAL$ink,
                              margin = margin(t = 12, b = 4, l = 10)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1.05),
                                 margin = margin(b = 20, l = 10)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.85),
                                hjust = 0, margin = margin(t = 16, l = 10)),
    strip.text = element_text(face = "bold", color = PAL$ink, size = rel(1.15),
                              margin = margin(b = 8)),
    strip.background = element_blank(),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.spacing = unit(0.6, "lines"),
    plot.margin = margin(22, 22, 22, 22)
  )

save_plot_hq(p_scorecards, here("results", "01_aut_scorecards.png"),
             width = 13, height = 5.5)

# =============================================================================
# 3. SIDE-BY-SIDE EXAMPLE
# =============================================================================

demo_object <- "brick"
demo_model <- "sonnet-4.5"

extract_demo <- function(df, the_condition, n_show = 6) {
  rec <- df |>
    filter(model_label == demo_model,
           condition == !!the_condition,
           task_id == demo_object,
           seed == 1L) |>
    slice(1)
  if (nrow(rec) == 0) return(NULL)
  list(uses = head(rec$uses[[1]], n_show),
       tangents = head(rec$tangents[[1]], n_show))
}

wrap_use <- function(x, width = 52) {
  vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"),
         character(1))
}

demo_default <- extract_demo(parsed, "default")
demo_tr <- extract_demo(parsed, "tangent_return")
n_show <- min(length(demo_default$uses), length(demo_tr$uses), 6)

sidebyside_df <- tibble(
  row = rep(1:n_show, 2),
  side = rep(c("Default", "Tangent-return"), each = n_show),
  use = c(wrap_use(demo_default$uses[1:n_show], 52),
          wrap_use(demo_tr$uses[1:n_show], 52)),
  tangent = c(rep(NA_character_, n_show),
              wrap_use(demo_tr$tangents[1:n_show], 45))
)

row_height <- 1.4

p_sbs <- ggplot(sidebyside_df) +
  annotate("rect", xmin = 0, xmax = 1, ymin = -0.5,
           ymax = n_show * row_height + 0.8,
           fill = "#f2f2f2", color = NA) +
  annotate("rect", xmin = 1.05, xmax = 2.05, ymin = -0.5,
           ymax = n_show * row_height + 0.8,
           fill = "#eef3f8", color = NA) +
  annotate("rect", xmin = 0, xmax = 1,
           ymin = n_show * row_height + 0.3,
           ymax = n_show * row_height + 0.8,
           fill = PAL$default, color = NA) +
  annotate("rect", xmin = 1.05, xmax = 2.05,
           ymin = n_show * row_height + 0.3,
           ymax = n_show * row_height + 0.8,
           fill = PAL$tangent_return, color = NA) +
  annotate("text", x = 0.5, y = n_show * row_height + 0.55,
           label = "Default condition",
           color = "white", size = 5.4, fontface = "bold", hjust = 0.5) +
  annotate("text", x = 1.55, y = n_show * row_height + 0.55,
           label = "Tangent-return condition",
           color = "white", size = 5.4, fontface = "bold", hjust = 0.5) +
  geom_text(data = filter(sidebyside_df, side == "Default"),
            aes(x = 0.05,
                y = n_show * row_height + 1 - row * row_height,
                label = paste0(row, ".  ", use)),
            hjust = 0, vjust = 0.5, size = 3.8,
            color = PAL$ink, lineheight = 1.15) +
  geom_text(data = filter(sidebyside_df, side == "Tangent-return"),
            aes(x = 1.10,
                y = n_show * row_height + 1 - row * row_height + 0.32,
                label = paste0(row, ".  Tangent: ", tangent)),
            hjust = 0, vjust = 0.5, size = 3.3, fontface = "italic",
            color = PAL$tangent_return, lineheight = 1.05) +
  geom_text(data = filter(sidebyside_df, side == "Tangent-return"),
            aes(x = 1.10,
                y = n_show * row_height + 1 - row * row_height - 0.22,
                label = use),
            hjust = 0, vjust = 0.5, size = 3.8,
            color = PAL$ink, lineheight = 1.15) +
  scale_x_continuous(limits = c(-0.03, 2.08), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.6, n_show * row_height + 1.1),
                     expand = c(0, 0)) +
  labs(
    title = "The operation in action",
    subtitle = paste0("Same model (Sonnet 4.5), same object (",
                      demo_object, "), same seed. Different prompt."),
    caption = "Default prompt asks for creative uses directly. Tangent-return requires each use to follow from an explicitly-named tangent."
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.55), color = PAL$ink,
                              margin = margin(t = 12, b = 4, l = 6)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1.08),
                                 margin = margin(b = 22, l = 6)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.92),
                                hjust = 0, margin = margin(t = 16, l = 6)),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(22, 22, 22, 22)
  )

save_plot_hq(p_sbs, here("results", "01_aut_sidebyside.png"),
             width = 13, height = 8)

# =============================================================================
# 4. ABLATION COMPARISON
# =============================================================================

abl_models <- c("sonnet-4.5", "opus-4.5", "gpt-4o")
combined <- bind_rows(
  parsed |> filter(model_label %in% abl_models),
  ablation_parsed
)
cond_order <- c("default", "default_examples", "default_long", "tangent_return")
cond_labels <- c("default" = "Default",
                 "default_examples" = "Default\n+examples",
                 "default_long" = "Default\n+length",
                 "tangent_return" = "Tangent-\nreturn")

per_cell <- combined |>
  group_by(model_label, condition) |>
  summarise(
    originality = mean(judge_originality, na.rm = TRUE),
    flexibility = mean(judge_flexibility, na.rm = TRUE),
    elaboration = mean(judge_elaboration, na.rm = TRUE),
    semantic_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

plot_df <- per_cell |>
  pivot_longer(c(originality, flexibility, elaboration, semantic_diversity),
               names_to = "metric", values_to = "value") |>
  mutate(
    condition = factor(condition, levels = cond_order),
    model_label = factor(model_label, levels = abl_models),
    metric = factor(metric,
                    levels = c("originality", "flexibility",
                               "elaboration", "semantic_diversity"),
                    labels = c("Originality", "Flexibility",
                               "Elaboration", "Semantic diversity"))
  )

p_ablation <- ggplot(plot_df, aes(condition, value, fill = condition)) +
  geom_col(width = 0.7, alpha = 0.92) +
  geom_text(aes(label = sprintf(
    ifelse(as.character(metric) == "Semantic diversity", "%.2f", "%.1f"),
    value)),
    vjust = -0.4, size = 3.5, color = PAL$ink) +
  facet_grid(metric ~ model_label, scales = "free_y", switch = "y") +
  scale_x_discrete(labels = cond_labels) +
  scale_fill_manual(values = c("default" = PAL$default,
                               "default_examples" = PAL$default_examples,
                               "default_long" = PAL$default_long,
                               "tangent_return" = PAL$tangent_return)) +
  labs(
    title = "Ablation results: which control catches the cognitive-operation claim?",
    subtitle = "Tangent-return uniquely maintains semantic diversity at extended length; the length-matched default beats it on elaboration but collapses diversity.",
    x = NULL, y = NULL,
    caption = "default = standard AUT prompt. default+examples = same worked examples used in TR, tangent labels stripped. default+length = instructed to produce ~600 tokens. tangent_return = full operation."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", color = PAL$ink, size = rel(1.2),
                              margin = margin(t = 8, b = 4)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1),
                                 margin = margin(b = 16)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.82),
                                hjust = 0, margin = margin(t = 14)),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, hjust = 1, face = "bold"),
    strip.text.x = element_text(face = "bold", color = PAL$ink, size = rel(1.05)),
    strip.background = element_blank(),
    axis.text.x = element_text(size = rel(0.9), lineheight = 0.9),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.spacing = unit(0.8, "lines"),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(20, 20, 20, 20)
  )

save_plot_hq(p_ablation, here("results", "01a_ablation_comparison.png"),
             width = 13, height = 9)

# =============================================================================
# 5. PAIRED-ARROW PARETO
# =============================================================================

parsed_priced <- parsed |>
  rowwise() |>
  mutate(agent_cost = cost_per_call(model, tokens_in, tokens_out)) |>
  ungroup()

paired <- parsed_priced |>
  group_by(model_label, condition) |>
  summarise(
    cost = mean(agent_cost, na.rm = TRUE),
    quality = (mean(judge_originality, na.rm = TRUE) +
               mean(judge_flexibility, na.rm = TRUE) +
               mean(judge_elaboration, na.rm = TRUE)) / 3,
    .groups = "drop"
  ) |>
  pivot_wider(names_from = condition, values_from = c(cost, quality))

sonnet_tr <- paired |> filter(model_label == "sonnet-4.5")
callout_text <- "Sonnet 4.5 + tangent-return:\n95% of gpt-5 default's quality\nat 15% of gpt-5 default's cost"

p_pareto <- ggplot(paired) +
  annotate("curve",
           x = 0.038, y = 4.05,
           xend = sonnet_tr$cost_tangent_return * 1.05,
           yend = sonnet_tr$quality_tangent_return - 0.03,
           curvature = 0.25, linewidth = 0.6, color = PAL$accent_warm,
           arrow = arrow(length = unit(0.22, "cm"), type = "closed")) +
  annotate("label",
           x = 0.042, y = 4.00,
           label = callout_text, hjust = 0, vjust = 1,
           color = PAL$accent_warm, size = 3.8, fontface = "bold",
           fill = PAL$bg, label.size = 0,
           lineheight = 1.05) +
  geom_segment(aes(x = cost_default, y = quality_default,
                   xend = cost_tangent_return, yend = quality_tangent_return),
               arrow = arrow(length = unit(0.34, "cm"), type = "closed"),
               color = PAL$tangent_return, linewidth = 1.3, alpha = 0.88) +
  geom_point(aes(x = cost_default, y = quality_default),
             shape = 21, fill = "white", color = PAL$default,
             stroke = 1.6, size = 6) +
  geom_point(aes(x = cost_tangent_return, y = quality_tangent_return),
             fill = PAL$tangent_return, color = PAL$tangent_return,
             shape = 21, size = 7, stroke = 1) +
  geom_text(aes(x = cost_tangent_return, y = quality_tangent_return,
                label = model_label),
            size = 5, fontface = "bold", color = PAL$ink,
            nudge_y = 0.08, nudge_x = 0.02) +
  geom_text(aes(x = cost_default, y = quality_default, label = "default"),
            size = 3.3, color = PAL$ink_light, vjust = -1.4, hjust = 0.5) +
  scale_x_log10(labels = scales::dollar_format(accuracy = 0.001),
                breaks = c(0.003, 0.006, 0.01, 0.02, 0.05, 0.1, 0.2)) +
  labs(
    title = "Tangent-return shifts every model up the quality curve",
    subtitle = "The cheapest high-quality option is mid-tier Claude with the right prompt, not the flagship at default",
    x = "Cost per call (USD, log scale)",
    y = "Composite quality\n(mean of originality, flexibility, elaboration)",
    caption = "Hollow circle = default condition. Filled circle = tangent-return. Arrow = the shift. Each point = mean across 30 responses (10 AUT tasks × 3 seeds). Pricing verified 2026-05-30 against official Anthropic and OpenAI rate cards. gpt-5 cost may understate true cost due to billed-but-unreported reasoning tokens."
  ) +
  theme_magpie_hq(base_size = 14) +
  theme(legend.position = "none",
        plot.title = element_text(size = rel(1.35)),
        plot.margin = margin(20, 20, 20, 20))

save_plot_hq(p_pareto, here("results", "01_paired_arrow_pareto.png"),
             width = 10, height = 7)

# =============================================================================
# 6. LINKEDIN BANNER (1200 × 627)
# =============================================================================

# A bold editorial banner. Title block top-left. Two-path schematic bottom.
# Designed for LinkedIn article header (1.91:1) and post-card crops.

banner_default_nodes <- tibble(
  x = c(2.5, 3.5, 4.5, 5.5, 6.5),
  y = 1.6,
  label = c("Q", "1", "2", "3", "A")
)
banner_default_edges <- tibble(
  x = banner_default_nodes$x[-nrow(banner_default_nodes)],
  xend = banner_default_nodes$x[-1],
  y = 1.6, yend = 1.6
)
banner_tr_trunk <- tibble(
  x = c(2.5, 3.5, 4.5, 5.5, 6.5),
  y = 0.5,
  label = c("Q", "1", "2", "3", "A+")
)
banner_tr_edges <- tibble(
  x = banner_tr_trunk$x[-nrow(banner_tr_trunk)],
  xend = banner_tr_trunk$x[-1],
  y = 0.5, yend = 0.5
)
banner_tangents <- tibble(
  trunk_x = c(3.5, 4.5, 5.5),
  tangent_y = 0.5 + 0.45
)
banner_arcs <- bind_rows(lapply(seq_len(nrow(banner_tangents)), function(i) {
  prev_x <- banner_tangents$trunk_x[i] - 0.35
  next_x <- banner_tangents$trunk_x[i] + 0.35
  depart <- make_arc(prev_x, banner_tangents$trunk_x[i],
                     0.5, banner_tangents$tangent_y[i] - 0.03,
                     curvature = 0.32)
  ret <- make_arc(banner_tangents$trunk_x[i], next_x,
                  banner_tangents$tangent_y[i] - 0.03, 0.5,
                  curvature = 0.32)
  bind_rows(
    mutate(depart, grp = paste0("g", i)),
    mutate(ret, grp = paste0("g", i))
  )
}))

p_banner <- ggplot() +
  # Title block (left side)
  annotate("text", x = 0.05, y = 2.55, label = "Magpie Thinking",
           hjust = 0, vjust = 1, size = 16, fontface = "bold",
           color = PAL$ink) +
  annotate("text", x = 0.05, y = 2.0, hjust = 0, vjust = 1, size = 6.5,
           color = PAL$ink, lineheight = 1.05,
           label = "What my AuDHD brain\naccidentally taught an AI") +
  annotate("text", x = 0.05, y = 0.95, hjust = 0, vjust = 1, size = 4.2,
           color = PAL$ink_light, fontface = "italic", lineheight = 1.1,
           label = "An empirical test of whether a neurodivergent\ncognitive pattern measurably improves LLMs.") +
  annotate("text", x = 0.05, y = 0.30, hjust = 0, vjust = 1, size = 3.4,
           color = PAL$ink_light,
           label = "github.com/BenWiseman/magpie-thinking") +

  # Default path
  annotate("text", x = 2.5, y = 2.18, hjust = 0, size = 4.2,
           color = PAL$ink_light, fontface = "bold",
           label = "Default") +
  annotate("text", x = 3.2, y = 2.18, hjust = 0, size = 3.6,
           color = PAL$ink_light, fontface = "italic",
           label = "linear: each step proceeds to the next") +
  geom_segment(data = banner_default_edges,
               aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, linewidth = 1.5,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed")) +
  geom_point(data = banner_default_nodes, aes(x = x, y = y),
             size = 14, fill = "white", color = PAL$ink, shape = 21,
             stroke = 1.7) +
  geom_text(data = banner_default_nodes, aes(x = x, y = y, label = label),
            size = 5.2, color = PAL$ink, fontface = "bold") +

  # Tangent-return path
  geom_path(data = banner_arcs, aes(x = x, y = y, group = grp),
            color = PAL$tangent_return, linewidth = 1.4, alpha = 0.95) +
  geom_segment(data = banner_tr_edges,
               aes(x = x, xend = xend, y = y, yend = yend),
               color = PAL$ink_light, linewidth = 1.5,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed")) +
  geom_point(data = banner_tr_trunk, aes(x = x, y = y),
             size = 14, fill = "white", color = PAL$ink, shape = 21,
             stroke = 1.7) +
  geom_text(data = banner_tr_trunk, aes(x = x, y = y, label = label),
            size = 5.2, color = PAL$ink, fontface = "bold") +
  geom_point(data = banner_tangents,
             aes(x = trunk_x, y = tangent_y),
             size = 10, fill = PAL$tangent_return,
             color = PAL$tangent_return, shape = 21, stroke = 1) +
  annotate("text", x = 2.5, y = -0.08, hjust = 0, size = 4.2,
           color = PAL$tangent_return, fontface = "bold",
           label = "Tangent-return") +
  annotate("text", x = 3.7, y = -0.08, hjust = 0, size = 3.6,
           color = PAL$ink_light, fontface = "italic",
           label = "each step departs, synthesises, returns enriched") +

  scale_x_continuous(limits = c(-0.05, 6.9), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.4, 2.7), expand = c(0, 0)) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(28, 28, 28, 32)
  )

# LinkedIn article header dimensions: 1200 × 627 px
save_plot_hq(p_banner, here("results", "00_banner.png"),
             width = 12, height = 6.27, dpi = 200)

cat("\nRendered at 300dpi via ragg:\n",
    "  results/01_concept_diagram.png\n",
    "  results/01_aut_scorecards.png\n",
    "  results/01_aut_sidebyside.png\n",
    "  results/01a_ablation_comparison.png\n",
    "  results/01_paired_arrow_pareto.png\n",
    "Banner:\n",
    "  results/00_banner.png (1200×627-ish, LinkedIn article header)\n",
    sep = "")
