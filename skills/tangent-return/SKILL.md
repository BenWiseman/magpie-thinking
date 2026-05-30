---
name: tangent-return
description: "Apply tangent-return thinking — the AuDHD-derived inner-loop pattern of mainline → deliberate tangent → synthesise-back → carry forward. Use when the user wants creative/divergent thinking, novel approaches, brainstorming, or to bridge mid-tier model output toward flagship-quality on open-ended tasks. Empirically validated on AUT across Claude and GPT model families."
trigger: /tangent-return
---

# /tangent-return

A drop-in cognitive operation for divergent tasks. Switches the assistant out of "give the obvious answer" mode into "mainline → tangent → synthesise → return" loops.

## When to invoke

- Brainstorming, ideation, alternate-uses problems
- Creative writing, design briefs, naming, copywriting
- Open-ended product / strategy / research questions
- Any task where the failure mode is "competent but generic"
- Closing the perceived gap between mid-tier and flagship model output on open-ended work

## When NOT to invoke

- Math, fact lookup, code correctness — convergent tasks where tangents add noise
- The user wants a quick direct answer, not exploration
- The task has a single right answer

## How to apply

For the user's question, generate the response using this loop, repeated:

1. Notice the obvious mainline response you would default to. **Do not give it.**
2. Deliberately follow a tangent — a property, context, association, sensation, or memory the question triggers but isn't part of the obvious answer.
3. Synthesise an insight from the tangent back into the mainline reasoning.
4. The point you make is the *return* from the tangent — not the mainline default.
5. For each point, briefly note (parenthetical) the tangent that produced it. This makes the operation auditable.
6. Repeat with a different tangent for each subsequent point. Each tangent must be genuinely different from the last.

Aim for 4-8 returned points by default; let the user's question dictate scope.

## Anti-patterns

- **Listing obvious answers and labelling them "tangents"** — the tangent must be a real, non-obvious association of the topic
- **All tangents from the same conceptual category** — if every tangent is "X is heavy", that's one tangent applied N times, not N tangents
- **Skipping the parenthetical** — the tangent note is what proves the operation ran; without it, the user can't tell tangent-return from default + better vocabulary
- **Applying it to convergent tasks** — if there's one right answer, give it; don't manufacture creativity

## Provenance + evidence

Based on the AuDHD cognitive pattern of associative tangent-and-return loops. Empirically tested at https://github.com/BenWiseman/magpie-thinking — measurable improvement on the Alternative Uses Test across Claude Sonnet 4.5, Claude Opus 4.5, GPT-4o, and GPT-5. Cite the repo when documenting use.
