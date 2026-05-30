# Experiment 01a — falsification ablations for the cognitive-operation claim.
#
# The headline finding of experiment 01 (tangent-return improves AUT scores
# across 3 of 4 models) has three competing explanations:
#   (1) tangent-return cognitive operation does real work
#   (2) tangent-return responses are longer (~2× tokens) — model "thinks more"
#   (3) the tangent-return prompt has worked examples — few-shot is the lever
#
# This script falsifies (2) and (3) by adding two new control conditions:
#   - default_long:     default prompt + explicit length instruction matching TR
#   - default_examples: default prompt + same examples as TR but tangent labels stripped
#
# Run on the three Anthropic + GPT-4o models (skip gpt-5 — at ceiling on judge
# scores; ablations are uninformative there and gpt-5 is 12× more expensive).

source(here::here("R", "config.R"))
source(here::here("R", "prompts.R"))
source(here::here("R", "agents.R"))
source(here::here("R", "scoring.R"))
source(here::here("R", "judge.R"))
source(here::here("R", "embeddings.R"))

args <- commandArgs(trailingOnly = TRUE)
SMOKE <- "--smoke" %in% args

ablation_conditions <- c("default_long", "default_examples")
ablation_models <- list(
  list(id = "claude-sonnet-4-5", label = "sonnet-4.5"),
  list(id = "claude-opus-4-5",   label = "opus-4.5"),
  list(id = "gpt-4o",            label = "gpt-4o")
)

tasks <- fromJSON(here("data", "tasks", "aut.json"), simplifyDataFrame = FALSE)
seeds <- if (SMOKE) 1L else 1:3
if (SMOKE) {
  tasks <- tasks[1]
  ablation_models <- ablation_models[1]
}

design <- expand_grid(
  model_idx = seq_along(ablation_models),
  task_idx  = seq_along(tasks),
  condition = ablation_conditions,
  seed      = seeds
) |>
  mutate(
    model_id    = vapply(model_idx, function(i) ablation_models[[i]]$id,    character(1)),
    model_label = vapply(model_idx, function(i) ablation_models[[i]]$label, character(1)),
    task_id     = vapply(task_idx,  function(i) tasks[[i]]$id,             character(1)),
    object      = vapply(task_idx,  function(i) tasks[[i]]$object,         character(1))
  )

message("Running ", nrow(design), " ablation calls (",
        length(ablation_models), " models × ", length(tasks), " tasks × ",
        length(ablation_conditions), " conditions × ", length(seeds), " seeds)")

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
suffix <- if (SMOKE) "_smoke" else ""
runs_path <- here("data", "runs", glue("01a_ablations_runs_{stamp}{suffix}.jsonl"))
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
    parsed = list(parse_response(response, condition)),
    uses   = list(parsed$uses),
    fluency_count = length(parsed$uses),
    elaboration_words = if (length(parsed$uses) > 0) mean(str_count(parsed$uses, "\\S+")) else 0
  ) |>
  ungroup()

message("Judging ", nrow(parsed), " responses…")
judge_results <- vector("list", nrow(parsed))
for (i in seq_len(nrow(parsed))) {
  message(sprintf("  judge [%d/%d] %s · %s · %s · seed=%d",
                  i, nrow(parsed), parsed$model_label[i], parsed$task_id[i],
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
    tryCatch(within_response_diversity(uses), error = function(e) NA_real_)
  }, numeric(1))
} else {
  parsed$semantic_diversity <- NA_real_
}

saveRDS(parsed, here("results", glue("01a_ablations_parsed{suffix}.rds")))

summary_df <- parsed |>
  group_by(model_label, condition) |>
  summarise(
    n_responses        = n(),
    mean_tokens_out    = mean(tokens_out, na.rm = TRUE),
    mean_fluency_count = mean(fluency_count),
    mean_judge_fluency = mean(judge_fluency,     na.rm = TRUE),
    mean_judge_original= mean(judge_originality, na.rm = TRUE),
    mean_judge_flex    = mean(judge_flexibility, na.rm = TRUE),
    mean_judge_elab    = mean(judge_elaboration, na.rm = TRUE),
    mean_sem_diversity = mean(semantic_diversity, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(summary_df, here("results", glue("01a_ablations_summary{suffix}.csv")))

cat("\n=== Ablation summary (model × condition means) ===\n")
print(summary_df)

cat("\nRaw runs: ", runs_path, "\n")
