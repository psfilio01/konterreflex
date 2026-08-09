begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values (
  '33333333-3333-3333-3333-333333333333',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'scenario@example.test', '', now(),
  '{}', '{}', now(), now()
);

insert into public.scenarios (id, title, category, status, source)
values (
  '10000000-0000-0000-0000-000000000099',
  'Nicht freigegeben',
  'Test',
  'draft',
  'generated'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);

select results_eq(
  $$ select count(*) from public.scenarios $$,
  array[2::bigint],
  'regular users can only retrieve active scenarios'
);

select is(
  (select count(*) from public.scenario_characters where scenario_id = '10000000-0000-0000-0000-000000000002'),
  2::bigint,
  'the curated group scenario exposes two actors'
);

select is(
  (select count(*) from public.scenario_turns where scenario_id = '10000000-0000-0000-0000-000000000001'),
  1::bigint,
  'the curated one-to-one scenario exposes its actor turn'
);

select * from finish();
rollback;
