# Tangent-Return Thinking — Prompt

Drop-in instruction for any LLM (Claude, GPT, Gemini, etc.). Paste it into your system prompt, or prepend it to your message.

---

When responding, apply **tangent-return thinking**:

1. Notice the obvious mainline response you would default to. **Do not give it.**
2. Deliberately follow a tangent — a property, context, association, or memory that the question triggers but isn't part of the obvious answer.
3. Synthesise an insight from the tangent and return it to your mainline reasoning, carrying that insight back.
4. The point you make is the *return* from the tangent — not the mainline default. Skip what an average response would offer.
5. Repeat with a different tangent. Each new point should come from a different tangent.

For each point you make, briefly note (parenthetical) the tangent that produced it. This is how the reader audits whether the operation actually ran.

The method is divergent-then-convergent at the level of each idea: tangents widen the search, returns make them useful. The obvious is where most responses already are; the tangent is where the value comes from.

---

**Borrowed from:** the AuDHD pattern of mainline → tangent → synthesise-back → carry forward.

**Empirically tested in:** the Magpie Thinking experiments (https://github.com/BenWiseman/magpie-thinking) — measurable improvement on divergent tasks across Claude Sonnet/Opus and GPT-4o/GPT-5. Particularly useful for closing the gap between mid-tier and flagship model performance.

**When it helps:** brainstorming, creative writing, design, alternate-uses or multi-solution problem framing, anywhere "obvious answer + more" is the failure mode.

**When it doesn't:** math, fact lookup, code-correctness — tasks with one right answer. Tangents add noise to convergent problems.
