begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '93000000-0000-4000-8000-000000000018',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'speech-context@example.test', '', now(),
  '{}', '{}', now(), now()
);

select has_table(
  'public',
  'shared_speech_audio_cache',
  'shared speech cache metadata exists'
);

select is(
  (select public from storage.buckets where id = 'shared-speech-cache'),
  false,
  'shared speech objects are kept in a private bucket'
);

set local role authenticated;
select throws_ok(
  $$ select count(*) from public.shared_speech_audio_cache $$,
  '42501',
  null,
  'authenticated clients cannot inspect cache metadata'
);

set local role service_role;

insert into public.scenarios (
  id,title,category,moderator_intro,response_cue,status,source,locale
) values (
  '90000000-0000-4000-8000-000000000018',
  'Context cache',
  'Test',
  'Ein ausführlicher Kontext.',
  'Was antwortest du?',
  'draft',
  'curated',
  'de'
);
insert into public.scenario_characters (
  id,scenario_id,name,description,sort_order
) values (
  '91000000-0000-4000-8000-000000000018',
  '90000000-0000-4000-8000-000000000018',
  'Alex',
  'Testfigur',
  0
);
insert into public.scenario_turns (
  id,scenario_id,character_id,body,stage_direction,sort_order
) values (
  '92000000-0000-4000-8000-000000000018',
  '90000000-0000-4000-8000-000000000018',
  '91000000-0000-4000-8000-000000000018',
  'Das sehe ich anders.',
  'Alex schaut dich direkt an und sagt:',
  0
);
insert into public.scenario_safety_reviews (
  scenario_id,content_revision,decision,rationale,provider,model,
  prompt_version,reviewed_by
) select
  id,content_revision,'pass','Neutrale Testszene.','mock','mock','test',
  '93000000-0000-4000-8000-000000000018'
from public.scenarios
where id = '90000000-0000-4000-8000-000000000018';
update public.scenarios
set status = 'active'
where id = '90000000-0000-4000-8000-000000000018';

select results_eq(
  $$
    select speech_text
    from public.resolve_shared_speech_resource(
      'scenario_intro',
      '10000000-0000-0000-0000-000000000001',
      'de'
    )
  $$,
  array['Nach einem gemeinsamen Termin spricht dich ein Teammitglied direkt an.'],
  'active scenario intros resolve to canonical server content'
);

select is(
  (
    select count(*)
    from public.resolve_shared_speech_resource(
      'scenario_intro',
      '10000000-0000-0000-0000-000000000001',
      'en'
    )
  ),
  0::bigint,
  'a shared resource cannot be reused for another language'
);

select results_eq(
  $$
    select speech_text, voice_role
    from public.resolve_shared_speech_resource(
      'scenario_stage_direction',
      '92000000-0000-4000-8000-000000000018',
      'de'
    )
  $$,
  $$ values ('Alex schaut dich direkt an und sagt:'::text, 'moderator'::text) $$,
  'stage directions resolve as canonical moderator content'
);

select results_eq(
  $$
    select speech_text, voice_role
    from public.resolve_shared_speech_resource(
      'scenario_response_cue',
      '90000000-0000-4000-8000-000000000018',
      'de'
    )
  $$,
  $$ values ('Was antwortest du?'::text, 'moderator'::text) $$,
  'response cues resolve as canonical moderator content'
);

select is(
  (
    select claimed
    from public.claim_shared_speech_audio(
      repeat('a', 64),
      'v1/aa/' || repeat('a', 64),
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      30
    )
  ),
  true,
  'the first cold request owns the generation claim'
);

select is(
  (
    select claimed
    from public.claim_shared_speech_audio(
      repeat('a', 64),
      'v1/aa/' || repeat('a', 64),
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      30
    )
  ),
  false,
  'a concurrent cold request cannot duplicate generation'
);

select is(
  public.complete_shared_speech_audio(
    repeat('a', 64),
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'audio/mpeg',
    'mock',
    'mock-tts',
    3
  ),
  true,
  'the claim owner can complete a generated object'
);

select results_eq(
  $$
    select cache_state, claimed
    from public.claim_shared_speech_audio(
      repeat('a', 64),
      'v1/aa/' || repeat('a', 64),
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      30
    )
  $$,
  $$ values ('ready'::text, false) $$,
  'later requests receive the ready shared object'
);

select * from finish();
rollback;
