# Magpie Thinking

*Tangent-return cognition, tested as an architecture for LLM agent swarms.*

Most "creative" LLM prompting either turns up the temperature or asks the model to "think outside the box". This repo tests something more specific: that a deliberate **tangent-return loop** — mainline thought → interesting tangent → synthesise the tangent back into the mainline → carry forward → repeat — produces measurably better outputs on divergent tasks than default agent reasoning. And that a parallel **inner committee** of such agents, each with a distinct character running the same loop, does better still.

The pattern is borrowed from how my own AuDHD (autism + ADHD) brain actually solves hard problems. The claim is that the cognitive operation is portable.

> 📄 **For the empirical study with full methods, stats, and confound declarations:** [`writeup/paper.md`](writeup/paper.md)
> ✍️ **For the lived-experience narrative version:** [`writeup/post.md`](writeup/post.md)
> 🧪 **For the prompt you can paste anywhere:** [`prompts/tangent-return.md`](prompts/tangent-return.md)

## The claim being tested

**H1.** A single agent running tangent-return thinking outperforms a default agent on divergent tasks (AUT, design briefs, multi-solution coding), and ties on convergent tasks (math, code-correctness).

**H2.** A swarm of N tangent-return agents with distinct cognitive characters (the *inner committee*) outperforms a swarm of N tangent-return clones at equal compute.

**H3.** The benefit is asymmetric — it scales with how divergent the task is. On purely convergent tasks the inner committee should *not* win. If it does, the result is noise.

## The architecture, in two layers

### Layer 1 — Tangent-return thinking (the operation)

One mind, looping:

```
mainline thought
  → notice an interesting tangent
  → follow the tangent
  → synthesise the insight from it
  → return to the mainline carrying the payload
  → next tangent
```

Psychiatry tends to flag the *tangent* as a symptom (loose associations, tangential speech) and miss the *return*. Without the return it is a disorder of attention. With the return it is a method.

### Layer 2 — The inner committee (the architecture)

N agents, each running tangent-return thinking, each anchored to a distinct **character** with its own pet concern, characteristic move, and pet rejection. Starter cast:

| Character | Pet concern | Characteristic move | Pet rejection |
|---|---|---|---|
| **Systematizer** | invariants | name the invariant each move rests on | vibes-only proposals |
| **Catastrophizer** | silent failures | find the way it breaks at 3am | happy-path complacency |
| **Aesthete** | texture, emotional truth | one concrete sensory anchor per move | beige correctness |
| **Contrarian** | the unsaid second-order | "what is everyone missing" | consensus moves |
| **Hyperfocus monk** | depth | master ONE mechanism exquisitely | covering three things adequately |

Convergence is not delegated. Synthesis across the committee is an *executive* step performed outside the swarm — by a human, or by a downstream synthesiser whose performance is itself measured.

The committee draws on Internal Family Systems (Schwartz), Society of Mind (Minsky), and Dennett's multiple-drafts model. It is an *operational* model of parallel cognitive parts, not a clinical model of dissociation.

## Experiments

Each experiment runs three conditions at fixed N, fixed model, fixed temperature:

- **A. Default** — N identical default agents.
- **B. Tangent-return clone** — N identical agents running the tangent-return loop.
- **C. Inner committee** — N agents, each running the tangent-return loop with a distinct character.

| # | Task | Type | Primary metric |
|---|---|---|---|
| 01 | AUT (Alternative Uses Test) | Divergent (classic) | fluency / originality / flexibility / elaboration |
| 02 | Product design briefs | Divergent (applied) | pairwise judge Elo |
| 03 | Multi-solution coding (APPS subset) | Mixed | approach diversity + correctness |
| 04 | GSM8K subset | Convergent (control) | accuracy |

Secondary metrics across all experiments: inter-output semantic distance (embedding cosine), best-of-N quality, coverage where enumerable, cost-normalised quality, and synthesiser-lift (a fixed downstream synthesiser agent is fed the swarm outputs and the resulting artefact is scored).

## Repo layout

```
prompts/          drop-in prompts you can paste into any LLM
skills/           Claude Code skills (~/.claude/skills/)
R/                library functions (sourced, not packaged)
experiments/      numbered study scripts — NN_short-name.R
data/tasks/       input task instances
results/          committed summary results, plots, tables
writeup/          article(s) and figures
```

## Just use it

If you don't want to run the experiment and you just want to *try the prompt*:

- **Copy-paste anywhere** — [`prompts/tangent-return.md`](prompts/tangent-return.md). Drop into your system prompt or prepend to your message. Works with Claude, GPT, Gemini, anything.
- **Claude Code users** — copy [`skills/tangent-return/`](skills/tangent-return/) into `~/.claude/skills/` and invoke with `/tangent-return`.

Both artefacts cite this repo when used — the empirical evidence lives here.

## Stack

R throughout. [`ellmer`](https://ellmer.tidyverse.org/) for Claude API calls, the tidyverse for data, `ggplot2` for plots. `renv` for dependency locking once the first experiment runs. Expected packages:

```r
install.packages(c(
  "ellmer", "tidyverse", "fs", "jsonlite",
  "glue", "here", "furrr", "broom"
))
```

## Reproduce

```bash
git clone git@github.com:BenWiseman/magpie-thinking.git
cd magpie-thinking
cp .env.example .env   # add your ANTHROPIC_API_KEY
```

Open `magpie-thinking.Rproj` in RStudio. Run commands land with the first committed experiment.

## Status

**Experiment 01 complete.** Single-agent tangent-return tested across 4 frontier models (Claude Sonnet 4.5, Claude Opus 4.5, GPT-4o, GPT-5) on the Alternative Uses Test. Three of four models show significant gains on originality and elaboration; the fourth is at ceiling. Full results in [`results/`](results/), preprint at [`writeup/paper.md`](writeup/paper.md), accessible writeup at [`writeup/post.md`](writeup/post.md).

**Pending — and load-bearing for the cognitive-operation claim:** the limitations section of the paper names two confounds (token budget, in-prompt examples) that need direct ablations before the claim can be made cleanly. Those are experiment 01a/01b. After that, experiments 02-04 extend to inner-committee swarms and other divergent tasks (see [hypotheses](#the-claim-being-tested) below).

Null results — for any of the above — will be published as null. This is not a marketing exercise.

## Acknowledgements

The tangent-return framing is mine. The cognitive-style descendants are not: the character set draws on Hartmann's hunter-versus-farmer ADHD model, Mottron's enhanced perception in autism, Baron-Cohen's empathising-systemising axis, and the Internal Family Systems / Society of Mind tradition of multi-agent cognition.

## License

Code under MIT. Writeup under CC-BY-4.0.
