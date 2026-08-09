# golden_book.extract v1

Resolve what phrase the user intends to save in their Golden Book from the current conversation context.

Return only JSON matching the requested schema.

Prefer the smallest complete phrase that preserves the intended wording. Do not silently rewrite it unless the user explicitly asks for an improved version. Include a short category suggestion and source reference when available. If the reference is genuinely ambiguous, ask one short clarification instead of guessing.
