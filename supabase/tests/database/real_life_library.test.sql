begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

select ok(
  public.is_valid_real_life_reconstruction(
    '{"title":"Teamgespräch","moderator_intro":"Du bist wieder im Gespräch.","response_cue":"Was antwortest du?","characters":[{"name":"Alex","description":"Teammitglied"}],"turns":[{"character_name":"Alex","body":"Wir müssen weiter.","stage_direction":""}]}'::jsonb
  ),
  'a complete reconstruction snapshot is valid'
);
select isnt(
  public.is_valid_real_life_reconstruction(
    '{"moderator_intro":"Intro","characters":[],"turns":[]}'::jsonb
  ),
  true,
  'a reconstruction without title and playable lines is invalid'
);
select isnt(
  public.is_valid_real_life_reconstruction(
    '{"title":"Teamgespräch","moderator_intro":"Intro","response_cue":"Was antwortest du?","characters":[{"name":"Alex","description":"Teammitglied","private_note":"secret"}],"turns":[{"character_name":"Alex","body":"Weiter.","stage_direction":""}]}'::jsonb
  ),
  true,
  'unexpected nested model fields are rejected'
);
select isnt(
  public.is_valid_real_life_reconstruction(
    '{"title":"Teamgespräch","moderator_intro":"Intro","response_cue":"Was antwortest du?","characters":[{"name":"Alex","description":"Teammitglied"}],"turns":[{"character_name":"Unknown","body":"Weiter.","stage_direction":""}]}'::jsonb
  ),
  true,
  'dialogue may only reference a declared character'
);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('b1000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','library-one@example.test','',now(),'{}','{}',now(),now()),
  ('b1000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','library-two@example.test','',now(),'{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000001', true);

select results_eq(
  $$
    select case_client_id
    from public.save_real_life_case_with_reconstruction(
      'b2000000-0000-4000-8000-000000000001',
      'Private Situation',
      '{"setting":"Teamrunde"}'::jsonb,
      'de',
      'Teamgespräch',
      '{"title":"Teamgespräch","moderator_intro":"Du bist wieder im Gespräch.","response_cue":"Was antwortest du?","characters":[{"name":"Alex","description":"Teammitglied"}],"turns":[{"character_name":"Alex","body":"Wir müssen weiter.","stage_direction":""}]}'::jsonb,
      '{"provider":"mock","model":"mock","prompt_version":"v2"}'::jsonb
    )
  $$,
  $$ values ('b2000000-0000-4000-8000-000000000001'::uuid) $$,
  'confirmed reconstruction and case are saved atomically'
);
select is((select count(*) from public.real_life_cases), 1::bigint, 'the owner sees one saved case');
select is((select count(*) from public.real_life_reconstructions), 1::bigint, 'the owner sees one German snapshot');
select is(
  (select title from public.real_life_reconstructions),
  'Teamgespräch',
  'the reusable short title is stored'
);

select lives_ok(
  $$
    select *
    from public.save_real_life_case_with_reconstruction(
      'b2000000-0000-4000-8000-000000000001',
      'Private Situation',
      '{"setting":"Teamrunde"}'::jsonb,
      'de',
      'Teamgespräch',
      '{"title":"Teamgespräch","moderator_intro":"Du bist wieder im Gespräch.","response_cue":"Was antwortest du?","characters":[{"name":"Alex","description":"Teammitglied"}],"turns":[{"character_name":"Alex","body":"Wir müssen weiter.","stage_direction":""}]}'::jsonb,
      '{"provider":"mock"}'::jsonb
    )
  $$,
  'retrying the atomic save is safe'
);
select is((select count(*) from public.real_life_reconstructions), 1::bigint, 'a save retry does not duplicate the language snapshot');

select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000002', true);
select is((select count(*) from public.real_life_cases), 0::bigint, 'another user cannot read the case');
select is((select count(*) from public.real_life_reconstructions), 0::bigint, 'another user cannot read its snapshots');
select throws_ok(
  $$
    insert into public.real_life_reconstructions (
      case_id,user_id,locale,title,scenario_snapshot
    ) values (
      (select id from public.real_life_cases where client_id = 'b2000000-0000-4000-8000-000000000001'),
      'b1000000-0000-4000-8000-000000000002','en','Stolen',
      '{"title":"Stolen","moderator_intro":"Intro","response_cue":"What do you say?","characters":[{"name":"A","description":""}],"turns":[{"character_name":"A","body":"Line","stage_direction":""}]}'::jsonb
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "real_life_reconstructions"',
  'RLS prevents another user from resolving or attaching to the private case'
);

reset role;
insert into public.practice_schedules (
  user_id,item_kind,real_life_case_id,locale,stage,last_signal,last_practiced_at,next_due_at
) select
  'b1000000-0000-4000-8000-000000000001','real_life',id,'de',1,'developing',now(),now()
from public.real_life_cases
where client_id = 'b2000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b1000000-0000-4000-8000-000000000001', true);
select is(
  public.delete_own_real_life_case(
    (select id from public.real_life_cases where client_id = 'b2000000-0000-4000-8000-000000000001')
  ),
  true,
  'the owner can delete the saved case'
);
select is((select count(*) from public.real_life_reconstructions), 0::bigint, 'case deletion removes localized snapshots');
select is((select count(*) from public.practice_schedules where item_kind = 'real_life'), 0::bigint, 'case deletion removes its adaptive schedule');

select * from finish();
rollback;
