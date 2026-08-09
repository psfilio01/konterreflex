import { createClient } from "npm:@supabase/supabase-js@2";
import { createDeleteAccountHandler } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Missing Supabase server configuration.");
}

const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

Deno.serve(
  createDeleteAccountHandler({
    async getUser(token) {
      const { data, error } = await adminClient.auth.getUser(token);
      if (error) return null;
      return data.user == null ? null : { id: data.user.id };
    },
    async deleteUser(userId) {
      const { error } = await adminClient.auth.admin.deleteUser(userId);
      if (error) throw error;
    },
  }),
);
