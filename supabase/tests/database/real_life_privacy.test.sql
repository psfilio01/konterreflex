begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '44444444-4444-4444-4444-444444444444',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'case-one@example.test', '', now(),
    '{}', '{}', now(), now()
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'case-two@example.test', '', now(),
    '{}', '{}', now(), now()
  );

insert into public.real_life_cases (user_id, source_transcript)
values ('44444444-4444-4444-4444-444444444444', 'Private Situation');

set local role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
select is(
  (select count(*) from public.real_life_cases),
  1::bigint,
  'the owner can read the private replay case'
);

select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', true);
select is(
  (select count(*) from public.real_life_cases),
  0::bigint,
  'another user cannot read the private replay case'
);

select * from finish();
rollback;
