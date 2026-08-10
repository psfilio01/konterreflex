import { aiTasks } from "../contracts.ts";
import { taskRegistry } from "./task_registry.ts";

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
