Deno.serve(async (_req) => {
  // Prompt 11 implements Stripe signature verification and entitlement sync.
  return Response.json({ error: 'Not implemented' }, { status: 501 });
});
