begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('dddddddd-4444-4444-8444-dddddddddddd','00000000-0000-0000-0000-000000000000','authenticated','authenticated','privacy-one@example.test','',now(),'{}','{}',now(),now()),
  ('eeeeeeee-5555-4555-8555-eeeeeeeeeeee','00000000-0000-0000-0000-000000000000','authenticated','authenticated','privacy-two@example.test','',now(),'{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub', 'dddddddd-4444-4444-8444-dddddddddddd', true);
insert into public.training_sessions (id,user_id,mode,client_id)
values ('d0000000-0000-4000-8000-000000000001','dddddddd-4444-4444-8444-dddddddddddd','simulation','d0000000-0000-4000-8000-000000000002');

select throws_ok(
  $$ insert into public.user_responses (session_id,user_id,client_id,audio_path) values ('d0000000-0000-4000-8000-000000000001','dddddddd-4444-4444-8444-dddddddddddd','d0000000-0000-4000-8000-000000000003','private/raw.pcm') $$,
  'P0001',
  'Raw recording retention is disabled',
  'raw audio cannot be retained by default'
);
insert into public.user_responses (session_id,user_id,client_id,transcript)
values ('d0000000-0000-4000-8000-000000000001','dddddddd-4444-4444-8444-dddddddddddd','d0000000-0000-4000-8000-000000000003','Private Antwort');

select public.set_own_privacy_preferences(0,true);
insert into public.analytics_events (user_id,event_name,feature_key,step_key,outcome_key,platform_key)
values ('dddddddd-4444-4444-8444-dddddddddddd','session_completed','training','completion','completed','web');
select is((select count(*) from public.analytics_events),1::bigint,'consented fixed analytics can be stored');
select hasnt_column('public','analytics_events','transcript','analytics has no transcript column');
select hasnt_column('public','analytics_events','audio_path','analytics has no audio column');

select set_config('request.jwt.claim.sub', 'eeeeeeee-5555-4555-8555-eeeeeeeeeeee', true);
select is(public.delete_own_training_session('d0000000-0000-4000-8000-000000000001'),false,'another user cannot delete a session');

select set_config('request.jwt.claim.sub', 'dddddddd-4444-4444-8444-dddddddddddd', true);
select is(public.delete_own_training_session('d0000000-0000-4000-8000-000000000001'),true,'the owner can delete a session');
select is((select count(*) from public.user_responses where user_id = 'dddddddd-4444-4444-8444-dddddddddddd'),0::bigint,'session deletion cascades to private responses');

insert into public.real_life_cases (id,user_id,source_transcript)
values ('d0000000-0000-4000-8000-000000000004','dddddddd-4444-4444-8444-dddddddddddd','Private Situation');
insert into public.training_sessions (user_id,mode,client_id,state)
values ('dddddddd-4444-4444-8444-dddddddddddd','real_life','d0000000-0000-4000-8000-000000000005','{"real_life_case_id":"d0000000-0000-4000-8000-000000000004"}');
select is(public.delete_own_real_life_case('d0000000-0000-4000-8000-000000000004'),true,'the owner can delete a real-life case and linked sessions');
select is((select count(*) from public.training_sessions where state ->> 'real_life_case_id' = 'd0000000-0000-4000-8000-000000000004'),0::bigint,'real-life deletion removes linked sessions');

select * from finish();
rollback;
