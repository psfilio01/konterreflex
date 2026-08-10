begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

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
  8::bigint,
  'prompts belonging to active German and English sets are readable'
);

select * from finish();
rollback;
