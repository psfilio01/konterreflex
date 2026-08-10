# Prompt 06: Qualitative feedback
Branch: `feature/qualitative-feedback`

Implement AI evaluation of a spoken response. Never show a numeric score. Return a short qualitative headline, concise explanation, strengths, one improvement direction and up to three natural alternatives. Evaluate contextually across posture, precision, frame, social effect, naturalness and escalation fit. Precede the text with one overall and six dimension-level qualitative signals so the result direction is visually recognizable without reading the detailed feedback. Signals must be categorical, accessible without color and must never be converted to numbers, averaged or ranked. Allow the user to ask follow up questions by voice and retry the same scene.

Acceptance: schema validated responses, the completed training result prioritizes the visual overview over the active voice orb, feedback UI stays concise, tests reject numeric scoring fields and disguised numeric signals. Finish the mandatory Git workflow.
