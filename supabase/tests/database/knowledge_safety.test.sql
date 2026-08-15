begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values ('cccccccc-3333-4333-8333-cccccccccccc','00000000-0000-0000-0000-000000000000','authenticated','authenticated','safety-admin@example.test','',now(),'{}','{}',now(),now());
update public.user_roles set role = 'admin' where user_id = 'cccccccc-3333-4333-8333-cccccccccccc';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'cccccccc-3333-4333-8333-cccccccccccc', true);

insert into public.scenarios (id,title,category,moderator_intro,response_cue,status,source,created_by)
values ('a0000000-0000-4000-8000-000000000001','Safety Entwurf','Test','Kurzer Rahmen','Was antwortest du?','draft','generated','cccccccc-3333-4333-8333-cccccccccccc');

select throws_ok(
  $$ update public.scenarios set status = 'active' where id = 'a0000000-0000-4000-8000-000000000001' $$,
  'P0001',
  'Current scenario revision has no passed safety review',
  'a generated draft cannot activate without review'
);

insert into public.scenario_safety_reviews (
  scenario_id,content_revision,decision,rationale,provider,model,prompt_version,reviewed_by
) values (
  'a0000000-0000-4000-8000-000000000001',1,'pass','Keine diskriminierende Verknüpfung.','mock','mock','scenario_safety_review_v1','cccccccc-3333-4333-8333-cccccccccccc'
);
update public.scenarios set status = 'active' where id = 'a0000000-0000-4000-8000-000000000001';
select is((select status::text from public.scenarios where id = 'a0000000-0000-4000-8000-000000000001'),'active','the reviewed revision can activate');

insert into public.scenario_characters (scenario_id,name,sort_order)
values ('a0000000-0000-4000-8000-000000000001','Alex',0);
select is((select content_revision from public.scenarios where id = 'a0000000-0000-4000-8000-000000000001'),2,'editing content creates a new review revision');
select throws_ok(
  $$ update public.scenarios set status = 'active' where id = 'a0000000-0000-4000-8000-000000000001' $$,
  'P0001',
  'Current scenario revision has no passed safety review',
  'an old safety review cannot approve edited content'
);

select public.admin_create_knowledge_version(null,'Historische Quelle','Historische Autorin','Historisches Modell','Nur historischer Kontext','historical','Kein moderner empirischer Konsens') as first_id \gset
select public.admin_create_knowledge_version(:'first_id','Historische Quelle · kommentiert','Historische Autorin','Historisches Modell','Nur historischer Kontext','historical','Kein moderner empirischer Konsens; nicht zur Diagnose') as second_id \gset
select results_eq(
  $$ select version from public.communication_knowledge order by version $$,
  array[1,2],
  'knowledge changes create traceable versions'
);

select * from finish();
rollback;
