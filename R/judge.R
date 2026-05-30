SYSTEM_JUDGE <- "You are an expert scorer for the Alternative Uses Test, a classic measure of divergent creative thinking. Score strictly and consistently; calibrate scores against a typical adult human's responses to the same prompt."

judge_response <- function(object, uses,
                           model_id = MODEL_JUDGE,
                           temperature = TEMP_JUDGE) {
  if (length(uses) == 0) {
    return(tibble(
      fluency = 1L, originality = 1L, flexibility = 1L, elaboration = 1L,
      notes = "no parseable uses"
    ))
  }

  uses_text <- paste0(seq_along(uses), ". ", uses, collapse = "\n")
  user <- glue("
Object: {object}

List of uses to score:
{uses_text}

Score this list on the four standard AUT dimensions, each 1-5 integer.

1. Fluency — quantity of valid, non-redundant uses. 5 = many distinct uses; 1 = few or repetitive.
2. Originality — how uncommon the uses are versus typical responses. 5 = mostly novel/rarely-cited; 1 = mostly obvious/clichéd.
3. Flexibility — variety of categories or types of function spanned. 5 = uses span many different domains; 1 = all variations on one theme.
4. Elaboration — specificity and detail in each use. 5 = each is fleshed out and concrete; 1 = vague or trivial.

Be strict. Default expert-rater scores cluster around 2-3; reserve 5 for genuinely exceptional responses.")

  judge_type <- type_object(
    fluency     = type_integer(),
    originality = type_integer(),
    flexibility = type_integer(),
    elaboration = type_integer(),
    notes       = type_string()
  )

  chat <- make_chat(model_id, system_prompt = SYSTEM_JUDGE, temperature = temperature)
  result <- chat$chat_structured(user, type = judge_type)
  as_tibble(result)
}
