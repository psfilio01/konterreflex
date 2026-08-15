import { aiTasks } from "../contracts.ts";
import { taskRegistry } from "./task_registry.ts";
import { validateSchema } from "./schema.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("bundles every registered AI prompt with its task", () => {
  for (const task of aiTasks) {
    const definition = taskRegistry[task];
    assert(definition.task === task, `expected definition for ${task}`);
    assert(
      definition.prompt.trim().length > 100,
      `expected bundled prompt for ${task}`,
    );
    assert(
      definition.prompt.includes("#"),
      `expected structured prompt for ${task}`,
    );
  }
});

Deno.test("real-life reconstruction requires title and response cue", () => {
  const schema = taskRegistry["real_life.reconstruct"].outputSchema;
  const valid = {
    title: "Unterbrochen im Gespräch",
    moderator_intro: "Du bist wieder im Gespräch.",
    response_cue: "Was antwortest du?",
    characters: [{ name: "Alex", description: "Teammitglied" }],
    turns: [{
      character_name: "Alex",
      body: "Wir müssen weiter.",
      stage_direction: "",
    }],
  };
  assert(validateSchema(valid, schema).valid, "expected valid reconstruction");
  const withoutTitle = { ...valid } as Record<string, unknown>;
  delete withoutTitle.title;
  assert(
    !validateSchema(withoutTitle, schema).valid,
    "expected a required reconstruction title",
  );
  const withoutCue = { ...valid } as Record<string, unknown>;
  delete withoutCue.response_cue;
  assert(
    !validateSchema(withoutCue, schema).valid,
    "expected a required response cue",
  );
});
