make_judge_cache_key <- function(model_label, task_id, condition, seed) {
  paste(model_label, task_id, condition, seed, sep = "|")
}

judge_cache_filename <- function(key) {
  safe <- gsub("[^A-Za-z0-9_.=-]+", "__", key)
  paste0(safe, ".json")
}

judge_cache_file <- function(cache_dir, key) {
  file.path(cache_dir, judge_cache_filename(key))
}

read_judge_cache_row <- function(cache_dir, key, judge_model) {
  path <- judge_cache_file(cache_dir, key)
  if (!file.exists(path)) return(NULL)
  row <- as_tibble(fromJSON(path, flatten = TRUE))
  if (!identical(as.character(row$judge_model[[1]]), as.character(judge_model))) {
    return(NULL)
  }
  row
}

write_judge_cache_row <- function(cache_dir, key, row) {
  dir_create(cache_dir, recurse = TRUE)
  path <- judge_cache_file(cache_dir, key)
  tmp <- file.path(
    cache_dir,
    paste0(".", basename(path), ".", Sys.getpid(), ".", sample.int(1e9, 1), ".tmp")
  )
  write(toJSON(row, auto_unbox = TRUE), tmp)
  if (!file.rename(tmp, path)) {
    file_delete(tmp)
    stop("Could not atomically write judge cache file: ", path)
  }
  path
}

judge_response_with_retry <- function(object, uses, model_id, judge_fn,
                                      max_tries = 5L, sleep_fn = Sys.sleep) {
  last_error <- NULL
  for (attempt in seq_len(max_tries)) {
    result <- tryCatch(
      judge_fn(object = object, uses = uses, model_id = model_id),
      error = function(e) {
        last_error <<- e
        NULL
      }
    )
    if (!is.null(result)) return(result)

    if (attempt < max_tries) {
      wait <- min(30, 2 ^ (attempt - 1))
      message("    ! judge attempt ", attempt, "/", max_tries,
              " failed: ", conditionMessage(last_error),
              " - retrying in ", wait, "s")
      sleep_fn(wait)
    }
  }
  stop(conditionMessage(last_error))
}

score_one_row_with_cache <- function(row, cache_dir, judge_model, judge_fn,
                                     max_tries = 5L, allow_failures = FALSE) {
  key <- row$judge_cache_key[[1]]
  run_row_id <- if ("run_row_id" %in% names(row)) row$run_row_id[[1]] else NA_integer_
  cached <- read_judge_cache_row(cache_dir, key, judge_model)
  if (!is.null(cached)) {
    return(cached |>
             select(fluency, originality, flexibility, elaboration, notes))
  }

  result <- tryCatch(
    judge_response_with_retry(
      object = row$object[[1]],
      uses = row$uses[[1]],
      model_id = judge_model,
      judge_fn = judge_fn,
      max_tries = max_tries
    ),
    error = function(e) {
      if (!allow_failures) stop(e)
      tibble(
        fluency = NA_integer_,
        originality = NA_integer_,
        flexibility = NA_integer_,
        elaboration = NA_integer_,
        notes = paste("error:", conditionMessage(e))
      )
    }
  )

  cache_row <- result |>
    mutate(
      judge_cache_key = key,
      judge_model = judge_model,
      run_row_id = run_row_id,
      model_label = row$model_label[[1]],
      task_id = row$task_id[[1]],
      condition = row$condition[[1]],
      seed = row$seed[[1]],
      cached_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    )
  write_judge_cache_row(cache_dir, key, cache_row)
  result |> select(fluency, originality, flexibility, elaboration, notes)
}

score_rows_with_cache <- function(parsed, cache_dir, judge_model, judge_fn,
                                  jobs = 1L, max_tries = 5L,
                                  allow_failures = FALSE) {
  dir_create(cache_dir, recurse = TRUE)
  rows <- split(parsed, seq_len(nrow(parsed)))
  jobs <- max(1L, as.integer(jobs))

  worker <- function(row) {
    score_one_row_with_cache(
      row = row,
      cache_dir = cache_dir,
      judge_model = judge_model,
      judge_fn = judge_fn,
      max_tries = max_tries,
      allow_failures = allow_failures
    )
  }

  if (jobs > 1L) {
    repo_dir <- getwd()
    cl <- parallel::makeCluster(jobs, type = "PSOCK")
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterExport(
      cl,
      varlist = c("repo_dir", "cache_dir", "judge_model", "judge_fn", "max_tries", "allow_failures"),
      envir = environment()
    )
    parallel::clusterEvalQ(cl, {
      setwd(repo_dir)
      source("R/config.R")
      source("R/judge.R")
      source("R/judge_cache.R")
      NULL
    })
    results <- parallel::parLapplyLB(cl, rows, worker)
  } else {
    results <- lapply(rows, worker)
  }

  bind_rows(results)
}
