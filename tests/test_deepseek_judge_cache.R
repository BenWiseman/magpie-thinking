suppressPackageStartupMessages({
  source("R/config.R")
  source("R/judge_cache.R")
})

make_rows <- function() {
  tibble::tibble(
    model_label = "deepseek-v4-flash",
    task_id = c("brick", "brick", "spoon", "spoon"),
    condition = c("default", "tangent_return", "default", "tangent_return"),
    seed = c(1L, 1L, 1L, 1L),
    object = c("brick", "brick", "spoon", "spoon"),
    uses = list("doorstop", "thermal mass", "mirror", "wind chime"),
    judge_cache_key = make_judge_cache_key(model_label, task_id, condition, seed)
  )
}

expect_true <- function(x, msg) {
  if (!isTRUE(x)) stop(msg, call. = FALSE)
}

expect_equal <- function(x, y, msg) {
  if (!identical(x, y)) {
    stop(sprintf("%s\nactual: %s\nexpected: %s", msg, deparse(x), deparse(y)), call. = FALSE)
  }
}

cache_dir <- tempfile("judge-cache-")
dir.create(cache_dir)
rows <- make_rows()
calls_file <- tempfile("judge-calls-")

fake_judge <- local({
  log_path <- calls_file
  function(object, uses, model_id) {
    cat(object, "\n", file = log_path, append = TRUE, sep = "")
    tibble::tibble(
      fluency = 2L,
      originality = 3L,
      flexibility = 4L,
      elaboration = 5L,
      notes = paste("judged", object, "with", model_id)
    )
  }
})

first <- score_rows_with_cache(
  rows[1:2, ],
  cache_dir = cache_dir,
  judge_model = "fake-sonnet",
  judge_fn = fake_judge,
  jobs = 1L,
  max_tries = 1L
)

expect_equal(nrow(first), 2L, "first run should return two judge rows")
expect_equal(length(list.files(cache_dir, pattern = "\\.json$")), 2L,
             "first run should persist each successful judge row")

calls_after_first <- readLines(calls_file)
expect_equal(calls_after_first, c("brick", "brick"),
             "first run should call fake judge for uncached rows")

second <- score_rows_with_cache(
  rows,
  cache_dir = cache_dir,
  judge_model = "fake-sonnet",
  judge_fn = fake_judge,
  jobs = 2L,
  max_tries = 1L
)

expect_equal(nrow(second), 4L, "resume run should return all rows")
expect_equal(length(list.files(cache_dir, pattern = "\\.json$")), 4L,
             "resume run should preserve cached rows and add missing rows")

calls_after_second <- readLines(calls_file)
expect_equal(calls_after_second[1:2], c("brick", "brick"),
             "resume should not re-call already cached rows")
expect_true(all(c("spoon", "spoon") %in% calls_after_second[3:4]),
            "resume should call fake judge only for missing rows")

cat("judge cache tests passed\n")
