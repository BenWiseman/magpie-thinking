# What my AuDHD brain accidentally taught an AI

*On testing a hunch that cognitive patterns labelled "inefficient" might actually be doing something useful.*

---

![Linear vs tangent-return cognitive paths](../results/01_concept_diagram.png)

A few years into my last job, my managers started running workshops to figure out how I came up with ideas.

I wasn't doing anything special — at least it didn't feel that way to me. They'd present a problem, the room would work through it, and sometimes — not always — I'd say something that shifted the frame. Not the final answer, often; just an angle nobody else had noticed. Often something that, written down, looked obvious in retrospect. They wanted me to teach the team how I did it.

I'm not a great teacher of this particular thing. The honest version of my answer was: I wasn't *trying* to find the answer. I was thinking about something else and the connection landed.

That's roughly the moment I started understanding that my AuDHD brain — autism plus ADHD, two neurodivergent profiles that frequently co-occur — was doing something specific that other people weren't, and that it was visible from the outside as "where do these ideas come from?"

Years later I've decided to try and bottle it. Not for me — for AI.

This post is about what happened when I prompted four large language models to think the way my brain thinks, and tested whether it measurably improved their outputs.

The short answer: yes. Across three of the four models, with statistically significant improvements on the standard measure of divergent thinking, with the fourth (the most expensive reasoning model) already at ceiling. The code, data, and analysis are public at https://github.com/BenWiseman/magpie-thinking.

The longer answer is in the rest of this post, because I think *why* it works is more interesting than *that* it works.

---

## The pattern, in plain terms

Here's what's happening in my head when I'm thinking about a problem.

There's a mainline thought — the problem itself. I'm holding it. But almost immediately, the topic triggers a tangent. Something the problem reminds me of. Not a related thought; an associated one. A property, a memory, a piece of a song lyric, a thing I read about ant colonies in 2014, the way light fell in a particular room.

The tangent is loud. It demands a few seconds of attention. I follow it — briefly, voluntarily.

And then — this is the part I think matters — the tangent comes back. I extract whatever insight it had and bring it home to the mainline, carrying that insight with me. The mainline is now slightly different. I'm thinking about the same problem, but with a new ingredient.

Then another tangent. Then another. Mainline → tangent → synthesise → return. Loop.

If you read about ADHD in older clinical literature, this gets labelled "tangential thinking" — and treated as a deficit. The clinical observer sees the tangent and assumes the train of thought has derailed. But from inside, the *return* is the productive move. It's what makes the tangents worth taking. Without the return it would just be distraction. With the return it's something else.

I think of it as graph traversal, not linear reasoning. A chain of thought is a chain — A leads to B leads to C, single track. What my brain does looks more like a graph: there's a trunk, but every node spawns branches that return to update the trunk before the next step. The shape is a tree that keeps folding back into itself.

This is also what most AuDHD people I know describe when they describe how they think, with their own metaphors. I'm calling it *tangent-return thinking*. The word for the bird that collects shiny things from everywhere and brings them back to the nest is *magpie*, which is what I called the project.

---

## What it costs

I don't want to write the "neurodiversity superpower" version of this post. That version is glib and it's not how the experience feels. The pattern has real costs.

I'm tired most evenings. Holding mainlines while following tangents takes cognitive load — more than I'd otherwise spend, I think, though I have nothing to compare it to. Conversations with neurotypical people are often a friction surface: they're following a single thread, I'm following six, and the part I say out loud sometimes lands as a non-sequitur. Sometimes it lands as the thing they actually needed to hear; sometimes it lands as a non-sequitur and the moment passes and I have to look interested in the original thread again. It's a guess each time.

The constant synthesis is hard to switch off. I sleep badly. I get overstimulated. Crowded rooms are expensive. There are real reasons that "ADHD" and "autism" are clinical labels — they describe patterns that, in some environments, are genuinely costly to run.

But here's the thing the clinical framing tends to miss: the same machinery that costs me in the wrong environments produces real outputs in the right ones. Workshops to extract my process were happening because the *outputs* were valued. The pattern wasn't a deficit being graciously accommodated; it was a productive operation that the rest of the team wanted to learn from. That's a meaningful distinction. It changes whether the pattern is something to be fixed or something to be understood.

I'm interested in the understanding side.

---

## The hunch

Large language models are trained on aggregate text from humans. They tend, by default, toward the modal response — the answer most people would give. That's a useful inductive bias for problems with one right answer. It's a corrosive bias for problems where the value is in the tail.

The standard prompting tricks for creative tasks are basically louder versions of "be creative": turn up temperature, ask for many ideas, run best-of-N. These all push outputs away from the centre but they don't say *where* to push, or *how*. They make the model noisier, not differently shaped.

What if you could give a model a *specific cognitive operation* that came from outside its training distribution? What if you could prompt it to think in a way that's well-articulated by people who actually think that way?

In other words: what if you simulated a small piece of neurodivergent cognition and asked the model to use it?

This was my hunch. I wrote it down on a Friday evening — Saturday, technically, by the time the file existed — and decided to treat it as an honest test. The way Karl Popper would have run it: not "let's see if I can prove this works", but "let's set up an experiment that *could* embarrass me, and see what happens."

---

## The experiment

I tested four frontier large language models:

- **Claude Sonnet 4.5** (Anthropic, mid-tier)
- **Claude Opus 4.5** (Anthropic, flagship)
- **GPT-4o** (OpenAI, mid-tier)
- **GPT-5** (OpenAI, flagship reasoning model)

Two conditions per model: a *default* prompt asking for creative uses of an everyday object, and a *tangent-return* prompt that operationalises the loop I described above — start from the obvious mainline, deliberately follow a tangent, synthesise the tangent back, list the use that follows, repeat.

I used the Alternative Uses Test — a 60-year-old psychology measure of divergent thinking. Pick an object (a brick, a paperclip, a newspaper, a shoe) and list creative uses. Performance is scored on fluency (how many), originality (how uncommon), flexibility (how varied), and elaboration (how specific). I used ten standard objects, three repeated samples per object per condition, scored by an independent LLM judge using a structured rubric, with embedding-based cross-validation.

The whole experiment cost under five dollars and took about 75 minutes. The code, data, analysis, and the actual prompt you can copy and paste into your own chats are at the GitHub link above.

---

## What landed

The hypothesis did not get falsified.

Across all four models, on the dimensions where tangent-return could move the needle, it did.

**Originality** improved significantly on three of four models. On Anthropic's Opus 4.5 the gain was +0.77 on a 5-point scale (p<.001). On Sonnet 4.5 it was +0.60 (p=.002). On GPT-4o, +0.43 (p=.006). GPT-5 was the only model with no significant improvement on originality — but its default-condition baseline was already 3.96 out of 5. It had nowhere to go. (GPT-5 is a reasoning model whose architecture probably does something tangent-like internally already.)

**Flexibility** and **elaboration** improved on Opus 4.5 and Sonnet 4.5 with p<.001 on at least one of the two. GPT-4o improved significantly on elaboration. GPT-5 sat at ceiling.

**Semantic diversity** — an embedding-based measure that doesn't go through the LLM judge — improved significantly on three of four models, providing a non-judge check on the finding.

In plain English: the prompt that asks the model to think the way my brain thinks produced measurably better creative outputs on a classic creativity benchmark, across four different frontier models from two providers.

![Per-model effects of tangent-return prompting](../results/01_aut_scorecards.png)

Here's what it looks like on a single object (a brick), same model, same seed — just a different prompt:

![Default vs tangent-return responses on a brick](../results/01_aut_sidebyside.png)

But "measurably better" can fail in two obvious ways that would falsify the cognitive-operation framing:

1. **The model just talked more.** Tangent-return responses use about twice as many output tokens as default ones. Maybe the quality gain is just "thinking out loud for longer."
2. **The examples did all the work.** The tangent-return prompt shows worked examples; the default prompt doesn't. Maybe the model would be just as good if you gave it equivalent examples without the tangent-return structure.

So I ran two more ablations to test these alternative explanations directly — a *length-matched* default (told to produce ~600 tokens like the tangent-return condition) and an *examples-matched* default (given the same example uses, just without the tangent labels).

Here's what the ablations actually showed — and it was more interesting than I expected.

**Examples alone did almost nothing.** Default-plus-examples scored barely above default. The worked examples I included in the tangent-return prompt are not what's doing the lifting.

**Length alone did something subtle and revealing.** When I told the default prompt to produce ~600 tokens (matching tangent-return's typical output length), the judge-rated scores for "elaboration" actually went *up* — sometimes higher than tangent-return itself. So if you only looked at the judge scores, you'd conclude "the model just needed to talk more." But:

**The judge-independent measure of semantic diversity inverted.** When the default prompt was forced to produce extra tokens, the resulting responses became *less* conceptually diverse, not more. The model used the extra tokens to elaborate further on the same conceptual themes — the same neighbourhood, deeper exploration. Tangent-return was the only condition that maintained both extended length *and* high semantic diversity. Across all three models. With p<.001.

That is, in plain terms, exactly what tangent-return is *for*: every tangent forces the next thought to depart from the previous neighbourhood. It's a structural discipline that prevents response collapse. The judge scores partially obscure this because LLM judges tend to reward verbosity per individual answer — a documented bias — but the embedding-based diversity measure cuts through it and shows the operation's signature clearly.

So the headline lands as something more specific than I started with: **tangent-return prompting's distinctive contribution is preserving conceptual spread across a response**. It's not just "thinking more"; it's *thinking in more places*. That's a different claim, and it's the one the data supports.

This was an honest falsification attempt — I genuinely expected at least one of the controls to close the gap. The pattern that emerged sharpened the cognitive-operation claim rather than refuting it: not "neurodivergent thinking makes the model better at everything", but "this specific neurodivergent operation does this specific thing that other plausible explanations don't reproduce." That's the shape of a useful finding.

![Tangent-return shifts every model's cost-quality position](../results/01_paired_arrow_pareto.png)

---

## The kicker

There's a practical corollary that I didn't expect.

GPT-5 won the default-condition comparison cleanly. With no creative prompting beyond "list uses", GPT-5 produced the highest-quality outputs by a meaningful margin.

But GPT-5 is **expensive**. At current pricing, a single AUT response from GPT-5 costs around $0.075. A response from Claude Sonnet 4.5 costs around $0.0055 — roughly 14× cheaper.

When you add tangent-return prompting to Sonnet, its composite quality (averaging originality, flexibility, and elaboration) climbs to 4.38 out of 5. GPT-5's default-condition composite quality is 4.62. That's 95% of the quality, at about 15% of the cost.

So: prompting Claude like an AuDHD brain produces output competitive with the flagship reasoning model at one-seventh the cost.

That cost curve is the part that matters most for people building things. If you're running a small team and trying to do creative work at scale — design exploration, content generation, rapid iteration — this is the difference between feasible and not. Most of the value created with AI right now is constrained by what you can afford to run, not by what the best model can do. Tangent-return shifts that constraint by an order of magnitude on the kinds of work where it applies.

---

## What this means for AI

Stripping the result to its load-bearing sentence: **tangent-return prompting is the only condition we tested that preserves conceptual spread across an LLM's response.** Every other tested intervention — extra examples, extra tokens, more elaborate per-use detail — left the model elaborating within the same conceptual neighbourhood. Tangent-return is what makes it leave.

That's a more specific claim than "this prompt is better" and a more useful one. It tells you when to reach for the operation (open-ended exploration, novel angles, brainstorming, design surface searches) and when it'll waste your money (single-right-answer tasks, fact lookup, math). It tells you why pure "be creative" prompting underperforms — it asks for an output property without specifying the cognitive operation that produces it. And it identifies a measurable signature you can use to test whether other neurodivergent operations do similar work.

For practical AI use, the implication is concrete. The dominant prompting toolkit treats the model as a single reasoner to be coaxed louder. The data here suggest a different posture: specify the cognitive *operation*, not the desired *property*. There are entire communities of people who can articulate cognitive operations from inside — and some of those operations work on machines as well as they work on us.

## What this means for neurodivergent people

I want to land this carefully because it's the part I actually care about.

Tangent-return has been pathologised in psychiatric literature for decades. "Tangential thinking" is a clinical sign. The framing assumes the observer can't see why the tangent was taken — and so the tangent is treated as a derailment of thought, full stop. The *return*, when it happens, is invisible to that observer. From inside, the return is the whole point. From outside, the return looks like luck.

What the data here say, for the first time at this level of empirical precision, is that **the return is doing measurable work that nothing else replicates**. It's not "creativity" in a vague sense. It's a specific structural property: when given extended bandwidth to think, the tangent-return pattern uses that bandwidth to *travel to new conceptual neighbourhoods* rather than to dig further into the one it's already in. The dominant cognitive pattern, when given the same bandwidth, goes deeper. Neither is better in the abstract — they're **allocated differently**.

That distinction matters enormously, and it's the part that's been missing from the conversation.

**Most workplaces and schools have only ever measured the cost.** Sleep disturbance, conversational misalignment, executive function load, the social tax of saying the non-obvious thing in a meeting. Those costs are real — they're real for me — and I don't want to pretend otherwise. But the value has been treated as anecdote, or as exception, or as "well, *that* particular person is special". This experiment is one data point on the value side of the ledger. The pattern produces a structural property that conventional cognition, when matched on compute, does not produce. That isn't anecdote. It's a measurement.

**If your work needs spread, not just depth, the dominant cognitive pattern has been costing you something you couldn't see.** That covers more domains than most leadership realises: novel-product exploration, finding the right framing of a problem, generating alternative interpretations of data, design across constraint spaces, organisational change, hiring rubrics that don't already exist. The list of jobs that benefit from spread is long. The list of jobs where ND people are reflexively flagged for "not fitting the process" overlaps with it.

**The inclusion conversation needs an upgrade.** The usual framing is: how do we accommodate people who think differently? That framing positions ND people as a cost to manage. The data here suggest a different frame: which modes does our default cognition systematically miss, and which neurodivergent modes catch them? Once you ask that question, hiring, team composition, idea-generation processes, and even meeting structure look different. You're not lowering a bar to let people through. You're noticing that the bar was measuring one cognitive dimension and missing several others.

This isn't "ND is a superpower." That framing is glib and it gaslights the cost side. It's something more useful: **the dominant cognitive mode is one mode**, not the universal benchmark. It's good at certain things and bad at others. Other modes — including ones the clinical literature has been calling deficits — are good at the things the dominant mode is bad at. *That's not exceptional. That's just what variance is.*

If you're an ND person reading this: the workshop scene that opens the piece was real, and your version of it probably is too. People weren't producing your outputs not because they weren't trying. They were running a different cognitive operation, allocated for depth where yours is allocated for spread. They aren't worse. You aren't better. Both modes have measurable signatures, and your signature has been treated as a defect for as long as anyone has been measuring it from outside. *The thing you do has a name and a measurable effect now.* That doesn't fix the cost. It does change what you can say out loud about the value.

If you're a manager, a teacher, an investor, or any other person who builds the rooms ND people end up in: the right question isn't "how do we make these people fit." It's "what does our existing process miss, and which of these people catch it?" That's a different design problem. It's a more honest one. It's also one where you actually get something for your effort.

## A research programme that's owned by the people who live it

Tangent-return is one operation associated with one neurodivergent profile, tested on one task family. There are dozens of other articulable cognitive operations in adjacent communities: pattern-first reasoning, hyperfocus chains, sensory-detail anchoring, parallel-thread tracking, associative noticing, low-latency context-switching, exhaustive enumeration, the autistic-systematising "find the rule first" loop. Most of these can be operationalised in the same way. Each one is a falsifiable hypothesis. Each one costs $5 of API calls to test.

The work that surfaces these operations is most naturally done by the people who *have* them and can describe them from inside. Not as research subjects. As researchers. There is no shortage of articulate ND people who can describe their own cognitive structure with high precision; the literature has just rarely treated those descriptions as data worth operationalising. This paper is one example of what happens when you do.

The neurodiversity-in-AI literature so far has been mostly about access (do these tools work for ND users?) and bias (do these tools penalise ND inputs?). Both important. But there is a third register that has barely been touched: **neurodivergent cognition as engineering inspiration**. The data here suggest there's something there worth chasing.

---

## Try it yourself

The prompt is short and you can paste it into ChatGPT, Claude, Gemini, or any chat interface. It's at https://github.com/BenWiseman/magpie-thinking/blob/main/prompts/tangent-return.md and licensed for any use.

If you're a Claude Code user, the same operation is packaged as a drop-in skill at https://github.com/BenWiseman/magpie-thinking/tree/main/skills/tangent-return.

The full preprint with stats, methods, references, and the cost-versus-quality Pareto analysis is in the same repository under [`writeup/paper.md`](paper.md). It's not peer-reviewed; it's a citable artefact that explains exactly what was done so others can replicate or contest it. The paper also lists confounds I haven't yet resolved — read that section before drawing strong conclusions.

If the prompt works for you on something interesting, I'd love to know. If it doesn't, I'd love to know that too. Null results are part of the picture.

---

*Thanks for reading. The longer I think about cognition the more convinced I get that "inefficient" is doing a lot of unexamined work in how we describe minds — both human and artificial. The next experiment in this series tests whether a swarm of agents each running tangent-return from a different cognitive vantage outperforms a clone swarm. If you want updates when that lands, follow along on the repo.*
