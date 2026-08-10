# Runtime prompts

Runtime prompt templates live in `supabase/prompts` and are versioned by filename. Edge Functions should load or bundle the active version through a prompt registry rather than embed large strings throughout code.

Current tasks:

- `scenario.generate` -> `scenario_generate_v2.md`
- `scenario.personalize` -> `scenario_personalize_v1.md`
- `scenario.safety_review` -> `scenario_safety_review_v1.md`
- `response.evaluate` -> `response_evaluate_v2.md`
- `response.evaluate_visual` -> `response_evaluate_v3.md`
- `real_life.extract` -> `real_life_extract_v1.md`
- `real_life.reconstruct` -> `real_life_reconstruct_v1.md`
- `conversation.reply` -> `conversation_reply_v1.md`
- `golden_book.extract` -> `golden_book_extract_v1.md`

Any prompt change that can materially alter user feedback should create a new version instead of overwriting the previous production version.
