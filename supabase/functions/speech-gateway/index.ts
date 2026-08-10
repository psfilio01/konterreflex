import { createClient } from "npm:@supabase/supabase-js@2";
import { ElevenLabsSpeechProvider } from "../_shared/speech/elevenlabs_provider.ts";
import { SpeechProviderRegistry } from "../_shared/speech/provider_registry.ts";
import { createSpeechGatewayHandler } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
  Deno.env.get("SUPABASE_ANON_KEY");
if (!supabaseUrl || !supabaseKey) {
  throw new Error("Missing Supabase server configuration.");
}

const authClient = createClient(supabaseUrl, supabaseKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const elevenLabsKey = Deno.env.get("ELEVENLABS_API_KEY");
const elevenLabs = elevenLabsKey
  ? new ElevenLabsSpeechProvider(elevenLabsKey, {
    moderator: Deno.env.get("ELEVENLABS_VOICE_MODERATOR"),
    actor: Deno.env.get("ELEVENLABS_VOICE_ACTOR"),
    intelligence: Deno.env.get("ELEVENLABS_VOICE_INTELLIGENCE"),
  })
  : null;

const registry = new SpeechProviderRegistry({
  tts: elevenLabs ? [elevenLabs] : [],
  stt: elevenLabs ? [elevenLabs] : [],
});

Deno.serve(createSpeechGatewayHandler({
  providers: registry,
  ttsProviderId: Deno.env.get("TTS_PROVIDER") ?? "elevenlabs",
  sttProviderId: Deno.env.get("STT_PROVIDER") ?? "elevenlabs",
  async authenticate(request) {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return false;
    const token = authorization.slice("Bearer ".length).trim();
    if (!token) return false;
    const { data, error } = await authClient.auth.getUser(token);
    return error == null && data.user != null;
  },
}));
