parse_uses_default <- function(response) {
  lines <- str_split(response, "\n")[[1]]
  num_lines <- str_subset(lines, "^\\s*\\d+[\\.\\)]\\s*\\S")
  uses <- str_replace(num_lines, "^\\s*\\d+[\\.\\)]\\s*", "")
  uses <- str_trim(uses)
  uses[nchar(uses) > 0]
}

parse_uses_tangent_return <- function(response) {
  lines <- str_split(response, "\n")[[1]]
  entries <- list()
  current <- list(tangent = NA_character_, use = NA_character_)
  flush <- function() {
    if (!is.na(current$use) && nchar(current$use) > 0) {
      entries[[length(entries) + 1L]] <<- current
    }
    current <<- list(tangent = NA_character_, use = NA_character_)
  }
  for (line in lines) {
    if (str_detect(line, "^\\s*\\d+[\\.\\)]")) {
      flush()
      after_num <- str_replace(line, "^\\s*\\d+[\\.\\)]\\s*", "")
      if (str_detect(after_num, regex("^\\s*Tangent\\s*:", ignore_case = TRUE))) {
        current$tangent <- str_trim(str_replace(after_num, regex("^\\s*Tangent\\s*:\\s*", ignore_case = TRUE), ""))
      }
    } else if (str_detect(line, regex("^\\s*Tangent\\s*:", ignore_case = TRUE))) {
      current$tangent <- str_trim(str_replace(line, regex("^\\s*Tangent\\s*:\\s*", ignore_case = TRUE), ""))
    } else if (str_detect(line, regex("^\\s*Use\\s*:", ignore_case = TRUE))) {
      current$use <- str_trim(str_replace(line, regex("^\\s*Use\\s*:\\s*", ignore_case = TRUE), ""))
    }
  }
  flush()
  tibble(
    tangent = vapply(entries, function(e) e$tangent, character(1)),
    use     = vapply(entries, function(e) e$use,     character(1))
  ) |> filter(!is.na(use) & nchar(use) > 0)
}

parse_response <- function(response, condition) {
  if (condition == "tangent_return") {
    pairs <- parse_uses_tangent_return(response)
    list(uses = pairs$use, tangents = pairs$tangent, n_pairs = nrow(pairs))
  } else {
    uses <- parse_uses_default(response)
    list(uses = uses, tangents = rep(NA_character_, length(uses)), n_pairs = length(uses))
  }
}

local_scores <- function(uses) {
  tibble(
    fluency_count = length(uses),
    elaboration_chars = if (length(uses) > 0) mean(nchar(uses)) else 0,
    elaboration_words = if (length(uses) > 0) mean(str_count(uses, "\\S+")) else 0
  )
}
