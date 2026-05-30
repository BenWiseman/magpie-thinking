source(here::here("R", "config.R"))
source(here::here("R", "prompts.R"))
source(here::here("R", "agents.R"))
source(here::here("R", "scoring.R"))
source(here::here("R", "judge.R"))
source(here::here("R", "embeddings.R"))

args <- commandArgs(trailingOnly = TRUE)
SMOKE <- "--smoke" %in% args
MODEL_FILTER <- NULL
if (any(grepl("^--models=", args))) {
  MODEL_FILTER <- strsplit(sub("^--models=", "", args[grepl("^--models=", args)]), ",")[[1]]
}

tasks <- fromJSON(here("data", "tasks", "aut.json"), simplifyDataFrame = FALSE)
conditions <- c("default", "tangent_return")
seeds <- if (SMOKE) 1L else 1:3

models_to_run <- MODELS
if (!is.null(MODEL_FILTER)) {
  models_to_run <- Filter(function(m) m$label %in% MODEL_FILTER || m$id %in% MODEL_FILTER, MODELS)
}
if (SMOKE) {
  tasks <- tasks[1]
  if (is.null(MODEL_FILTER)) {
    models_to_run <- Filter(function(m) m$id == "claude-sonnet-4-5", MODELS)
  }
}

design <- expand_grid(
  model_idx = seq_along(models_to_run),
  task_idx  = seq_along(tasks),
  condition = conditions,
  seed      = seeds
) |>
  mutate(
    model_id    = vapply(model_idx, function(i) models_to_run[[i]]$id,    character(1)),
    model_label = vapply(model_idx, function(i) models_to_run[[i]]$label, character(1)),
    task_id     = vapply(task_idx,  function(i) tasks[[i]]$id,            character(1)),
    object      = vapply(task_idx,  function(i) tasks[[i]]$object,        character(1))
  )

message("Running ", nrow(design), " agent calls (",
        length(models_to_run), " models × ",
        length(tasks), " tasks × ",
        length(conditions), " conditions × ",
        length(seeds), " seeds)")

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
suffix <- if (SMOKE) "_smoke" else ""
runs_path <- here("data", "runs", glue("01_aut_runs_{stamp}{suffix}.jsonl"))
runs <- list()

t0 <- Sys.time()
for (i in seq_len(nrow(design))) {
  row <- design[i, ]
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  message(sprintf("  [%d/%d  %.0fs] %s · %s · %s · seed=%d",
                  i, nrow(design), elapsed,
                  row$model_label, row$task_id, row$condition, row$seed))
  result <- tryCatch(
    run_agent(row$condition, row$object, seed = row$seed, model_id = row$model_id),
    error = function(e) {
      message("    ! agent error: ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(result)) {
    result$task_id     <- row$task_id
    result$model_label <- row$model_label
    runs[[length(runs) + 1L]] <- result
    write(toJSON(result, auto_unbox = TRUE), runs_path, append = TRUE)
  }
}

runs_df <- bind_rows(runs)
message("Generation done: ", nrow(runs_df), " responses")

if (nrow(runs_df) == 0) stop("No successful agent runs; aborting.")

parsed <- runs_df |>
  rowwise() |>
  mutate(
    parsed            = list(parse_response(response, condition)),
    uses              = list(parsed$uses),
    tangents          = list(parsed$tangents),
    fluency_count     = length(parsed$uses),
    elaboration_words = if (length(parsed$uses) > 0) mean(str_count(parsed$uses, "\\S+")) else 0
  ) |>
  ungroup()

message("Judging ", nrow(parsed), " responses…")
judge_results <- vector("list", nrow(parsed))
for (i in seq_len(nrow(parsed))) {
  message(sprintf("  judge [%d/%d] %s · %s · %s · seed=%d",
                  i, nrow(parsed),
                  parsed$model_label[i], parsed$task_id[i],
                  parsed$condition[i], parsed$seed[i]))
  judge_results[[i]] <- tryCatch(
    judge_response(parsed$object[i], parsed$uses[[i]]),
    error = function(e) {
      message("    ! judge error: ", conditionMessage(e))
      tibble(fluency = NA_integer_, originality = NA_integer_,
             flexibility = NA_integer_, elaboration = NA_integer_,
             notes = paste("error:", conditionMessage(e)))
    }
  )
}
judge_df <- bind_rows(judge_results)
parsed <- bind_cols(parsed, judge_df |> rename_with(~ paste0("judge_", .x)))

if (Sys.getenv("OPENAI_API_KEY") != "") {
  message("Embedding for within-response diversity…")
  parsed$semantic_diversity <- vapply(parsed$uses, function(uses) {
    tryCatch(within_response_diversity(uses), error = function(e) {
      message("    ! embed error: ", conditionMessage(e))
      NA_real_
    })
  }, numeric(1))
} else {
  message("OPENAI_API_KEY not set — skipping embeddings")
  parsed$semantic_diversity <- NA_real_
}

summary_df <- parsed |>
  group_by(model_label, condition) |>
  summarise(
    n_responses          = n(),
    mean_tokens_out      = mean(tokens_out, na.rm = TRUE),
    mean_fluency_count   = mean(fluency_count),
    mean_judge_fluency   = mean(judge_fluency,     na.rm = TRUE),
    mean_judge_original  = mean(judge_originality, na.rm = TRUE),
    mean_judge_flex      = mean(judge_flexibility, na.rm = TRUE),
    mean_judge_elab      = mean(judge_elaboration, na.rm = TRUE),
    mean_sem_diversity   = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

per_task <- parsed |>
  group_by(model_label, task_id, object, condition) |>
  summarise(
    fluency_count      = mean(fluency_count),
    tokens_out         = mean(tokens_out, na.rm = TRUE),
    judge_fluency      = mean(judge_fluency,     na.rm = TRUE),
    judge_originality  = mean(judge_originality, na.rm = TRUE),
    judge_flexibility  = mean(judge_flexibility, na.rm = TRUE),
    judge_elaboration  = mean(judge_elaboration, na.rm = TRUE),
    semantic_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

paired_test <- function(metric, df) {
  wide <- df |>
    select(model_label, task_id, condition, value = all_of(metric)) |>
    pivot_wider(names_from = condition, values_from = value)
  if (!all(c("default", "tangent_return") %in% names(wide))) return(NULL)
  diff <- wide$tangent_return - wide$default
  diff <- diff[!is.na(diff)]
  if (length(diff) < 2) return(NULL)
  t <- tryCatch(t.test(diff), error = function(e) NULL)
  w <- tryCatch(wilcox.test(diff), error = function(e) NULL)
  tibble(
    model_label = unique(df$model_label),
    metric      = metric,
    n_tasks     = length(diff),
    mean_diff   = mean(diff),
    sd_diff     = sd(diff),
    t_p         = if (!is.null(t)) t$p.value else NA_real_,
    wilcox_p    = if (!is.null(w)) w$p.value else NA_real_
  )
}

stats_df <- per_task |>
  group_by(model_label) |>
  group_split() |>
  lapply(function(df) {
    bind_rows(lapply(
      c("fluency_count", "tokens_out", "judge_fluency", "judge_originality",
        "judge_flexibility", "judge_elaboration", "semantic_diversity"),
      paired_test, df = df
    ))
  }) |>
  bind_rows()

write_csv(summary_df, here("results", glue("01_aut_summary{suffix}.csv")))
write_csv(per_task,   here("results", glue("01_aut_per_task{suffix}.csv")))
write_csv(stats_df,   here("results", glue("01_aut_stats{suffix}.csv")))
saveRDS(parsed,       here("results", glue("01_aut_parsed{suffix}.rds")))

if (nrow(per_task) > 0 && length(unique(per_task$condition)) == 2) {
  plot_df <- per_task |>
    select(model_label, task_id, condition,
           judge_originality, judge_flexibility, judge_elaboration, semantic_diversity) |>
    pivot_longer(c(judge_originality, judge_flexibility, judge_elaboration, semantic_diversity),
                 names_to = "metric", values_to = "value")
  p <- ggplot(plot_df, aes(condition, value, fill = condition)) +
    geom_boxplot(outlier.size = 0.6, width = 0.55, alpha = 0.85) +
    geom_jitter(width = 0.15, alpha = 0.3, size = 0.8) +
    facet_grid(metric ~ model_label, scales = "free_y") +
    scale_fill_manual(values = c(default = "#bdbdbd", tangent_return = "#1f77b4")) +
    labs(title = "AUT: default vs tangent-return across models",
         x = NULL, y = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "none",
          strip.text.y = element_text(angle = 0, hjust = 0),
          panel.grid.minor = element_blank())
  ggsave(here("results", glue("01_aut_plot{suffix}.png")),
         p, width = 2 + 2.2 * length(unique(plot_df$model_label)),
         height = 7, dpi = 160)
}

cat("\n=== Summary (model × condition means) ===\n")
print(summary_df)
cat("\n=== Paired stats (tangent_return − default, by task, per model) ===\n")
print(stats_df)

cat("\nRaw runs : ", runs_path, "\n")
cat("Results  : ", here("results"), "\n")
