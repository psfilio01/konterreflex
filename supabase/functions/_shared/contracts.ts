export type AiTask =
  | 'scenario.generate'
  | 'scenario.personalize'
  | 'response.evaluate'
  | 'real_life.extract'
  | 'real_life.reconstruct'
  | 'conversation.reply'
  | 'golden_book.extract';

export interface AiRequest {
  task: AiTask;
  payload: Record<string, unknown>;
  schemaVersion: '1';
}

export interface AiResponse<T = unknown> {
  data: T;
  provider: string;
  model: string;
  promptVersion: string;
}
