import { AiTask } from "../contracts.ts";
import { JsonSchema } from "./schema.ts";

export interface AiTaskDefinition {
  task: AiTask;
  promptFile: string;
  promptVersion: string;
  outputSchema: JsonSchema;
}

const text = (minLength = 0): JsonSchema => ({ type: "string", minLength });
const textList = (maxItems?: number): JsonSchema => ({
  type: "array",
  items: text(1),
  ...(maxItems == null ? {} : { maxItems }),
});
const strictObject = (
  properties: Record<string, JsonSchema>,
  required = Object.keys(properties),
): JsonSchema => ({
  type: "object",
  properties,
  required,
  additionalProperties: false,
});

const characterSchema = strictObject({
  name: text(1),
  description: text(),
});

const turnSchema = strictObject({
  character_name: text(),
  body: text(1),
  stage_direction: text(),
});

const scenarioSchema = strictObject({
  title: text(1),
  category: text(1),
  moderator_intro: text(1),
  trigger_statement: text(1),
  underlying_intent: text(1),
  evaluation_focus: textList(6),
  characters: {
    type: "array",
    items: characterSchema,
    minItems: 1,
    maxItems: 4,
  },
  turns: { type: "array", items: turnSchema, minItems: 1, maxItems: 8 },
});

const reconstructionSchema = strictObject({
  moderator_intro: text(1),
  characters: {
    type: "array",
    items: characterSchema,
    minItems: 1,
    maxItems: 4,
  },
  turns: { type: "array", items: turnSchema, minItems: 1, maxItems: 8 },
});

export const taskRegistry: Record<AiTask, AiTaskDefinition> = {
  "scenario.generate": {
    task: "scenario.generate",
    promptFile: "scenario_generate_v2.md",
    promptVersion: "scenario_generate_v2",
    outputSchema: scenarioSchema,
  },
  "scenario.personalize": {
    task: "scenario.personalize",
    promptFile: "scenario_personalize_v1.md",
    promptVersion: "scenario_personalize_v1",
    outputSchema: scenarioSchema,
  },
  "scenario.safety_review": {
    task: "scenario.safety_review",
    promptFile: "scenario_safety_review_v1.md",
    promptVersion: "scenario_safety_review_v1",
    outputSchema: strictObject({
      decision: { type: "string", enum: ["pass", "needs_review", "block"] },
      findings: textList(6),
      rationale: text(1),
      hostile_content_as_training: { type: "boolean" },
      protected_trait_linkage: { type: "boolean" },
      stereotype_risk: { type: "boolean" },
    }),
  },
  "response.evaluate": {
    task: "response.evaluate",
    promptFile: "response_evaluate_v2.md",
    promptVersion: "response_evaluate_v2",
    outputSchema: strictObject({
      headline: text(1),
      explanation: text(1),
      strengths: textList(3),
      improvement: text(1),
      alternatives: textList(3),
      dimensions: strictObject({
        posture: text(1),
        precision: text(1),
        frame: text(1),
        social_effect: text(1),
        naturalness: text(1),
        escalation_fit: text(1),
      }),
    }),
  },
  "real_life.extract": {
    task: "real_life.extract",
    promptFile: "real_life_extract_v1.md",
    promptVersion: "real_life_extract_v1",
    outputSchema: strictObject({
      setting: text(),
      participants: {
        type: "array",
        items: strictObject({ name: text(1), relationship: text() }),
        maxItems: 8,
      },
      statements: textList(12),
      trigger_statement: text(),
      observable_tone: text(),
      emotional_social_tension: text(),
      original_reaction: text(),
      unresolved_questions: textList(4),
    }),
  },
  "real_life.reconstruct": {
    task: "real_life.reconstruct",
    promptFile: "real_life_reconstruct_v1.md",
    promptVersion: "real_life_reconstruct_v1",
    outputSchema: reconstructionSchema,
  },
  "conversation.reply": {
    task: "conversation.reply",
    promptFile: "conversation_reply_v1.md",
    promptVersion: "conversation_reply_v1",
    outputSchema: strictObject({ reply: text(1) }),
  },
  "golden_book.extract": {
    task: "golden_book.extract",
    promptFile: "golden_book_extract_v1.md",
    promptVersion: "golden_book_extract_v1",
    outputSchema: strictObject({
      status: {
        type: "string",
        enum: ["extracted", "needs_clarification"],
      },
      phrase: text(),
      category: text(),
      source_reference: text(),
      clarification_question: text(),
    }),
  },
};

export function promptUrl(file: string): URL {
  return new URL(`../../../prompts/${file}`, import.meta.url);
}
