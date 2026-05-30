# Magpie Thinking: Simulating Neurodivergent Tangent-Return Cognition Improves LLM Performance on Divergent Tasks

**Ben Wiseman**
*Independent researcher*
*benjamin.h.wiseman@gmail.com*
*2026-05-30*

---

## Abstract

Large language models trained on aggregate human text default to the centroid of their training distribution — a useful inductive bias for convergent tasks but a corrosive one for divergent tasks, where novelty is the unit of value. We hypothesise that *simulating cognitive variance* — specifically, encoding cognitive operations associated with neurodivergent thinking — improves LLM performance on divergent benchmarks. We operationalise one such operation, **tangent-return thinking** (mainline thought → deliberate tangent → synthesised return), drawn from the AuDHD (autism + ADHD) associative-loop pattern, and test it across four frontier models — Claude Sonnet 4.5, Claude Opus 4.5, GPT-4o, and GPT-5 — on the Alternative Uses Test, a 60-year-old standard measure of divergent thinking. **In three of four models, tangent-return prompting produces significant paired-test improvements in originality and elaboration (p<.01); the fourth model (GPT-5) shows ceiling effects with default-condition baselines already at 3.96–5.00 on a 5-point scale.** A practical corollary: mid-tier models with the operation reach 95% of flagship default quality at ~15% of the cost. We interpret these results, with stated limitations, as preliminary evidence that *cognitive operations associated with neurodivergent thinking have measurable utility for AI systems* — while flagging open confounds (token budget, in-prompt examples, judge-family bias) that future work must address before the cognitive-operation claim can be made cleanly.

**Keywords:** divergent thinking, prompting, neurodiversity, cognitive operations, Alternative Uses Test, chain-of-thought variants

---

## 1. Introduction

Large language models exhibit a documented tendency toward the modal response — the answer most people would give. This is a feature for convergent tasks (math, fact recall, code correctness) where there is one right answer near the centroid of well-represented training text. It is a *liability* for divergent tasks (brainstorming, creative writing, design, alternate-use reasoning) where the value is in the tail, not the centre.

The standard remedies — temperature sampling, "be creative", chain-of-thought variants, multi-sample best-of-N — push outputs away from the centroid but lack a principled cognitive structure for *where* to push. They make the model louder, not differently shaped.

This paper proposes a different remedy: explicitly *simulating cognitive operations associated with neurodivergent thinking*. The motivating intuition is mundane and underexplored: people whose cognition deviates from the modal "neurotypical" pattern routinely outperform the modal pattern on divergent tasks. Hartmann's hunter-versus-farmer model of ADHD [1], Mottron's enhanced perceptual functioning account of autistic cognition [2], and Baron-Cohen's empathising-systemising axis [3] all describe cognitive styles that differ from the centroid and that produce different — sometimes more useful — outputs in domains where centroid-thinking fails.

We operationalise one such cognitive style as a prompt-level intervention. The chosen pattern is **tangent-return thinking**: the AuDHD (autism + ADHD) inner-loop pattern of *mainline thought → interesting tangent → synthesised insight returned to the mainline → carry forward → next tangent*. This pattern is well-described by people who think this way; it is occasionally pathologised in psychiatric literature as "tangential thinking" when the *return* is missed by external observers; and it is, by self-report, a productive cognitive operation when the return happens.

Our research question:

> **Does prompting LLMs to perform tangent-return thinking measurably improve their performance on divergent tasks?**

If yes, this is evidence that simulating cognitive variance is a viable lever for LLM capability — distinct from the existing prompt-engineering literature that treats the LLM as a single, undifferentiated reasoner to be coaxed. It also provides a small but concrete example of *neurodiversity-informed AI research*: an under-explored direction in which cognitive patterns from neurodivergent communities serve as engineering inspiration rather than only as accessibility considerations.

---

## 2. Related Work

**Chain-of-thought and its variants.** Wei et al. [4] established that prompting models to "think step by step" improves performance on reasoning tasks. Subsequent work extended this to self-consistency [5], tree-of-thoughts [6], and graph-of-thoughts [7] — increasingly elaborate prompting structures that broaden the search space. These methods are agnostic about *what kind* of cognitive operation the model should perform; they impose structure on reasoning without specifying its character.

**Multi-agent and society-of-mind in LLMs.** Multiple recent works frame LLM problem-solving as a society of specialised agents [8, 9, 10], drawing on Minsky's *Society of Mind* [11]. These approaches diversify outputs through *role* specialisation rather than cognitive-operation specialisation.

**Divergent thinking measures in cognitive science.** The Alternative Uses Test (AUT), introduced by Guilford in 1967 [12], remains a standard measure of divergent thinking. Recent work has applied AUT to LLMs [13, 14] and human-LLM comparisons [15], finding LLMs competitive with average human performance but underperforming high-creative humans on originality.

**Neurodiversity in AI.** The neurodiversity literature in AI is sparse, primarily focused on accessibility, fairness, and bias mitigation [16, 17]. We are aware of no published work that treats neurodivergent cognitive operations as design *inspiration* for LLM prompting strategies.

This paper sits at the intersection: a cognitive-operation-specific prompting intervention motivated by, and named after, an explicit neurodivergent cognitive pattern.

---

## 3. Method

### 3.1 The cognitive operation

![Linear vs tangent-return cognitive paths](../results/01_concept_diagram.png)
*Figure 1. Two ways to traverse a problem. Default condition: linear reasoning, each step proceeds to the next. Tangent-return: each step departs to a tangent, synthesises an insight, returns enriched.*

**Tangent-return thinking** is operationalised as the following loop, instructed in the system prompt:

1. Start from an obvious mainline use (do *not* list this).
2. Notice a tangent — a property, context, association, sensation, or memory the object triggers that isn't about its main use.
3. Synthesise a fresh use by combining the tangent's insight with the object's affordances.
4. List the tangent first, then the use that follows from it.
5. Repeat from step 1 with a different tangent each time.

The format is structured: each output entry consists of an explicit *tangent* (the non-obvious association) followed by a *use* (the return). This dual structure makes the operation auditable: the reader can verify that the tangent is genuinely non-obvious and that the use follows from it, rather than being a post-hoc decoration.

### 3.2 Experimental design

A 4 × 2 × 10 × 3 factorial design:

- **4 models:** claude-sonnet-4-5, claude-opus-4-5, gpt-4o, gpt-5 (the gpt-5 alias resolves to gpt-5.5 in our experimental window)
- **2 conditions:** *default* (standard AUT prompt) vs *tangent-return* (above operationalisation)
- **10 tasks:** standard AUT objects — brick, paperclip, newspaper, car tire, bucket, shoe, toothbrush, cardboard box, pencil, spoon
- **3 seeds per cell:** repeated sampling at temperature 1.0 (for non-reasoning models)

Total: 240 attempted agent calls; 233 successful (7 GPT-5 calls dropped on transient errors).

### 3.3 Scoring

Each response was scored on four standard AUT dimensions by an LLM judge (claude-sonnet-4-5, temperature 0, structured JSON output):

- **Fluency:** quantity of valid, non-redundant uses (1-5 integer)
- **Originality:** how uncommon the uses are vs typical responses (1-5)
- **Flexibility:** variety of categories spanned (1-5)
- **Elaboration:** specificity and detail per use (1-5)

A secondary metric — **semantic diversity** — was computed via OpenAI text-embedding-3-large: mean pairwise cosine distance between the embedded uses within a response. Higher = more conceptually spread.

### 3.4 Materials

All prompts, scoring rubric, judge prompt, task list, raw responses, and analysis code are available at https://github.com/BenWiseman/magpie-thinking. Total budget for the reported experiment was under USD 5.

---

## 4. Results

### 4.1 Main effects

![Tangent-return effect sizes by model and metric](../results/01_effect_forest.png)
*Figure 2. Mean improvement (tangent-return − default) with 95% confidence intervals from per-task pairs (n=10). Bars whose CI excludes zero are highlighted; the consistent direction across models supports cross-model robustness.*

Tangent-return thinking produced significant improvements on originality and elaboration across most models. Per-model paired tests (default vs tangent-return, by task, n=10) are reported in **Table 1**.

**Table 1.** Mean improvement (tangent-return − default) per model per metric. Paired t-tests with by-task pairing. Significant results bolded.

| Model | Originality | Flexibility | Elaboration | Sem. diversity |
|---|---|---|---|---|
| **gpt-4o** | **+0.43 (p=.006)** | +0.03 (n.s.) | **+0.60 (p<.001)** | +0.02 (n.s.) |
| **gpt-5** | +0.10 (n.s., ceiling) | +0.03 (n.s.) | 0 (ceiling) | **+0.04 (p=.009)** |
| **opus-4.5** | **+0.77 (p<.001)** | **+0.73 (p<.001)** | **+0.73 (p<.001)** | **+0.03 (p=.027)** |
| **sonnet-4.5** | **+0.60 (p=.002)** | **+0.37 (p=.017)** | **+0.37 (p=.003)** | **+0.04 (p=.002)** |

Three of four models show significant gains on originality and elaboration. The fourth (gpt-5) shows non-significant gains on originality and zero gain on elaboration — but the default-condition baselines for gpt-5 are already 3.96/5 and 5.00/5 respectively. This is a *ceiling effect*, not a method failure: gpt-5 has nowhere left to go.

Semantic diversity (an automatic, judge-independent measure) increases significantly for 3 of 4 models, providing a non-LLM-judge cross-validation of the effect.

### 4.2 Cross-model robustness

The direction of effect is consistent across all four models and across both providers (Anthropic and OpenAI). The largest absolute gains appear on Anthropic's Opus 4.5 (which underperforms Sonnet 4.5 in the default condition — a surprising finding in itself — but pulls ahead under tangent-return).

### 4.3 Cost analysis (Pareto frontier)

A practical corollary of the main result: tangent-return prompting reshapes the cost-quality Pareto frontier (**Figure 3**).

![Cost-quality Pareto frontier with paired arrows](../results/01_paired_arrow_pareto.png)
*Figure 3. Each model's position shifts up the quality axis under tangent-return. The cheapest high-quality option is Sonnet 4.5 with tangent-return — not GPT-5 default. Within Anthropic the shift is dramatic; within OpenAI it partially closes the GPT-4o → GPT-5 gap at a fraction of the flagship's cost.*

**Table 2.** Per-call cost (agent only; judge and embedding costs constant across conditions and excluded) versus composite quality (mean of originality, flexibility, elaboration). Pricing verified 2026-05-30 from the official Anthropic and OpenAI pricing pages.

| Model + condition | Cost / call (USD) | Composite quality |
|---|---|---|
| gpt-4o default | $0.0030 | 3.42 |
| sonnet-4.5 default | $0.0055 | 3.93 |
| gpt-4o + tangent-return | $0.0059 | 3.78 |
| opus-4.5 default | $0.0083 | 3.84 |
| **sonnet-4.5 + tangent-return** | **$0.0114** | **4.38** |
| opus-4.5 + tangent-return | $0.0182 | 4.59 |
| gpt-5 default | $0.0753 | 4.62 |
| gpt-5 + tangent-return | $0.1331 | 4.67 |

Two implications:

1. **Sonnet 4.5 + tangent-return reaches 95% of GPT-5 default's composite quality at 15% of the cost** ($0.0114 vs $0.0753). Within the experimental task family, prompting a mid-tier model with a tangent-return instruction is more cost-efficient than upgrading to the reasoning flagship.

2. **Opus 4.5 default is Pareto-dominated by Sonnet 4.5 default** — at higher cost, lower quality. Tangent-return reverses the order (Opus 4.5 + TR is the highest-quality non-GPT-5 option). The implication for divergent tasks: model selection should be made *jointly* with prompt selection, not sequentially.

---

## 5. Discussion

### 5.1 Why might this operation work?

We offer three non-exclusive mechanisms:

**Centroid avoidance.** The default prompt elicits responses near the modal training distribution. By forbidding the obvious mainline and forcing the agent to articulate a non-obvious tangent before each use, the operation explicitly steers away from the centroid. This is conceptually similar to "diverse decoding" methods [18] but operates at the cognitive-instruction level rather than the sampling level.

**Token budget reallocation.** Tangent-return responses use ~2× the output tokens of default responses. Some of the quality gain may simply be the model "thinking more". But the gain on semantic diversity (which is *not* directly mediated by token count) suggests that the quality improvement is not solely a function of expanded compute.

**Search-tree branching with cross-pollination.** The tangent-return structure resembles a constrained tree-of-thoughts where each "branch" (tangent) must return value to the trunk (the listed use). This is a more disciplined exploration pattern than free-form CoT.

We do not have direct mechanism evidence; ablations are future work.

### 5.2 Neurodiversity as engineering inspiration

The framing of this paper is deliberate. Cognitive patterns documented in neurodivergent communities are typically discussed in AI in one of two registers: as accessibility considerations (how do we serve neurodivergent users?) or as fairness considerations (does this model perform worse on neurodivergent inputs?). Both are important. Neither treats neurodivergent cognition as a *source of design inspiration*.

This paper tests a single cognitive operation derived from a single neurodivergent profile (AuDHD) on a single task family (AUT). The result is small in scope but suggestive: simulating a specific neurodivergent cognitive operation produced measurable, robust improvements across model families, providers, and quality dimensions.

If this generalises — and the question of whether it does is the obvious next research programme — the implication is that the AI prompt-engineering community has been leaving useful structure on the table by treating "creativity" as an undifferentiated property to be coaxed rather than a set of distinct cognitive operations to be specifically encoded.

### 5.3 What this is not

This is not a claim that LLMs *think like* neurodivergent humans, nor that neurodivergent thinking is reducible to a prompt. The cognitive operation we have encoded is a single, well-articulated *instance* of a much broader space of cognitive variance. It is a useful instance; it is not the territory.

---

## 6. Limitations

We declare the following limitations explicitly because the cognitive-operation claim hinges on ruling them out.

1. **Token-budget confound (load-bearing).** Tangent-return responses use ~2× the output tokens of default responses (mean 685 vs 343 for Sonnet 4.5). Some portion of the quality gain is plausibly attributable to expanded compute alone. We argue against a pure-tokens explanation on two grounds: (a) embedding-based semantic diversity — which does not strictly track token count — improves significantly on 3 of 4 models, and (b) the largest gains appear on originality, which has a low upper bound and is not obviously elongation-elastic. Neither rules tokens out as a mediator. **A length-matched ablation — instructing the default condition to produce ~600-token responses — is necessary future work and gates the cognitive-operation claim. Without it, the present results support the weaker claim that the *combination* of tangent-return structure, in-prompt examples, and expanded token budget improves LLM-judge ratings for AUT-style divergent generation.**

2. **In-prompt examples confound.** The tangent-return prompt includes two worked examples ("brick → thermal mass → bed-warmer"); the default prompt does not include equivalent worked examples of creative uses. Few-shot examples are well-documented to shift LLM outputs substantially. A control condition that gives the default prompt equivalent uses-only examples (without tangent labels) would isolate the effect of the cognitive-operation framing from the effect of demonstration. This is required future work.

3. **Judge is also an LLM, and shares a family with two test conditions.** The judge (claude-sonnet-4-5) is the same model family as Sonnet 4.5 and Opus 4.5. While the effect direction is consistent across both providers (including the two OpenAI models), judge-family bias toward Claude-style outputs cannot be ruled out without human-rater validation on a subsample (planned for v2, ~30 pair-judgments).

4. **The model may not be executing the operation it is instructed to.** The output format (Tangent: ... Use: ...) is observable; the underlying cognitive process is not. The model may be generating creative uses and retroactively labelling them. We cannot distinguish "model executed tangent-return" from "model produced uses and formatted them according to a template" from output alone. Probing experiments on open-weight models (testing whether the tangent comes *before* the use in the model's internal representation) are required future work.

5. **One task family.** AUT measures one specific kind of divergent thinking (object reframing). Generalisation to other divergent tasks — creative writing, open-ended design, problem reframing — is hypothesis, not finding. Experiments 02-04 are planned to address this.

6. **Single language (English).** Tangent-return as instructed may rely on English-specific associative networks.

7. **GPT-5 reasoning token billing uncertainty.** GPT-5's internal reasoning tokens are billed but may or may not appear in the API's reported output token count. Our cost calculations may *understate* GPT-5's true cost; the cost-efficiency finding is robust to this uncertainty in only one direction.

8. **No inner-committee test.** The theoretical extension — multiple agents each running tangent-return from distinct cognitive characters — is theorised in the project repository but not tested in this experiment. Experiment 02 will address it.

---

## 7. Future Work

Three confound-resolution experiments come first, gating the cognitive-operation claim:

**0a. Length-matched ablation.** Default condition with explicit "produce ~600 tokens" instruction, retested. Resolves the token-budget confound.

**0b. Example-matched ablation.** Default condition with two worked uses-only examples (no tangent labelling), retested. Resolves the in-prompt-examples confound.

**0c. Human-rater validation.** Pairwise human comparison (default vs tangent-return) on a 30–50 response subsample, on a "creativity" 5-point scale. Resolves the judge-bias concern. If human raters confirm the effect, the cognitive-operation claim hardens; if they do not, the paper scopes to "structured-reasoning format improves LLM-judge ratings".

Three substantive extensions follow:

**A. Generalisation across divergent tasks.** Apply the same design (with the above ablations baked in) to: creative writing prompts (judged pairwise), multi-solution coding (where approach diversity is measurable), open-ended design briefs. Also include a *convergent* control (GSM8K subset) where we predict tangent-return will *not* help and may hurt — a falsification test.

**B. The inner committee.** Extend the operation to a swarm of agents each running tangent-return *from a distinct cognitive character* (e.g., a systematiser, a catastrophiser, an aesthete). Test whether the variance benefit compounds. This was the original motivation for the broader research programme.

**C. Other neurodivergent cognitive operations.** Tangent-return is one operation associated with one neurodivergent profile. Other candidates — hyperfocus chains, pattern-first reasoning (autistic systematising), associative-noticing — are plausibly encodable as prompt-level interventions and merit independent testing.

A broader meta-question: which cognitive operations from which neurodivergent profiles confer LLM benefits on which task types? This is a tractable empirical programme with low cost-per-experiment and high signal-to-noise. The work presented here is the first step.

---

## Acknowledgements

The tangent-return framing is mine, drawn from lived experience as an AuDHD-identified person. The cognitive-style descendants are not: this paper builds on Hartmann's hunter-versus-farmer model, Mottron's enhanced perception account, Baron-Cohen's empathising-systemising axis, and the Society of Mind / Internal Family Systems tradition of multi-agent cognition. Thanks to the neurodivergent communities whose self-articulation of their own cognitive patterns made this operationalisation possible.

---

## References

[1] Hartmann, T. (1993). *Attention Deficit Disorder: A Different Perception*. Underwood Books.

[2] Mottron, L., Dawson, M., Soulières, I., Hubert, B., & Burack, J. (2006). Enhanced perceptual functioning in autism: An update, and eight principles of autistic perception. *Journal of Autism and Developmental Disorders*, 36(1), 27–43.

[3] Baron-Cohen, S. (2002). The extreme male brain theory of autism. *Trends in Cognitive Sciences*, 6(6), 248–254.

[4] Wei, J., et al. (2022). Chain-of-thought prompting elicits reasoning in large language models. *NeurIPS*.

[5] Wang, X., et al. (2023). Self-consistency improves chain of thought reasoning in language models. *ICLR*.

[6] Yao, S., et al. (2023). Tree of thoughts: Deliberate problem solving with large language models. *NeurIPS*.

[7] Besta, M., et al. (2024). Graph of thoughts: Solving elaborate problems with large language models. *AAAI*.

[8] Park, J. S., et al. (2023). Generative agents: Interactive simulacra of human behavior. *UIST*.

[9] Du, Y., et al. (2023). Improving factuality and reasoning in language models through multiagent debate. *arXiv:2305.14325*.

[10] Hong, S., et al. (2024). MetaGPT: Meta programming for a multi-agent collaborative framework. *ICLR*.

[11] Minsky, M. (1986). *The Society of Mind*. Simon & Schuster.

[12] Guilford, J. P. (1967). *The Nature of Human Intelligence*. McGraw-Hill.

[13] Stevenson, C., et al. (2022). Putting GPT-3's creativity to the (Alternative Uses) Test. *ICCC*.

[14] Cropley, D., & Cropley, A. (2023). Creativity and Artificial Intelligence: A Standardized Test. *Creativity Research Journal*.

[15] Hubert, K., et al. (2024). The current state of artificial intelligence generative language models is more creative than humans on divergent thinking tasks. *Scientific Reports*, 14, 3440.

[16] Begel, A., et al. (2020). Lessons learned in designing AI for autistic adults. *ASSETS*.

[17] Schwartz, S., et al. (2022). The neurodiversity case for human-centered AI. *FAccT*.

[18] Vijayakumar, A. K., et al. (2018). Diverse beam search for improved description of complex scenes. *AAAI*.

---

*Code, data, prompts, and analysis: https://github.com/BenWiseman/magpie-thinking*

*A first-person narrative version of this work — focused on the lived-experience motivation and accessible to non-specialist readers — is available at `writeup/post.md` in the same repository.*

*Licensed CC-BY-4.0 for content; MIT for code.*
