source(here::here("R", "config.R"))
source(here::here("R", "prompts.R"))
source(here::here("R", "deepseek.R"))
source(here::here("R", "scoring.R"))
source(here::here("R", "judge.R"))
source(here::here("R", "judge_cache.R"))
source(here::here("R", "embeddings.R"))

args <- commandArgs(trailingOnly = TRUE)
SKIP_JUDGE <- "--no-judge" %in% args
SKIP_EMBED <- "--no-embed" %in% args
ALLOW_JUDGE_FAILURES <- "--allow-judge-failures" %in% args
RESET_JUDGE_CACHE <- "--reset-judge-cache" %in% args

arg_value <- function(prefix, default = NULL) {
  hit <- args[grepl(paste0("^", prefix), args)]
  if (length(hit) == 0) return(default)
  sub(paste0("^", prefix), "", hit[[1]])
}

runs_path <- arg_value("--runs=", NULL)
if (is.null(runs_path)) {
  candidates <- list.files(
    here("data", "runs"),
    pattern = "^01_deepseek_aut_disabled_runs_.*\\.jsonl$",
    full.names = TRUE
  )
  if (length(candidates) == 0) stop("No DeepSeek AUT run JSONL found")
  runs_path <- candidates[which.max(file.info(candidates)$mtime)]
}

judge_model <- arg_value("--judge-model=", MODEL_JUDGE)
tag <- arg_value("--tag=", tools::file_path_sans_ext(basename(runs_path)))
JUDGE_MAX_TRIES <- as.integer(arg_value("--judge-max-tries=", "5"))
JUDGE_JOBS <- as.integer(arg_value("--judge-jobs=", "4"))

message("Postprocessing DeepSeek run: ", runs_path)
message("Judge model: ", if (SKIP_JUDGE) "<skipped>" else judge_model)

read_run_jsonl <- function(path) {
  lines <- readLines(path, warn = FALSE)
  rows <- lapply(lines, function(line) {
    parsed <- fromJSON(line, flatten = TRUE)
    as_tibble(parsed)
  })
  bind_rows(rows)
}

runs_df <- read_run_jsonl(runs_path)
message("Loaded ", nrow(runs_df), " responses")
if (nrow(runs_df) == 0) stop("No responses loaded")

parsed <- runs_df |>
  rowwise() |>
  mutate(
    parsed = list(parse_response(response, condition)),
    uses = list(parsed$uses),
    tangents = list(parsed$tangents),
    fluency_count = length(parsed$uses),
    elaboration_words = if (length(parsed$uses) > 0) mean(str_count(parsed$uses, "\\S+")) else 0
  ) |>
  ungroup() |>
  mutate(
    run_row_id = row_number(),
    judge_cache_key = make_judge_cache_key(model_label, task_id, condition, seed)
  )

if (!SKIP_JUDGE) {
  judge_cache_dir <- here("results", glue("{tag}_judge_cache"))
  if (RESET_JUDGE_CACHE && dir_exists(judge_cache_dir)) dir_delete(judge_cache_dir)
  message("Judging ", nrow(parsed), " responses with ", judge_model,
          " using ", JUDGE_JOBS, " worker(s)…")
  message("Judge cache: ", judge_cache_dir)
  judge_fn <- function(object, uses, model_id) {
    judge_response(object, uses, model_id = model_id)
  }
  judge_df <- score_rows_with_cache(
    parsed = parsed,
    cache_dir = judge_cache_dir,
    judge_model = judge_model,
    judge_fn = judge_fn,
    jobs = JUDGE_JOBS,
    max_tries = JUDGE_MAX_TRIES,
    allow_failures = ALLOW_JUDGE_FAILURES
  )
  parsed <- bind_cols(parsed, judge_df |> rename_with(~ paste0("judge_", .x)))
} else {
  message("--no-judge set — skipping AUT judge")
  parsed <- parsed |>
    mutate(
      judge_fluency = NA_integer_,
      judge_originality = NA_integer_,
      judge_flexibility = NA_integer_,
      judge_elaboration = NA_integer_,
      judge_notes = NA_character_
    )
}

if (!SKIP_EMBED && Sys.getenv("OPENAI_API_KEY") != "") {
  message("Embedding for within-response diversity…")
  parsed$semantic_diversity <- vapply(parsed$uses, function(uses) {
    tryCatch(within_response_diversity(uses), error = function(e) {
      message("    ! embed error: ", conditionMessage(e))
      NA_real_
    })
  }, numeric(1))
} else {
  message("Skipping embeddings")
  parsed$semantic_diversity <- NA_real_
}

summary_df <- parsed |>
  group_by(model_label, condition, thinking) |>
  summarise(
    n_responses = n(),
    total_generation_cost_usd = sum(generation_cost_usd, na.rm = TRUE),
    mean_generation_cost_usd = mean(generation_cost_usd, na.rm = TRUE),
    cost_per_1k_generations_usd = mean_generation_cost_usd * 1000,
    mean_tokens_in = mean(tokens_in, na.rm = TRUE),
    mean_tokens_out = mean(tokens_out, na.rm = TRUE),
    mean_cache_hit_tokens = mean(prompt_cache_hit_tokens, na.rm = TRUE),
    mean_cache_miss_tokens = mean(prompt_cache_miss_tokens, na.rm = TRUE),
    mean_fluency_count = mean(fluency_count),
    mean_judge_fluency = mean(judge_fluency, na.rm = TRUE),
    mean_judge_original = mean(judge_originality, na.rm = TRUE),
    mean_judge_flex = mean(judge_flexibility, na.rm = TRUE),
    mean_judge_elab = mean(judge_elaboration, na.rm = TRUE),
    mean_sem_diversity = mean(semantic_diversity, na.rm = TRUE),
    composite_quality = (mean_judge_original + mean_judge_flex + mean_judge_elab) / 3,
    cost_per_quality_point = mean_generation_cost_usd / composite_quality,
    .groups = "drop"
  )

per_task <- parsed |>
  group_by(model_label, task_id, object, condition, thinking) |>
  summarise(
    fluency_count = mean(fluency_count),
    tokens_out = mean(tokens_out, na.rm = TRUE),
    generation_cost_usd = mean(generation_cost_usd, na.rm = TRUE),
    judge_fluency = mean(judge_fluency, na.rm = TRUE),
    judge_originality = mean(judge_originality, na.rm = TRUE),
    judge_flexibility = mean(judge_flexibility, na.rm = TRUE),
    judge_elaboration = mean(judge_elaboration, na.rm = TRUE),
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
    metric = metric,
    n_tasks = length(diff),
    mean_diff = mean(diff),
    sd_diff = sd(diff),
    t_p = if (!is.null(t)) t$p.value else NA_real_,
    wilcox_p = if (!is.null(w)) w$p.value else NA_real_
  )
}

stats_df <- per_task |>
  group_by(model_label) |>
  group_split() |>
  lapply(function(df) {
    bind_rows(lapply(
      c("fluency_count", "tokens_out", "generation_cost_usd", "judge_fluency",
        "judge_originality", "judge_flexibility", "judge_elaboration",
        "semantic_diversity"),
      paired_test, df = df
    ))
  }) |>
  bind_rows()

value_table <- summary_df |>
  arrange(cost_per_quality_point) |>
  select(model_label, condition, thinking, mean_generation_cost_usd,
         cost_per_1k_generations_usd, composite_quality, mean_judge_original,
         mean_judge_flex, mean_judge_elab, mean_sem_diversity,
         cost_per_quality_point)

write_csv(summary_df, here("results", glue("{tag}_summary.csv")))
write_csv(per_task, here("results", glue("{tag}_per_task.csv")))
write_csv(stats_df, here("results", glue("{tag}_stats.csv")))
write_csv(value_table, here("results", glue("{tag}_value_table.csv")))
saveRDS(parsed, here("results", glue("{tag}_parsed.rds")))

if (nrow(per_task) > 0 && length(unique(per_task$condition)) == 2) {
  plot_df <- per_task |>
    select(model_label, task_id, condition,
           judge_originality, judge_flexibility, judge_elaboration,
           semantic_diversity, generation_cost_usd) |>
    pivot_longer(c(judge_originality, judge_flexibility, judge_elaboration,
                   semantic_diversity, generation_cost_usd),
                 names_to = "metric", values_to = "value")
  p <- ggplot(plot_df, aes(condition, value, fill = condition)) +
    geom_boxplot(outlier.size = 0.6, width = 0.55, alpha = 0.85) +
    geom_jitter(width = 0.15, alpha = 0.3, size = 0.8) +
    facet_grid(metric ~ model_label, scales = "free_y") +
    scale_fill_manual(values = c(default = "#bdbdbd", tangent_return = "#1f77b4")) +
    labs(title = glue("DeepSeek AUT: default vs tangent-return ({judge_model} judge)"),
         x = NULL, y = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "none",
          strip.text.y = element_text(angle = 0, hjust = 0),
          panel.grid.minor = element_blank())
  ggsave(here("results", glue("{tag}_plot.png")),
         p, width = 2 + 2.2 * length(unique(plot_df$model_label)),
         height = 8, dpi = 160)
}

cat("\n=== DeepSeek summary (model × condition means) ===\n")
print(summary_df)
cat("\n=== DeepSeek paired stats (tangent_return − default, by task, per model) ===\n")
print(stats_df)
cat("\n=== DeepSeek value table (sorted by generation cost / quality) ===\n")
print(value_table)

cat("\nInput runs: ", runs_path, "\n")
cat("Results   : ", here("results"), "\n")
