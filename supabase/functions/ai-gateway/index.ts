import { AiRequest } from '../_shared/contracts.ts';

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  const body = await req.json() as AiRequest;
  if (!body?.task || body.schemaVersion !== '1') {
    return Response.json({ error: 'Invalid request' }, { status: 400 });
  }

  // Prompt 03 implements authenticated routing, provider adapters,
  // JSON schema validation, prompt versioning and Gemini default behavior.
  return Response.json({
    error: 'AI gateway not implemented yet',
    task: body.task,
  }, { status: 501 });
});
