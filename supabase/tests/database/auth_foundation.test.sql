begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'one@example.test',
    '',
    now(),
    '{}',
    '{"locale":"de"}',
    now(),
    now()
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'two@example.test',
    '',
    now(),
    '{}',
    '{}',
    now(),
    now()
  );

select ok(
  exists(select 1 from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'new auth users receive profiles'
);
select is(
  (select role from public.user_roles where user_id = '11111111-1111-1111-1111-111111111111'),
  'user',
  'new auth users receive the user role'
);
select is(
  (select tier from public.entitlements where user_id = '11111111-1111-1111-1111-111111111111'),
  'free',
  'new auth users receive the default entitlement'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);

select results_eq(
  $$ select count(*) from public.profiles $$,
  array[1::bigint],
  'users can only read their own profile'
);

update public.profiles
set display_name = 'Nicht erlaubt'
where id = '22222222-2222-2222-2222-222222222222';

reset role;
select is(
  (select display_name from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  null,
  'users cannot update another profile'
);

select * from finish();
rollback;
