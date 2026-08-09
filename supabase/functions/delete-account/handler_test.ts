import { bearerToken, createDeleteAccountHandler } from "./handler.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("bearerToken rejects malformed authorization", () => {
  const request = new Request("http://localhost", {
    headers: { Authorization: "Basic secret" },
  });
  assert(bearerToken(request) === null, "expected malformed header to fail");
});

Deno.test("delete account requires an authenticated user", async () => {
  const handler = createDeleteAccountHandler({
    getUser: async () => null,
    deleteUser: async () => {
      throw new Error("must not be called");
    },
  });
  const response = await handler(
    new Request("http://localhost", { method: "POST" }),
  );
  assert(response.status === 401, "expected an unauthorized response");
});

Deno.test("delete account deletes only the authenticated user", async () => {
  let deletedUserId: string | null = null;
  const handler = createDeleteAccountHandler({
    getUser: async (token) => token === "valid" ? { id: "user-1" } : null,
    deleteUser: async (userId) => {
      deletedUserId = userId;
    },
  });
  const response = await handler(
    new Request("http://localhost", {
      method: "POST",
      headers: { Authorization: "Bearer valid" },
    }),
  );
  assert(response.status === 200, "expected a successful response");
  assert(
    deletedUserId === "user-1",
    "expected the authenticated user to be deleted",
  );
});
