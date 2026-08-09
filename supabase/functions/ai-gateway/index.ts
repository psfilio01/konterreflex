import { createClient } from "npm:@supabase/supabase-js@2";
import { GeminiProvider } from "../_shared/ai/gemini_provider.ts";
import { AiProvider } from "../_shared/ai/provider.ts";
import { AiProviderRegistry } from "../_shared/ai/provider_registry.ts";
import { AiTaskDefinition, promptUrl } from "../_shared/ai/task_registry.ts";
import { createAiGatewayHandler } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ??
  Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
if (!supabaseUrl || !supabaseKey) {
  throw new Error("Missing Supabase server configuration.");
}

const authClient = createClient(supabaseUrl, supabaseKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const providers: AiProvider[] = [];
const geminiKey = Deno.env.get("GEMINI_API_KEY");
if (geminiKey) {
  providers.push(
    new GeminiProvider(
      geminiKey,
      Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash",
    ),
  );
}

const configuredTimeout = Number(Deno.env.get("AI_TIMEOUT_MS") ?? "20000");
const timeoutMs = Number.isFinite(configuredTimeout)
  ? Math.min(Math.max(configuredTimeout, 1_000), 30_000)
  : 20_000;

Deno.serve(createAiGatewayHandler({
  providerId: Deno.env.get("AI_PROVIDER") ?? "gemini",
  providers: new AiProviderRegistry(providers),
  timeoutMs,
  async authenticate(request) {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return false;
    const token = authorization.slice("Bearer ".length).trim();
    if (!token) return false;
    const { data, error } = await authClient.auth.getUser(token);
    return error == null && data.user != null;
  },
  loadPrompt(definition: AiTaskDefinition) {
    return Deno.readTextFile(promptUrl(definition.promptFile));
  },
  log(message, metadata) {
    console.error(JSON.stringify({ message, ...metadata }));
  },
}));
