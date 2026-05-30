suppressPackageStartupMessages({
  required <- c("ellmer", "dplyr", "tidyr", "purrr", "readr", "stringr",
                "tibble", "jsonlite", "fs", "here", "glue", "httr2", "ggplot2")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop(
      "Missing R packages: ", paste(missing, collapse = ", "),
      "\nInstall with:\n  install.packages(c('",
      paste(missing, collapse = "', '"), "'))"
    )
  }
})

library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(jsonlite)
library(fs)
library(here)
library(glue)
library(httr2)
library(ellmer)
library(ggplot2)

load_dotenv <- function(path = here::here(".env")) {
  if (!file.exists(path)) return(invisible(NULL))
  lines <- readLines(path, warn = FALSE)
  lines <- lines[!grepl("^\\s*(#|$)", lines)]
  for (line in lines) {
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub('^"|"$', "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  invisible(NULL)
}

load_dotenv()

# Model matrix: 2 providers × 2 tiers
MODELS <- list(
  list(id = "claude-sonnet-4-5", provider = "anthropic", tier = "mid",      label = "sonnet-4.5"),
  list(id = "claude-opus-4-5",   provider = "anthropic", tier = "flagship", label = "opus-4.5"),
  list(id = "gpt-4o",            provider = "openai",    tier = "mid",      label = "gpt-4o"),
  list(id = "gpt-5",             provider = "openai",    tier = "flagship", label = "gpt-5")
)
# Note: ellmer/Anthropic resolve "claude-sonnet-4-5" and "claude-opus-4-5"
# to the latest 4-5 series snapshots. If you want the very latest models
# (sonnet-4-6 / opus-4-7), bump the IDs here.

MODEL_JUDGE <- "claude-sonnet-4-5"   # one judge across all conditions for consistency
EMBED_MODEL <- "text-embedding-3-large"
TEMP_AGENT  <- 1.0
TEMP_JUDGE  <- 0.0

dir_create(here("data", "runs"), recurse = TRUE)
dir_create(here("results"), recurse = TRUE)

provider_for <- function(model_id) {
  if (grepl("^claude", model_id)) "anthropic"
  else if (grepl("^(gpt|o\\d)", model_id)) "openai"
  else stop("Unknown provider for model: ", model_id)
}

make_chat <- function(model_id, system_prompt, temperature = TEMP_AGENT) {
  prov <- provider_for(model_id)
  args <- list(system_prompt = system_prompt, model = model_id, echo = "none")
  # Some models (o-series reasoning, gpt-5) don't accept temperature
  no_temp <- grepl("^(o\\d|gpt-5)", model_id)
  if (!is.null(temperature) && !no_temp) {
    args$params <- params(temperature = temperature)
  }
  if (prov == "anthropic") {
    do.call(chat_anthropic, args)
  } else {
    do.call(chat_openai, args)
  }
}
