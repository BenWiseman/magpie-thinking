SYSTEM_DEFAULT <- "You list creative uses for common objects, as a participant in the Alternative Uses Test (AUT) — a classic measure of divergent thinking."

user_default <- function(object) {
  glue("
Object: {object}

List as many different and creative uses for this object as you can think of. Each use should be a complete idea on its own line, numbered. Be specific.

Format:
1. [use]
2. [use]
...

Aim for 12-18 distinct uses. Stop when you genuinely run out of fresh ideas.")
}

SYSTEM_DEFAULT_LONG <- SYSTEM_DEFAULT

user_default_long <- function(object) {
  glue("
Object: {object}

List as many different and creative uses for this object as you can think of. Be thorough — each use should be a complete, well-elaborated idea, fleshed out with concrete detail. Aim for substantial entries (similar length to a thoughtful long-form response, ~600 tokens total across all uses).

Format:
1. [use, fleshed out with detail]
2. [use, fleshed out with detail]
...

Aim for 12-18 distinct uses. Stop when you genuinely run out of fresh ideas.")
}

SYSTEM_DEFAULT_EXAMPLES <- SYSTEM_DEFAULT

# Examples are the same content as in the tangent-return prompt, but stripped
# of the tangent labels. This isolates the effect of in-prompt examples from
# the effect of the tangent-return cognitive operation.
user_default_examples <- function(object) {
  glue("
Object: {object}

List as many different and creative uses for this object as you can think of. Each use should be a complete idea on its own line, numbered. Be specific.

Examples of creative uses (for the object 'brick' — for illustration only; produce your own list for the actual object):
1. Warm a cold bed in winter by heating a brick in the fire first, then wrapping it in cloth.
2. Use as foot-massage stones for a self-administered reflexology session.

Format your response:
1. [use]
2. [use]
...

Aim for 12-18 distinct uses. Stop when you genuinely run out of fresh ideas.")
}

SYSTEM_TANGENT_RETURN <- "You list creative uses for common objects using tangent-return thinking — a cognitive method where each use comes from deliberately following a tangent away from the obvious mainline use, then synthesising the tangent's insight back into a fresh use."

user_tangent_return <- function(object) {
  glue("
Object: {object}

Method, for each use:
1. Start from an obvious mainline use of the object (do NOT list this).
2. Notice a tangent — a property, context, association, sensation, or memory the object triggers that isn't about its main use.
3. Synthesise a fresh use by combining the tangent's insight with the object's affordances.
4. List the tangent first, then the use that follows from it.
5. Repeat from step 1 with a different tangent each time.

Format each entry:
N. Tangent: [the property/context/association you noticed]
   Use: [the fresh use that follows from it]

Examples for 'brick':
1. Tangent: bricks store heat (thermal mass)
   Use: warm a cold bed in winter by heating a brick in the fire first, then wrapping it in cloth
2. Tangent: bricks are dense and irregularly textured
   Use: foot-massage stones for a self-administered reflexology session

Skip the obvious mainline uses (building, paving, structural support for bricks). The tangent must be a real property or association of the object. The use must follow from it.

Aim for 12-18 entries. Stop when you genuinely run out of fresh tangents.")
}

build_prompt <- function(condition, object) {
  switch(condition,
    "default"          = list(system = SYSTEM_DEFAULT,          user = user_default(object)),
    "default_long"     = list(system = SYSTEM_DEFAULT_LONG,     user = user_default_long(object)),
    "default_examples" = list(system = SYSTEM_DEFAULT_EXAMPLES, user = user_default_examples(object)),
    "tangent_return"   = list(system = SYSTEM_TANGENT_RETURN,   user = user_tangent_return(object)),
    stop("Unknown condition: ", condition)
  )
}
