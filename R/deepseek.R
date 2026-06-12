DEEPSEEK_MODELS <- list(
  list(
    id = "deepseek-chat",
    provider = "deepseek",
    tier = "flash_alias",
    label = "deepseek-chat"
  ),
  list(
    id = "deepseek-v4-flash",
    provider = "deepseek",
    tier = "flash",
    label = "deepseek-v4-flash"
  ),
  list(
    id = "deepseek-reasoner",
    provider = "deepseek",
    tier = "flash_reasoning_alias",
    label = "deepseek-reasoner"
  ),
  list(
    id = "deepseek-v4-pro",
    provider = "deepseek",
    tier = "pro",
    label = "deepseek-v4-pro"
  )
)

DEEPSEEK_PRICING <- list(
  # USD per 1M tokens, verified 2026-06-12 from DeepSeek API docs.
  # deepseek-chat and deepseek-reasoner are temporary aliases to V4 Flash.
  "deepseek-chat"     = list(cache_hit = 0.0028, cache_miss = 0.14, output = 0.28),
  "deepseek-reasoner" = list(cache_hit = 0.0028, cache_miss = 0.14, output = 0.28),
  "deepseek-v4-flash" = list(cache_hit = 0.0028, cache_miss = 0.14, output = 0.28),
  "deepseek-v4-pro"   = list(cache_hit = 0.003625, cache_miss = 0.435, output = 0.87)
)

deepseek_value <- function(x, default = NA) {
  if (is.null(x)) default else x
}

deepseek_generation_cost <- function(model_id, cache_hit_tokens, cache_miss_tokens,
                                     tokens_in, tokens_out) {
  p <- DEEPSEEK_PRICING[[model_id]]
  if (is.null(p)) {
    warning("No DeepSeek pricing for ", model_id, "; returning NA")
    return(NA_real_)
  }

  hit <- deepseek_value(cache_hit_tokens, NA_real_)
  miss <- deepseek_value(cache_miss_tokens, NA_real_)
  if (is.na(hit) && is.na(miss)) {
    hit <- 0
    miss <- tokens_in
  } else {
    hit <- deepseek_value(hit, 0)
    miss <- deepseek_value(miss, 0)
  }

  (hit * p$cache_hit + miss * p$cache_miss + tokens_out * p$output) / 1e6
}

run_deepseek_agent <- function(condition, object, seed = 1L,
                               model_id = "deepseek-v4-flash",
                               thinking = "disabled",
                               temperature = TEMP_AGENT) {
  key <- Sys.getenv("DEEPSEEK_API_KEY")
  if (key == "") stop("DEEPSEEK_API_KEY not set in shell env or .env")

  p <- build_prompt(condition, object)
  body <- list(
    model = model_id,
    messages = list(
      list(role = "system", content = p$system),
      list(role = "user", content = p$user)
    ),
    stream = FALSE
  )
  if (grepl("^deepseek-v4", model_id)) {
    body$thinking <- list(type = thinking)
  }
  if (!is.null(temperature)) body$temperature <- temperature

  resp <- request("https://api.deepseek.com/chat/completions") |>
    req_headers(
      Authorization = paste("Bearer", key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(body) |>
    req_retry(max_tries = 4) |>
    req_perform()

  payload <- resp_body_json(resp)
  usage <- payload$usage
  tokens_in <- as.integer(deepseek_value(usage$prompt_tokens, NA_integer_))
  tokens_out <- as.integer(deepseek_value(usage$completion_tokens, NA_integer_))
  cache_hit_tokens <- as.integer(deepseek_value(usage$prompt_cache_hit_tokens, NA_integer_))
  cache_miss_tokens <- as.integer(deepseek_value(usage$prompt_cache_miss_tokens, NA_integer_))
  generation_cost <- deepseek_generation_cost(
    model_id = model_id,
    cache_hit_tokens = cache_hit_tokens,
    cache_miss_tokens = cache_miss_tokens,
    tokens_in = tokens_in,
    tokens_out = tokens_out
  )

  message <- payload$choices[[1]]$message
  content <- deepseek_value(message$content, "")
  reasoning_content <- as.character(deepseek_value(message$reasoning_content, NA_character_))

  tibble(
    condition = condition,
    object = object,
    seed = as.integer(seed),
    model = model_id,
    provider = "deepseek",
    thinking = thinking,
    temperature = temperature,
    response = as.character(content),
    reasoning_content = reasoning_content,
    tokens_in = tokens_in,
    tokens_out = tokens_out,
    total_tokens = as.integer(deepseek_value(usage$total_tokens, NA_integer_)),
    prompt_cache_hit_tokens = cache_hit_tokens,
    prompt_cache_miss_tokens = cache_miss_tokens,
    generation_cost_usd = generation_cost,
    returned_model = as.character(deepseek_value(payload$model, model_id)),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}
