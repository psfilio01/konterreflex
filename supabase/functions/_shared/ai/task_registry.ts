import { AiTask } from "../contracts.ts";
import { JsonSchema } from "./schema.ts";
import {
  conversationReplyV1,
  goldenBookExtractV1,
  realLifeExtractV1,
  realLifeReconstructV3,
  responseChallengeSessionV1,
  responseEvaluateV2,
  responseEvaluateV3,
  scenarioGenerateV3,
  scenarioPersonalizeV2,
  scenarioSafetyReviewV2,
} from "./generated_prompts.ts";

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
  character_name: text(1),
  body: text(1),
  stage_direction: text(),
});

const scenarioSchema = strictObject({
  title: text(1),
  category: text(1),
  moderator_intro: text(1),
  response_cue: text(1),
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
  title: text(1),
  moderator_intro: text(1),
  response_cue: text(1),
  characters: {
    type: "array",
    items: characterSchema,
    minItems: 1,
    maxItems: 4,
  },
  turns: { type: "array", items: turnSchema, minItems: 1, maxItems: 8 },
});

const feedbackSignalSchema: JsonSchema = {
  type: "string",
  enum: ["strong", "developing", "focus"],
};

const feedbackDimensionSignalsSchema = strictObject({
  posture: feedbackSignalSchema,
  precision: feedbackSignalSchema,
  frame: feedbackSignalSchema,
  social_effect: feedbackSignalSchema,
  naturalness: feedbackSignalSchema,
  escalation_fit: feedbackSignalSchema,
});

const visualFeedbackSchema = strictObject({
  overall_signal: feedbackSignalSchema,
  dimension_signals: feedbackDimensionSignalsSchema,
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
});

export const taskRegistry: Record<AiTask, AiTaskDefinition> = {
  "scenario.generate": {
    task: "scenario.generate",
    prompt: scenarioGenerateV3,
    promptVersion: "scenario_generate_v3",
    outputSchema: scenarioSchema,
  },
  "scenario.personalize": {
    task: "scenario.personalize",
    prompt: scenarioPersonalizeV2,
    promptVersion: "scenario_personalize_v2",
    outputSchema: scenarioSchema,
  },
  "scenario.safety_review": {
    task: "scenario.safety_review",
    prompt: scenarioSafetyReviewV2,
    promptVersion: "scenario_safety_review_v2",
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
  "response.evaluate_visual": {
    task: "response.evaluate_visual",
    prompt: responseEvaluateV3,
    promptVersion: "response_evaluate_visual_v3",
    outputSchema: visualFeedbackSchema,
  },
  "response.evaluate_challenge_session": {
    task: "response.evaluate_challenge_session",
    prompt: responseChallengeSessionV1,
    promptVersion: "response_challenge_session_v1",
    outputSchema: strictObject({
      summary: visualFeedbackSchema,
      details: {
        type: "array",
        minItems: 1,
        maxItems: 15,
        items: strictObject({
          signal: feedbackSignalSchema,
          headline: text(1),
          strength: text(1),
          improvement: text(1),
          alternative: text(1),
        }),
      },
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
    prompt: realLifeReconstructV3,
    promptVersion: "real_life_reconstruct_v3",
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
