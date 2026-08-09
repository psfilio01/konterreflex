# Prompt 03: Provider agnostic AI gateway
Branch: `feature/ai-gateway`

Implement the authenticated Supabase `ai-gateway` with a small provider interface. Gemini is the default provider. Keep the contract ready for OpenAI, Claude or an OpenAI compatible self hosted gateway later. Use server side secrets, task specific prompt templates, structured JSON responses, validation, prompt version metadata, timeouts and safe error handling. Do not expose generic raw model access to the client.

Acceptance: unit tests cover routing, invalid schema and provider failure; one local mock provider makes tests deterministic. Finish the mandatory Git workflow.
