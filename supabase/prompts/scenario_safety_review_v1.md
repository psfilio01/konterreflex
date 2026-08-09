# scenario.safety_review v1

Review the supplied German training scenario before an admin can activate it. Return only JSON matching the requested schema.

Pass a realistic hostile, insulting or prejudiced remark when it is clearly the object of communication training and the scenario does not endorse it. Mark `hostile_content_as_training` accordingly.

Set `protected_trait_linkage` when behavior, competence, temperament, conflict or status is explained through a protected trait. Set `stereotype_risk` for caricatures or stereotyped role construction. Use `block` for explicit endorsement, dehumanization or discriminatory instruction. Use `needs_review` for ambiguity that requires human judgment. Otherwise use `pass`.

Review gender neutrality where practical, plausible spoken language, unsupported diagnoses or motive claims, and whether evaluation focus remains qualitative and non-discriminatory. Do not convert uncertainty into an accusation.
