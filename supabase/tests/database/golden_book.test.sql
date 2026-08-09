begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('77777777-7777-4777-8777-777777777777','00000000-0000-0000-0000-000000000000','authenticated','authenticated','book-one@example.test','',now(),'{}','{}',now(),now()),
  ('88888888-8888-4888-8888-888888888888','00000000-0000-0000-0000-000000000000','authenticated','authenticated','book-two@example.test','',now(),'{}','{}',now(),now());

insert into public.training_sessions (id,user_id,mode,client_id)
values ('70000000-0000-4000-8000-000000000001','77777777-7777-4777-8777-777777777777','simulation','70000000-0000-4000-8000-000000000002');

set local role authenticated;
select set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
insert into public.golden_book_entries (user_id,phrase,category,source_session_id)
values ('77777777-7777-4777-8777-777777777777','  Ich beende den Gedanken.  ','Grenzen','70000000-0000-4000-8000-000000000001');

select is((select phrase from public.golden_book_entries),'Ich beende den Gedanken.','phrases are trimmed');
select is((select source_session_id from public.golden_book_entries),'70000000-0000-4000-8000-000000000001'::uuid,'an entry links to its owner session');

select throws_ok(
  $$ insert into public.golden_book_entries (user_id,phrase) values ('77777777-7777-4777-8777-777777777777','„ich   beende den Gedanken“') $$,
  '23505',
  null,
  'equivalent phrases are deduplicated'
);

select set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
select is((select count(*) from public.golden_book_entries),0::bigint,'another user cannot read private entries');

select * from finish();
rollback;
