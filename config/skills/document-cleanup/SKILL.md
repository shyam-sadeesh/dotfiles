---
name: document-cleanup
description: Tighten a document and strip AI writing tells ("slop"), editing the file in place. Use this skill whenever I want a document cleaned up, tightened, de-slopped, or edited for concision and clarity, including READMEs, architecture docs, design docs, specs, blog posts, and any markdown or prose file. Trigger it when I say a draft "reads like AI," "sounds robotic / generic," "is too wordy," "needs editing," or ask you to "clean up," "tighten," "polish," or "review" a document. Also use it before presenting a long written document to me for review, so I receive a tight draft rather than a bloated one.
---

# Document Cleanup

Take a document and return a tight, human-sounding version with the same meaning and structure, fewer words, and no slop. Edit the file in place; do not produce a separate summary of changes.

## Procedure

1. Read the entire document first. Understand its scope, audience, and structure before changing.
2. Read the "Removing AI tells" section below. It lists the AI patterns to hunt for and what they look like. Keep it in mind for the whole pass.
3. Edit in place. Overwrite the original with the cleaned version. The deliverable is the cleaned document itself, not a changelog, diff, or summary.
4. Cut, consolidate, and clarify only. Do not add new claims, sections, examples, or facts. If something is unclear or seems wrong or contradictory, leave the meaning intact and flag it to me separately.
5. Preserve technical accuracy, meaning, and structure. Keep headings, lists, and code blocks unless merging or dropping them removes real duplication. The reader should get the same information, faster.
6. Consolidate and standardize terminology so common terms are used throughout, with a preference towards terms already used in other documents / the codebase

## General editing rules

Apply these alongside the AI-tells removal:

- Do not change the document structure (keep lists, keep tables, keep headers etc.)
- Delete filler ("it is important to note that," "in order to," "please be aware," "due to the fact that"). Prefer the short word ("because," not "due to the fact that"; "to," not "in order to").
- Remove duplication. State each fact, concept, or instruction once, in the place it belongs. Cut restatements and merge sections that cover the same ground.
- Make guidance direct. Avoid hedges ("you may want to," "consider," "it might be a good idea to"), use imperatives ("do X," "use Y," "avoid Z").
- Prefer active voice and one idea per paragraph. Use imperative verbs for instructions.
- Be specific. Replace vague verbs like "handle" or "deal with" with what actually happens. Use consistent terms throughout, and expand an acronym on first use.
- Bold sparingly. Reserve it for critical terms or actions, not every list item or key phrase.
- Keep concrete examples. Abstract guidance needs a worked example, an edge case, or a before/after. Do not delete these just to save words.
- Avoid repetition. Code comments should never reference a GitHub issue or design document, or repeat design-document content.
- Avoid creating changelogs or sections stating what the document used to say or what changed. Pure current views are best.
- Keep it simple. Use everyday English instead of jargon. Treat each word like it costs money.

## Removing AI tells

Hunt for these common patterns:

**Word Choice:** Magic adverbs ("quietly," "deeply," "fundamentally"), inflated verbs ("leverage," "utilize," "delve," "serve as"), ornate nouns ("tapestry," "landscape," "ecosystem"). Replace with plain words.

**Sentence Structure:** 
- Negative parallelism: "It's not X—it's Y." Rewrite as a direct statement.
- Rhetorical questions: "The result? Devastating." Just state the result.
- Gerund fragments: "Fixing bugs. Shipping faster. Delivering more." Fold back into full sentences.
- Em-dash overuse: Many em-dash asides become commas, periods, or parentheses.

**Tone:**
- Filler transitions: "It's worth noting," "Here's the thing," "Let's break this down," "Importantly." Delete or replace with real connectives.
- False suspense: "Here's the kicker" or "Here's what most people miss."
- Vague attributions: "Experts say," "Industry reports suggest." Drop unsourced claims.
- Inflated stakes: Avoid framing every point as world-historical.

**Formatting:**
- Bold-first bullets: Every item bolded is a tell. Use bold only for critical terms.
- Em-dash addiction: More than 2-3 per page signals AI. Most become commas or periods.
- Unicode decoration: Smart quotes and arrow glyphs instead of straight text.

**Composition:**
- Fractal summaries: "In this section... [content] ...as we've seen." Cut the scaffolding.
- Listicles disguised as prose: "The first... The second... The third..." Rewrite as real paragraphs.
- One-point dilution: Same thesis restated five ways. Consolidate.

## Examples:

**Before:**
> This function was added to replace the previous approach of iterating through all items, which caused O(n²) performance.

**After:**
> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of naive iteration.

**Before:**
> No configuration file needed. The results are preserved automatically.

**After:**
> You do not need a configuration file. The system preserves the results automatically.