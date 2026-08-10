# Speech Challenge flow

## Goal

Speech Challenge is a continuous spontaneity exercise, not a sequence of small
tests. Feedback must not interrupt the user's speaking rhythm. The user chooses
the intended session length before starting and receives one consolidated,
qualitative result after the final response.

## Session setup

- The topic is selected first.
- The next screen offers quick choices for 5, 10 or 15 prompts.
- A custom value from 1 through 15 is also accepted.
- Five prompts are selected by default.
- A session never repeats a prompt. Active challenge sets therefore contain at
  least 15 curated prompts per supported language.

The limit keeps the session understandable, bounds the AI payload and prevents
accidental, unexpectedly expensive runs. The count controls progress only; it
is never interpreted as performance.

## Hands-free flow

For every selected prompt the app:

1. plays the short prompt;
2. records the spoken response until silence;
3. transcribes and saves the response;
4. continues directly with the next prompt.

There is no spoken or visual performance feedback between prompts. The UI shows
only neutral session progress and the current voice state. If the user ends a
session early, already completed responses can still receive a consolidated
result.

## Consolidated result

After the final response, one batch evaluation produces:

- one overall qualitative feedback object with the standard visual signals;
- one concise detail per response, in the same order as the prompts;
- for every detail: a qualitative signal, headline, observed strength, next
  improvement and one natural alternative.

The overall result is contextual. It must not be calculated by averaging,
counting or converting detail signals into points. Detail cards are collapsed by
default so the result remains calm and scannable. Opening a card reveals the
prompt, transcript and its qualitative guidance.

Once the result is available, the app may speak the consolidated summary. No
detail feedback is spoken between prompts.

## Reliability and cost

- All responses are saved before evaluation starts.
- The session uses one Gemini batch call instead of one call after every answer.
- A failed evaluation can be retried without repeating the challenge.
- The server validates the complete result schema; the client additionally
  requires exactly one detail for every completed response.
- Session results and provider metadata are stored under user-owned RLS.
- No speed score, leaderboard, percentage, grade or hidden numerical score is
  introduced.
