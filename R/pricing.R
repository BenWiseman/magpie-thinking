# API pricing (USD per 1M tokens) — verified 2026-05-30 from official sources
# Sources:
#   Anthropic: https://platform.claude.com/docs/en/docs/about-claude/pricing
#   OpenAI:    https://developers.openai.com/api/docs/pricing
#
# Note: gpt-5 alias resolves to gpt-5.5 (current latest snapshot).
# Note: gpt-5 reasoning models bill internal reasoning tokens as output —
#       our captured tokens_out may UNDERSTATE actual cost.

PRICING <- list(
  "claude-sonnet-4-5" = list(input = 3.00,  output = 15.00),
  "claude-sonnet-4-6" = list(input = 3.00,  output = 15.00),
  "claude-opus-4-5"   = list(input = 5.00,  output = 25.00),
  "claude-opus-4-6"   = list(input = 5.00,  output = 25.00),
  "claude-opus-4-7"   = list(input = 5.00,  output = 25.00),
  "gpt-4o"            = list(input = 2.50,  output = 10.00),
  "gpt-5"             = list(input = 5.00,  output = 30.00),
  "text-embedding-3-large" = list(input = 0.13, output = 0.13)
)

cost_per_call <- function(model_id, tokens_in, tokens_out) {
  p <- PRICING[[model_id]]
  if (is.null(p)) {
    warning("No pricing for ", model_id, "; returning NA")
    return(NA_real_)
  }
  (tokens_in * p$input + tokens_out * p$output) / 1e6
}
