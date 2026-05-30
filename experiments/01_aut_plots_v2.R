# v2 visuals — scorecards (replacing forest plot) + side-by-side response example
#
# Builds:
#   results/01_aut_scorecards.png — one card per model, verdict + metric gains
#   results/01_aut_sidebyside.png  — default vs tangent-return responses, same model, same object

source(here::here("R", "config.R"))
source(here::here("R", "pricing.R"))

if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel", repos = "https://cloud.r-project.org")
}
library(ggrepel)
library(scales)

parsed <- readRDS(here("results", "01_aut_parsed.rds"))

PAL <- list(
  default        = "#a0a0a0",
  tangent_return = "#1e6091",
  accent_warm    = "#d68a3c",
  ceiling        = "#7a7a7a",
  significant    = "#1e6091",
  ink            = "#222222",
  ink_light      = "#666666",
  bg             = "#fafafa",
  card_bg        = "#ffffff",
  card_border    = "#dadada"
)

theme_magpie <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.2),
                                color = PAL$ink, margin = margin(b = 6)),
      plot.subtitle = element_text(color = PAL$ink_light, size = rel(0.95),
                                   margin = margin(b = 14)),
      plot.caption = element_text(color = PAL$ink_light, size = rel(0.78),
                                  hjust = 0, margin = margin(t = 12)),
      axis.title = element_text(color = PAL$ink_light, size = rel(0.95)),
      axis.text = element_text(color = PAL$ink_light),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#e8e8e8", size = 0.3),
      strip.text = element_text(face = "bold", color = PAL$ink, size = rel(0.95)),
      strip.background = element_blank(),
      plot.background = element_rect(fill = PAL$bg, color = NA),
      panel.background = element_rect(fill = PAL$bg, color = NA),
      legend.background = element_rect(fill = PAL$bg, color = NA)
    )
}

# -----------------------------------------------------------------------------
# Scorecard plot — one card per model, verdict + per-metric deltas
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

# Build a long row of "facet cards" with verdict + 4 metric rows
metric_labels_pos <- tibble(
  metric = factor(c("Originality", "Flexibility",
                    "Elaboration", "Semantic\ndiversity"),
                  levels = c("Originality", "Flexibility",
                             "Elaboration", "Semantic\ndiversity")),
  y_pos  = c(4, 3, 2, 1)
)

fmt_pvalue <- function(p, sig_class) {
  if (!is.na(sig_class) && sig_class == "ceiling") return("ceiling")
  if (is.na(p)) return("—")
  if (p < 0.001) return("p < .001")
  if (p < 0.05) return(sprintf("p = .%03d", min(999L, as.integer(round(p * 1000)))))
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
    sig_color = if (sig_class %in% c("high", "mid")) {
      PAL$tangent_return
    } else if (sig_class == "low") {
      PAL$accent_warm
    } else if (sig_class == "ceiling") {
      PAL$ceiling
    } else {
      PAL$ink_light
    }
  ) |>
  ungroup()

p_scorecards <- ggplot(scorecard_df) +
  # Card background
  geom_rect(aes(xmin = 0, xmax = 1, ymin = 0.3, ymax = 5.7),
            fill = PAL$card_bg, color = PAL$card_border, size = 0.4) +
  # Metric label (left)
  geom_text(aes(x = 0.05, y = y_pos, label = metric),
            hjust = 0, size = 3.0, color = PAL$ink_light,
            fontface = "plain", lineheight = 0.9) +
  # Delta value (centre-right)
  geom_text(aes(x = 0.65, y = y_pos, label = delta_label,
                color = sig_color),
            hjust = 1, size = 5.2, fontface = "bold") +
  # p-value (right)
  geom_text(aes(x = 0.70, y = y_pos, label = p_label),
            hjust = 0, size = 2.7, color = PAL$ink_light,
            fontface = "italic") +
  scale_color_identity() +
  facet_wrap(~ model_label, nrow = 1) +
  # Verdict badge inside each facet
  geom_text(data = model_verdict,
            aes(x = 0.5, y = 5.3, label = verdict, color = verdict_color[verdict]),
            hjust = 0.5, size = 4, fontface = "bold") +
  scale_x_continuous(limits = c(-0.02, 1.02), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0.2, 6.0), expand = c(0, 0)) +
  labs(
    title = "Tangent-return effects — by model",
    subtitle = "Mean lift over default condition (10 paired tasks per model). 3 of 4 models show robust effects; gpt-5's default baselines are already at ceiling.",
    caption = "Numbers are mean(tangent_return − default) per metric. p-values from paired t-tests on per-task means.\nCeiling = default-condition baseline ≥ 4.8/5, mathematically capped."
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.4), color = PAL$ink,
                              margin = margin(t = 10, b = 4, l = 10)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1),
                                 margin = margin(b = 18, l = 10)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.8),
                                hjust = 0, margin = margin(t = 14, l = 10)),
    strip.text = element_text(face = "bold", color = PAL$ink, size = rel(1.05),
                              margin = margin(b = 8)),
    strip.background = element_blank(),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.spacing = unit(0.6, "lines"),
    plot.margin = margin(20, 20, 20, 20)
  )

ggsave(here("results", "01_aut_scorecards.png"),
       p_scorecards, width = 13, height = 5.5, dpi = 180)

# -----------------------------------------------------------------------------
# Side-by-side response visual — concrete example of the operation in action
# -----------------------------------------------------------------------------

# Pick a vivid pair: Sonnet 4.5 on "brick", first seed of each condition
demo_object <- "brick"
demo_model <- "sonnet-4.5"

extract_demo <- function(df, condition, n_show = 6) {
  rec <- df |>
    filter(model_label == demo_model,
           condition == !!condition,
           task_id == demo_object,
           seed == 1L) |>
    slice(1)
  if (nrow(rec) == 0) return(NULL)
  uses <- rec$uses[[1]]
  tangents <- rec$tangents[[1]]
  list(
    uses = head(uses, n_show),
    tangents = head(tangents, n_show)
  )
}

demo_default <- extract_demo(parsed, "default")
demo_tr <- extract_demo(parsed, "tangent_return")

wrap_use <- function(x, width = 60) {
  vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"),
         character(1))
}

n_show <- min(length(demo_default$uses), length(demo_tr$uses), 6)

sidebyside_df <- tibble(
  row = rep(1:n_show, 2),
  side = rep(c("Default", "Tangent-return"), each = n_show),
  use = c(
    wrap_use(demo_default$uses[1:n_show], width = 52),
    wrap_use(demo_tr$uses[1:n_show], width = 52)
  ),
  tangent = c(
    rep(NA_character_, n_show),
    wrap_use(demo_tr$tangents[1:n_show], width = 45)
  )
)

# Each row vertical span; allow more height per row for wrapped text
row_height <- 1.4

p_sbs <- ggplot(sidebyside_df) +
  # Column backgrounds
  annotate("rect", xmin = 0, xmax = 1, ymin = -0.5,
           ymax = n_show * row_height + 0.8,
           fill = "#f2f2f2", color = NA) +
  annotate("rect", xmin = 1.05, xmax = 2.05, ymin = -0.5,
           ymax = n_show * row_height + 0.8,
           fill = "#eef3f8", color = NA) +
  # Header bars
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
           color = "white", size = 4.5, fontface = "bold", hjust = 0.5) +
  annotate("text", x = 1.55, y = n_show * row_height + 0.55,
           label = "Tangent-return condition",
           color = "white", size = 4.5, fontface = "bold", hjust = 0.5) +
  # Default uses
  geom_text(data = filter(sidebyside_df, side == "Default"),
            aes(x = 0.05,
                y = n_show * row_height + 1 - row * row_height,
                label = paste0(row, ".  ", use)),
            hjust = 0, vjust = 0.5, size = 3.1,
            color = PAL$ink, lineheight = 1.1) +
  # Tangent-return: tangent above, use below
  geom_text(data = filter(sidebyside_df, side == "Tangent-return"),
            aes(x = 1.10,
                y = n_show * row_height + 1 - row * row_height + 0.32,
                label = paste0(row, ".  Tangent: ", tangent)),
            hjust = 0, vjust = 0.5, size = 2.7, fontface = "italic",
            color = PAL$tangent_return, lineheight = 1.0) +
  geom_text(data = filter(sidebyside_df, side == "Tangent-return"),
            aes(x = 1.10,
                y = n_show * row_height + 1 - row * row_height - 0.22,
                label = use),
            hjust = 0, vjust = 0.5, size = 3.1,
            color = PAL$ink, lineheight = 1.1) +
  scale_x_continuous(limits = c(-0.03, 2.08), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.6, n_show * row_height + 1.1),
                     expand = c(0, 0)) +
  labs(
    title = "The operation in action",
    subtitle = paste0("Same model (Sonnet 4.5), same object (", demo_object,
                      "), different prompts. First 6 uses each, seed 1."),
    caption = "Default prompt asks for creative uses directly. Tangent-return prompt requires each use to follow from an explicitly-named tangent."
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = rel(1.4), color = PAL$ink,
                              margin = margin(t = 10, b = 4, l = 6)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(1),
                                 margin = margin(b = 18, l = 6)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.85),
                                hjust = 0, margin = margin(t = 14, l = 6)),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    plot.margin = margin(18, 18, 18, 18)
  )

ggsave(here("results", "01_aut_sidebyside.png"),
       p_sbs, width = 13, height = 8, dpi = 180)

cat("\nWritten:\n",
    " results/01_aut_scorecards.png\n",
    " results/01_aut_sidebyside.png\n", sep = "")
