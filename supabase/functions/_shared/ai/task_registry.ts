import { AiTask } from "../contracts.ts";
import { JsonSchema } from "./schema.ts";
import conversationReplyV1 from "../../../prompts/conversation_reply_v1.md" with {
  type: "text",
};
import goldenBookExtractV1 from "../../../prompts/golden_book_extract_v1.md" with {
  type: "text",
};
import realLifeExtractV1 from "../../../prompts/real_life_extract_v1.md" with {
  type: "text",
};
import realLifeReconstructV1 from "../../../prompts/real_life_reconstruct_v1.md" with {
  type: "text",
};
import responseEvaluateV2 from "../../../prompts/response_evaluate_v2.md" with {
  type: "text",
};
import scenarioGenerateV2 from "../../../prompts/scenario_generate_v2.md" with {
  type: "text",
};
import scenarioPersonalizeV1 from "../../../prompts/scenario_personalize_v1.md" with {
  type: "text",
};
import scenarioSafetyReviewV1 from "../../../prompts/scenario_safety_review_v1.md" with {
  type: "text",
};

export interface AiTaskDefinition {
  task: AiTask;
  prompt: string;
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
    prompt: scenarioGenerateV2,
    promptVersion: "scenario_generate_v2",
    outputSchema: scenarioSchema,
  },
  "scenario.personalize": {
    task: "scenario.personalize",
    prompt: scenarioPersonalizeV1,
    promptVersion: "scenario_personalize_v1",
    outputSchema: scenarioSchema,
  },
  "scenario.safety_review": {
    task: "scenario.safety_review",
    prompt: scenarioSafetyReviewV1,
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
    prompt: responseEvaluateV2,
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
    prompt: realLifeExtractV1,
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
    prompt: realLifeReconstructV1,
    promptVersion: "real_life_reconstruct_v1",
    outputSchema: reconstructionSchema,
  },
  "conversation.reply": {
    task: "conversation.reply",
    prompt: conversationReplyV1,
    promptVersion: "conversation_reply_v1",
    outputSchema: strictObject({ reply: text(1) }),
  },
  "golden_book.extract": {
    task: "golden_book.extract",
    prompt: goldenBookExtractV1,
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
