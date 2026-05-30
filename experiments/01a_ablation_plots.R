# Ablation visualisation — TR vs default vs default_long vs default_examples,
# by model × metric.

source(here::here("R", "config.R"))
source(here::here("R", "pricing.R"))

if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel", repos = "https://cloud.r-project.org")
}
library(scales)

PAL <- list(
  default          = "#bdbdbd",
  default_examples = "#9e9e9e",
  default_long     = "#d68a3c",
  tangent_return   = "#1e6091",
  ink              = "#222222",
  ink_light        = "#666666",
  bg               = "#fafafa"
)

main_parsed <- readRDS(here("results", "01_aut_parsed.rds"))
ablation_parsed <- readRDS(here("results", "01a_ablations_parsed.rds"))

# Combine, restricted to the 3 ablation models
abl_models <- c("sonnet-4.5", "opus-4.5", "gpt-4o")
combined <- bind_rows(
  main_parsed |> filter(model_label %in% abl_models),
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
    vjust = -0.4, size = 2.9, color = PAL$ink) +
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
    caption = "default = standard AUT prompt. default+examples = adds the same worked examples used in TR (tangent labels stripped).\ndefault+length = instructed to produce ~600 tokens. tangent_return = full operation."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", color = PAL$ink, size = rel(1.15),
                              margin = margin(b = 4)),
    plot.subtitle = element_text(color = PAL$ink_light, size = rel(0.92),
                                 margin = margin(b = 14)),
    plot.caption = element_text(color = PAL$ink_light, size = rel(0.78),
                                hjust = 0, margin = margin(t = 14)),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, hjust = 1, face = "bold"),
    strip.text.x = element_text(face = "bold", color = PAL$ink),
    strip.background = element_blank(),
    axis.text.x = element_text(size = rel(0.78), lineheight = 0.85),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.spacing = unit(0.8, "lines"),
    plot.background = element_rect(fill = PAL$bg, color = NA),
    panel.background = element_rect(fill = PAL$bg, color = NA)
  )

ggsave(here("results", "01a_ablation_comparison.png"),
       p_ablation, width = 13, height = 9, dpi = 180)

paired_test <- function(df, the_model, metric_col, cond_a, cond_b) {
  sub <- df[df$model_label == the_model, ]
  wide <- sub |>
    group_by(task_id, condition) |>
    summarise(val = mean(.data[[metric_col]], na.rm = TRUE),
              .groups = "drop") |>
    pivot_wider(names_from = condition, values_from = val)
  if (!all(c(cond_a, cond_b) %in% names(wide))) return(NULL)
  diff_vec <- wide[[cond_a]] - wide[[cond_b]]
  diff_vec <- diff_vec[!is.na(diff_vec)]
  if (length(diff_vec) < 2) return(NULL)
  p_val <- tryCatch(t.test(diff_vec)$p.value, error = function(e) NA_real_)
  tibble(model_label = the_model, metric = metric_col,
         comparison = paste(cond_a, "vs", cond_b),
         n = length(diff_vec),
         mean_diff = mean(diff_vec), p = p_val)
}

combined_long <- combined |>
  rename(originality_v = judge_originality,
         flexibility_v = judge_flexibility,
         elaboration_v = judge_elaboration,
         semdiv_v = semantic_diversity)

metric_cols <- c("originality_v", "flexibility_v",
                 "elaboration_v", "semdiv_v")

abl_stats <- bind_rows(lapply(abl_models, function(m) {
  bind_rows(lapply(metric_cols, function(mc) {
    bind_rows(
      paired_test(combined_long, m, mc, "tangent_return", "default_long"),
      paired_test(combined_long, m, mc, "tangent_return", "default_examples")
    )
  }))
})) |>
  mutate(metric = sub("_v$", "", metric))

write_csv(abl_stats, here("results", "01a_ablation_stats.csv"))

cat("\n=== TR vs ablation controls (paired by task, n=10) ===\n")
print(abl_stats |> arrange(model_label, metric, comparison))
cat("\nPlot: results/01a_ablation_comparison.png\n")
cat("Stats: results/01a_ablation_stats.csv\n")
