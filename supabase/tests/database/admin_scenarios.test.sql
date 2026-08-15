begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('99999999-9999-4999-8999-999999999999','00000000-0000-0000-0000-000000000000','authenticated','authenticated','admin@example.test','',now(),'{}','{}',now(),now()),
  ('aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000000','authenticated','authenticated','regular@example.test','',now(),'{}','{}',now(),now());
update public.user_roles set role = 'admin' where user_id = '99999999-9999-4999-8999-999999999999';

set local role authenticated;
select set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
insert into public.scenarios (id,title,category,response_cue,status,source,created_by)
values ('90000000-0000-4000-8000-000000000001','KI-Entwurf','Test','Was antwortest du?','active','generated','99999999-9999-4999-8999-999999999999');

select is((select status::text from public.scenarios where id = '90000000-0000-4000-8000-000000000001'),'draft','generated scenarios are forced into draft on insert');

insert into public.scenarios (id,title,category,response_cue,status,source,created_by)
values ('90000000-0000-4000-8000-000000000002','Import-Entwurf','Test','Was antwortest du?','active','imported','99999999-9999-4999-8999-999999999999');
select is((select status::text from public.scenarios where id = '90000000-0000-4000-8000-000000000002'),'draft','imported scenarios are forced into draft on insert');

insert into public.admin_scenario_audit (actor_id,action,scenario_ids,batch_id)
values ('99999999-9999-4999-8999-999999999999','generate_batch','["90000000-0000-4000-8000-000000000001"]','batch-test');
select is((select count(*) from public.admin_scenario_audit),1::bigint,'an admin can read the batch audit record');

insert into public.admin_scenario_audit (actor_id,action,scenario_ids,batch_id)
values ('99999999-9999-4999-8999-999999999999','import_batch','["90000000-0000-4000-8000-000000000001"]','import-test');
select is((select count(*) from public.admin_scenario_audit),2::bigint,'an imported batch has an accepted audit action');

select set_config('request.jwt.claim.sub', 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa', true);
select is((select count(*) from public.admin_scenario_audit),0::bigint,'regular users cannot read admin audit data');
select throws_ok(
  $$ insert into public.scenarios (title,category,response_cue,status,source) values ('Unerlaubt','Test','Was sagst du?','draft','manual') $$,
  '42501',
  null,
  'regular users cannot create admin scenario data'
);

select * from finish();
rollback;
