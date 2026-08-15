begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

select is(public.next_practice_stage(null, 'focus'), 0::smallint, 'focus starts at stage zero');
select is(public.next_practice_stage(null, 'developing'), 1::smallint, 'developing starts at stage one');
select is(public.next_practice_stage(null, 'strong'), 2::smallint, 'strong starts at stage two');
select is(public.next_practice_stage(5::smallint, 'focus'), 0::smallint, 'focus resets a mature item');
select is(public.next_practice_stage(5::smallint, 'developing'), 2::smallint, 'developing returns a mature item to stage two');
select is(public.next_practice_stage(4::smallint, 'strong'), 5::smallint, 'strong advances one stage');
select is(public.next_practice_stage(5::smallint, 'strong'), 5::smallint, 'strong is capped at stage five');

select results_eq(
  $$ select public.practice_interval_days(stage::smallint) from generate_series(0, 5) stage order by stage $$,
  $$ values (1), (3), (7), (14), (30), (60) $$,
  'review stages use the documented day intervals'
);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('a1000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','adaptive-one@example.test','',now(),'{}','{}',now(),now()),
  ('a1000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','adaptive-two@example.test','',now(),'{}','{}',now(),now());

update public.scenarios set status = 'archived';
insert into public.scenarios (id,title,category,moderator_intro,response_cue,status,source,locale) values
  ('a2000000-0000-4000-8000-000000000001','Due','Test','Intro','Was antwortest du?','active','curated','de'),
  ('a2000000-0000-4000-8000-000000000002','Unseen','Test','Intro','Was antwortest du?','active','curated','de'),
  ('a2000000-0000-4000-8000-000000000003','English','Test','Intro','What do you say?','active','curated','en');

insert into public.real_life_cases (id,user_id,source_transcript,extracted_context) values
  ('a3000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','Owner case','{"setting":"office"}'),
  ('a3000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000002','Other case','{"setting":"office"}');

insert into public.training_sessions (id,user_id,scenario_id,mode,client_id) values
  ('a4000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','a2000000-0000-4000-8000-000000000001','simulation','a4100000-0000-4000-8000-000000000001');
insert into public.user_responses (id,session_id,user_id,client_id,transcript) values
  ('a5000000-0000-4000-8000-000000000001','a4000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','a5100000-0000-4000-8000-000000000001','Answer');
insert into public.feedback (response_id,user_id,headline,explanation,improvement,overall_signal) values
  ('a5000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','Good','Context','Next','strong');

select is(
  (select stage from public.practice_schedules where scenario_id = 'a2000000-0000-4000-8000-000000000001'),
  2::smallint,
  'saved strong feedback creates a stage two training schedule'
);
select is(
  (select last_response_id from public.practice_schedules where scenario_id = 'a2000000-0000-4000-8000-000000000001'),
  'a5000000-0000-4000-8000-000000000001'::uuid,
  'the processed response is retained for idempotency'
);
select ok(
  (select next_due_at between now() + interval '6 days 23 hours' and now() + interval '7 days 1 hour'
   from public.practice_schedules where scenario_id = 'a2000000-0000-4000-8000-000000000001'),
  'strong feedback schedules the first review in seven days'
);

update public.feedback set headline = 'Still good'
where response_id = 'a5000000-0000-4000-8000-000000000001';
select is(
  (select stage from public.practice_schedules where scenario_id = 'a2000000-0000-4000-8000-000000000001'),
  2::smallint,
  'updating feedback for the same response does not advance the schedule'
);

insert into public.user_responses (id,session_id,user_id,client_id,transcript) values
  ('a5000000-0000-4000-8000-000000000002','a4000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','a5100000-0000-4000-8000-000000000002','Another answer');
insert into public.feedback (response_id,user_id,headline,explanation,improvement,overall_signal) values
  ('a5000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','Again','Context','Next','strong');
select is(
  (select stage from public.practice_schedules where scenario_id = 'a2000000-0000-4000-8000-000000000001'),
  3::smallint,
  'a new strong response advances the schedule once'
);

insert into public.training_sessions (id,user_id,mode,client_id) values
  ('a4000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','speech_challenge','a4100000-0000-4000-8000-000000000002');
insert into public.user_responses (id,session_id,user_id,client_id,transcript) values
  ('a5000000-0000-4000-8000-000000000003','a4000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','a5100000-0000-4000-8000-000000000003','Challenge answer');
insert into public.feedback (response_id,user_id,headline,explanation,improvement,overall_signal) values
  ('a5000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','Challenge','Context','Next','focus');
select is((select count(*) from public.practice_schedules), 1::bigint, 'Speech Challenge does not create a schedule');

insert into public.training_sessions (id,user_id,mode,client_id,state) values
  ('a4000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','real_life','a4100000-0000-4000-8000-000000000003','{"real_life_case_id":"a3000000-0000-4000-8000-000000000001","locale":"en"}');
insert into public.user_responses (id,session_id,user_id,client_id,transcript) values
  ('a5000000-0000-4000-8000-000000000004','a4000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','a5100000-0000-4000-8000-000000000004','Real answer');
insert into public.feedback (response_id,user_id,headline,explanation,improvement,overall_signal) values
  ('a5000000-0000-4000-8000-000000000004','a1000000-0000-4000-8000-000000000001','Replay','Context','Next','developing');
select is(
  (select stage from public.practice_schedules where real_life_case_id = 'a3000000-0000-4000-8000-000000000001'),
  1::smallint,
  'real-life feedback creates its separate schedule'
);
select is(
  (select locale from public.practice_schedules where real_life_case_id = 'a3000000-0000-4000-8000-000000000001'),
  'en',
  'real-life schedules retain the replay language'
);

update public.practice_schedules
set next_due_at = now() - interval '2 days', last_practiced_at = now() - interval '1 day'
where scenario_id = 'a2000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);

select is((select count(*) from public.practice_schedules), 2::bigint, 'the owner reads both private schedules');
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('training','de') $$,
  $$ values ('a2000000-0000-4000-8000-000000000001'::uuid, 'training'::text) $$,
  'an overdue training item wins over an unseen item'
);
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('real_life','de') $$,
  $$ values ('a3000000-0000-4000-8000-000000000001'::uuid, 'real_life'::text) $$,
  'the real-life pool selects only an owned case'
);

select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
select is((select count(*) from public.practice_schedules), 0::bigint, 'another user cannot read private schedules');
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('real_life','de') $$,
  $$ values ('a3000000-0000-4000-8000-000000000002'::uuid, 'real_life'::text) $$,
  'another user receives only their own real-life case'
);
select throws_ok(
  $$ insert into public.practice_schedules (user_id,item_kind,scenario_id,locale,stage,last_signal,last_practiced_at,next_due_at) values ('a1000000-0000-4000-8000-000000000002','training','a2000000-0000-4000-8000-000000000002','de',5,'strong',now(),now()) $$,
  '42501',
  'new row violates row-level security policy for table "practice_schedules"',
  'clients cannot manipulate their schedule directly'
);

select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select throws_ok(
  $$ select * from public.select_next_practice_item('mixed','de') $$,
  'P0001',
  'Unsupported practice pool',
  'mixed practice pools are rejected'
);
select throws_ok(
  $$ select * from public.select_next_practice_item('training','fr') $$,
  'P0001',
  'Unsupported locale',
  'unsupported locales are rejected'
);

reset role;
update public.practice_schedules
set next_due_at = now() + interval '4 days'
where scenario_id = 'a2000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('training','de') $$,
  $$ values ('a2000000-0000-4000-8000-000000000002'::uuid, 'training'::text) $$,
  'an unseen item wins when nothing is due'
);
select is(
  (select count(*) from public.select_next_practice_item('training','en')),
  1::bigint,
  'training selection is available independently in another language'
);

reset role;
insert into public.practice_schedules (
  user_id,item_kind,scenario_id,locale,stage,last_signal,last_practiced_at,next_due_at
) values (
  'a1000000-0000-4000-8000-000000000001','training',
  'a2000000-0000-4000-8000-000000000002','de',1,'developing',
  now() - interval '1 day',now() - interval '1 day'
);
update public.practice_schedules
set next_due_at = now() - interval '2 days', last_practiced_at = now()
where scenario_id = 'a2000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('training','de') $$,
  $$ values ('a2000000-0000-4000-8000-000000000002'::uuid, 'training'::text) $$,
  'the most recently practised due item is avoided when an alternative exists'
);

reset role;
update public.practice_schedules
set
  next_due_at = case scenario_id
    when 'a2000000-0000-4000-8000-000000000001' then now() + interval '4 days'
    else now() + interval '6 days'
  end,
  last_practiced_at = case scenario_id
    when 'a2000000-0000-4000-8000-000000000001' then now() - interval '1 day'
    else now()
  end
where item_kind = 'training';

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
select results_eq(
  $$ select item_id, item_kind from public.select_next_practice_item('training','de') $$,
  $$ values ('a2000000-0000-4000-8000-000000000001'::uuid, 'training'::text) $$,
  'the closest future item is used when every item is scheduled ahead'
);

select * from finish();
rollback;
