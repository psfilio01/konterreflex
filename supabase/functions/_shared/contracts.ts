export const aiTasks = [
  "scenario.generate",
  "scenario.personalize",
  "scenario.safety_review",
  "response.evaluate",
  "real_life.extract",
  "real_life.reconstruct",
  "conversation.reply",
  "golden_book.extract",
] as const;

export type AiTask = (typeof aiTasks)[number];

export interface AiRequest {
  task: AiTask;
  payload: Record<string, unknown>;
  responseLanguage: "de" | "en";
  schemaVersion: "1";
}

export interface AiResponse<T = unknown> {
  data: T;
  provider: string;
  model: string;
  promptVersion: string;
  schemaVersion: "1";
  requestId: string;
}

export function isAiTask(value: unknown): value is AiTask {
  return typeof value === "string" && aiTasks.some((task) => task === value);
}
