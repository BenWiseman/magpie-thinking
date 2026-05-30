# Cost analysis layered on top of the AUT experiment.
# Loads parsed.rds (per-response data) and applies real pricing to compute
# exact $/call, then surfaces the value-optimizer comparison.

source(here::here("R", "config.R"))
source(here::here("R", "pricing.R"))

parsed <- readRDS(here("results", "01_aut_parsed.rds"))

# Per-call agent cost (judge + embedding costs accounted separately below)
parsed <- parsed |>
  rowwise() |>
  mutate(agent_cost = cost_per_call(model, tokens_in, tokens_out)) |>
  ungroup()

# Judge cost — judge runs Sonnet 4.5 on every response
# Judge input ≈ system + rubric + the response (~2500 tokens with the longer TR responses)
# Judge output ≈ 200 tokens (structured score JSON)
# Approximate; not measured per-call in v1
judge_per_call <- (2500 * PRICING[["claude-sonnet-4-5"]]$input +
                   200  * PRICING[["claude-sonnet-4-5"]]$output) / 1e6

# Embedding cost — text-embedding-3-large; ~200 tokens per response (avg)
embed_per_call <- (200 * PRICING[["text-embedding-3-large"]]$input) / 1e6

parsed$judge_cost <- judge_per_call
parsed$embed_cost <- embed_per_call
parsed$total_cost <- parsed$agent_cost + parsed$judge_cost + parsed$embed_cost

# Per-(model × condition) cost summary
cost_summary <- parsed |>
  group_by(model_label, condition) |>
  summarise(
    n                  = n(),
    mean_tokens_in     = mean(tokens_in,  na.rm = TRUE),
    mean_tokens_out    = mean(tokens_out, na.rm = TRUE),
    mean_agent_cost    = mean(agent_cost, na.rm = TRUE),
    mean_total_cost    = mean(total_cost, na.rm = TRUE),
    cost_per_1k_calls  = mean(total_cost, na.rm = TRUE) * 1000,
    mean_originality   = mean(judge_originality, na.rm = TRUE),
    mean_flexibility   = mean(judge_flexibility, na.rm = TRUE),
    mean_elaboration   = mean(judge_elaboration, na.rm = TRUE),
    mean_sem_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(cost_summary, here("results", "01_aut_cost_summary.csv"))

# Value-optimizer table: cost per "originality point" and overall quality
value_table <- cost_summary |>
  mutate(
    composite_quality  = (mean_originality + mean_flexibility +
                          mean_elaboration) / 3,
    cost_per_orig_pt   = mean_agent_cost / mean_originality,
    cost_per_quality   = mean_agent_cost / composite_quality
  ) |>
  arrange(cost_per_quality) |>
  select(model_label, condition, mean_agent_cost, mean_originality,
         composite_quality, cost_per_orig_pt, cost_per_quality)

write_csv(value_table, here("results", "01_aut_value_table.csv"))

# Pareto plot: quality vs cost
pareto_df <- cost_summary |>
  mutate(
    composite_quality = (mean_originality + mean_flexibility +
                         mean_elaboration) / 3,
    label = paste0(model_label, " (", condition, ")")
  )

p_pareto <- ggplot(pareto_df,
                   aes(mean_agent_cost, composite_quality,
                       color = condition, shape = model_label)) +
  geom_point(size = 4, alpha = 0.85) +
  ggrepel::geom_text_repel(aes(label = label), size = 3,
                           show.legend = FALSE, box.padding = 0.5,
                           max.overlaps = Inf) +
  scale_x_log10(labels = scales::dollar_format(accuracy = 0.001)) +
  scale_color_manual(values = c(default = "#888888",
                                tangent_return = "#1f77b4")) +
  labs(title = "AUT: quality vs cost (log $/call)",
       subtitle = "Up-and-left is the value-optimizer corner",
       x = "Mean agent cost per call ($, log scale)",
       y = "Composite quality (mean of originality / flexibility / elaboration)",
       color = "Condition", shape = "Model") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "right",
        panel.grid.minor = element_blank())

ggsave(here("results", "01_aut_pareto.png"), p_pareto,
       width = 9, height = 6, dpi = 160)

cat("\n=== Cost summary (model × condition) ===\n")
print(cost_summary |> select(model_label, condition, mean_agent_cost,
                              cost_per_1k_calls, mean_originality,
                              mean_flexibility, mean_elaboration))
cat("\n=== Value table (sorted by cost per quality point) ===\n")
print(value_table)

cat("\nWritten:\n  results/01_aut_cost_summary.csv\n",
    "  results/01_aut_value_table.csv\n",
    "  results/01_aut_pareto.png\n", sep = "")
