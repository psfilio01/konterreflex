# AI layer

## Goal
Use Gemini first without making the product dependent on Gemini.

## Contract
All app calls target a server side `ai-gateway` Edge Function. The gateway exposes task oriented operations such as:

- `scenario.generate`
- `scenario.personalize`
- `scenario.safety_review`
- `response.evaluate`
- `response.evaluate_visual`
- `real_life.extract`
- `real_life.reconstruct`
- `conversation.reply`
- `golden_book.extract`

The client never calls a model provider directly.

## Provider interface
Implement a small internal adapter instead of spreading an external SDK throughout the codebase. An OpenAI compatible self hosted gateway such as LiteLLM may be introduced behind this boundary later, but it is not required for MVP operation.

## Output discipline
Use versioned JSON schemas. Store prompt version, provider and model name with generated artifacts for traceability.

Visual feedback uses categorical signals rather than calculated scores. The
legacy evaluation task remains available for older app versions; new clients use
the separately versioned visual schema.

## Knowledge foundation
Communication science references must be curated in a separate, reviewable knowledge layer. Do not claim scientific authority from a name alone. Store source, concept, intended use, evidence status and limitations.

Knowledge entries are immutable versions. Scenarios receive a structured safety
review for each content revision; only a passing review of that same revision
allows activation. Hostile remarks may remain as clearly identified training
material without being endorsed by the product.
