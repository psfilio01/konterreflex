begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '66666666-6666-4666-8666-666666666666',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'challenge@example.test', '', now(),
  '{}', '{}', now(), now()
);

insert into public.speech_challenge_sets (id,title,description,active)
values ('40000000-0000-0000-0000-000000000099','Entwurf','Nicht sichtbar',false);

set local role authenticated;
select set_config('request.jwt.claim.sub', '66666666-6666-4666-8666-666666666666', true);

select is(
  (select count(*) from public.speech_challenge_sets),
  4::bigint,
  'regular users see active German and English challenge sets'
);

select is(
  (select count(*) from public.speech_challenge_prompts),
  60::bigint,
  'prompts belonging to active German and English sets are readable'
);

select ok(
  not exists (
    select 1
    from public.speech_challenge_sets sets
    where sets.active
      and (
        select count(*)
        from public.speech_challenge_prompts prompt
        where prompt.set_id = sets.id
      ) < 15
  ),
  'every active challenge set offers fifteen unique prompts'
);

select ok(
  (
    select rowsecurity
    from pg_tables
    where schemaname = 'public'
      and tablename = 'speech_challenge_results'
  ),
  'consolidated challenge results use row level security'
);

select ok(
  public.is_valid_speech_challenge_result('{
    "summary": {
      "overall_signal": "developing",
      "dimension_signals": {
        "posture": "strong",
        "precision": "developing",
        "frame": "developing",
        "social_effect": "strong",
        "naturalness": "strong",
        "escalation_fit": "developing"
      },
      "headline": "Clear foundation",
      "explanation": "The responses remain understandable.",
      "strengths": ["Direct openings"],
      "improvement": "Make the next step more concrete.",
      "alternatives": ["I see this differently."],
      "dimensions": {
        "posture": "calm",
        "precision": "mostly clear",
        "frame": "partly set",
        "social_effect": "constructive",
        "naturalness": "speakable",
        "escalation_fit": "appropriate"
      }
    },
    "details": [{
      "response_id": "response-1",
      "prompt_id": "prompt-1",
      "signal": "developing",
      "headline": "Clear start",
      "strength": "The position is audible.",
      "improvement": "Name the desired next step.",
      "alternative": "I want to finish this thought first."
    }]
  }'::jsonb),
  'a categorical consolidated result is accepted'
);

select ok(
  not public.is_valid_speech_challenge_result('{
    "summary": {
      "overall_signal": "8",
      "dimension_signals": {},
      "headline": "Numeric",
      "explanation": "Numeric",
      "strengths": [],
      "improvement": "Numeric",
      "alternatives": [],
      "dimensions": {}
    },
    "details": []
  }'::jsonb),
  'numeric or incomplete consolidated results are rejected'
);

select * from finish();
rollback;
