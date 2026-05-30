run_agent <- function(condition, object, seed = 1L,
                      model_id = "claude-sonnet-4-5",
                      temperature = TEMP_AGENT) {
  p <- build_prompt(condition, object)

  chat <- make_chat(model_id, system_prompt = p$system, temperature = temperature)
  response <- chat$chat(p$user, echo = "none")

  # Token accounting — robust access; ellmer 0.4+ uses S7 (@), older versions use $
  tokens_in <- tokens_out <- NA_integer_
  tryCatch({
    last <- chat$last_turn()
    tk <- tryCatch(last@tokens, error = function(e) last$tokens)
    if (!is.null(tk)) {
      tokens_in  <- as.integer(tk[["input"]]  %||% tk[1])
      tokens_out <- as.integer(tk[["output"]] %||% tk[2])
    }
  }, error = function(e) NULL)

  tibble(
    condition   = condition,
    object      = object,
    seed        = as.integer(seed),
    model       = model_id,
    provider    = provider_for(model_id),
    temperature = temperature,
    response    = as.character(response),
    tokens_in   = as.integer(tokens_in),
    tokens_out  = as.integer(tokens_out),
    timestamp   = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}
