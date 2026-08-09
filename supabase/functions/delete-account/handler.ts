export interface DeleteAccountDependencies {
  getUser(token: string): Promise<{ id: string } | null>;
  deleteUser(userId: string): Promise<void>;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function bearerToken(request: Request): string | null {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return null;
  const token = authorization.slice("Bearer ".length).trim();
  return token.length > 0 ? token : null;
}

export function createDeleteAccountHandler(
  dependencies: DeleteAccountDependencies,
): (request: Request) => Promise<Response> {
  return async (request) => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return jsonResponse({ error: "method_not_allowed" }, 405);
    }

    const token = bearerToken(request);
    if (token == null) return jsonResponse({ error: "unauthorized" }, 401);

    const user = await dependencies.getUser(token);
    if (user == null) return jsonResponse({ error: "unauthorized" }, 401);

    await dependencies.deleteUser(user.id);
    return jsonResponse({ deleted: true }, 200);
  };
}
