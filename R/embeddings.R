embed_openai <- function(texts, model = EMBED_MODEL) {
  key <- Sys.getenv("OPENAI_API_KEY")
  if (key == "") stop("OPENAI_API_KEY not set in shell env or .env")

  if (length(texts) == 0) return(matrix(numeric(0), nrow = 0, ncol = 0))

  body <- list(input = as.list(texts), model = model)

  resp <- request("https://api.openai.com/v1/embeddings") |>
    req_headers(
      Authorization = paste("Bearer", key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(body) |>
    req_retry(max_tries = 3) |>
    req_perform()

  payload <- resp_body_json(resp)
  embeddings <- lapply(payload$data, function(d) unlist(d$embedding))
  do.call(rbind, embeddings)
}

cosine_dist_matrix <- function(M) {
  if (nrow(M) < 2) return(matrix(0, nrow(M), nrow(M)))
  norm <- sqrt(rowSums(M^2))
  M_n <- M / norm
  sim <- M_n %*% t(M_n)
  1 - sim
}

within_response_diversity <- function(uses) {
  if (length(uses) < 2) return(NA_real_)
  M <- embed_openai(uses)
  D <- cosine_dist_matrix(M)
  mean(D[upper.tri(D)])
}
