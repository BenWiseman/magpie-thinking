# Magpie Thinking

*Tangent-return cognition, tested as a concrete LLM prompting operation.*

Most "creative" LLM prompting either turns up the temperature or asks the model to "think outside the box". This repo tests something more specific: whether a deliberate **tangent-return loop** — mainline thought -> interesting tangent -> synthesise the tangent back into the mainline -> carry forward -> repeat — produces measurably different outputs on divergent tasks than default agent reasoning.

The pattern is borrowed from how my own AuDHD (autism + ADHD) brain actually solves hard problems. The claim is that the cognitive operation is portable.

> **Empirical study with methods, stats, and confounds:** [`writeup/paper.md`](writeup/paper.md)
> **Lived-experience narrative version:** [`writeup/post.md`](writeup/post.md)
> **Prompt you can paste anywhere:** [`prompts/tangent-return.md`](prompts/tangent-return.md)

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

### Current headline

The strongest current result is cost-normalised, not universal:

- On the original frontier-model AUT run, Sonnet 4.5 + tangent-return reached 95% of GPT-5 default composite quality at 15% of the generation cost.
- On the follow-up DeepSeek sweep, **DeepSeek V4 Pro + tangent-return scored 4.74 composite quality**, above GPT-5 default (4.62) and GPT-5 + tangent-return (4.67), at **$0.78 per 1k generations**. That is about **97x lower generation cost than GPT-5 default** and **170x lower than GPT-5 + tangent-return** in these runs.
- The DeepSeek result is model-dependent. V4 Pro benefits from tangent-return; V4 Flash is cheaper and strong without it; `deepseek-chat` and `deepseek-reasoner` currently returned the V4 Flash backend in this API window.

The same Claude Sonnet 4.5 judge and rubric were used for the original and DeepSeek scoring, so the comparison is not confounded by changing judges. Judge and embedding costs are excluded from the headline ratios because they are shared evaluation costs, not agent generation costs.

DeepSeek scoring completed for all 240 responses. Nineteen semantic-diversity values are missing because the parser extracted zero valid uses from those responses; the judge scores are complete.

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

Open `magpie-thinking.Rproj` in RStudio. The original frontier-model AUT run is in `experiments/01_aut.R`. The DeepSeek AUT generation and resumable postprocess pipeline are:

```bash
Rscript experiments/01_deepseek_aut.R --thinking=disabled
Rscript experiments/01_deepseek_postprocess.R \
  --runs=data/runs/<deepseek-run>.jsonl \
  --judge-model=claude-sonnet-4-5 \
  --judge-jobs=4
```

The postprocess step writes one judge-cache file per response and can resume after failures without re-scoring completed rows.

## Status

**Experiment 01 complete.** Single-agent tangent-return tested across 4 frontier models (Claude Sonnet 4.5, Claude Opus 4.5, GPT-4o, GPT-5) on the Alternative Uses Test. Three of four models show significant gains on originality and elaboration; the fourth is at ceiling. Confound checks show the defensible mechanism claim is narrower: tangent-return preserves semantic spread better than length-matched and examples-matched controls.

**DeepSeek follow-up complete.** The same AUT design was run across `deepseek-chat`, `deepseek-v4-flash`, `deepseek-reasoner`, and `deepseek-v4-pro`, then scored with the same Sonnet 4.5 judge. V4 Pro + tangent-return is the best absolute score in the repo so far; V4 Flash default is the cheap high-value option; tangent-return is not uniformly helpful across all DeepSeek routes.

**Next:** experiments 02-04 extend to inner-committee swarms and other divergent tasks (see [hypotheses](#the-claim-being-tested) above). Human-rater validation remains the main unresolved validation step.

Null results — for any of the above — will be published as null. This is not a marketing exercise.

## Acknowledgements

The tangent-return framing is mine. The cognitive-style descendants are not: the character set draws on Hartmann's hunter-versus-farmer ADHD model, Mottron's enhanced perception in autism, Baron-Cohen's empathising-systemising axis, and the Internal Family Systems / Society of Mind tradition of multi-agent cognition.

## License

Code under MIT. Writeup under CC-BY-4.0.
