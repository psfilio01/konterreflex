begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

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
