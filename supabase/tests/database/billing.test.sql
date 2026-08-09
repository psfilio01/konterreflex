begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values ('bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb','00000000-0000-0000-0000-000000000000','authenticated','authenticated','billing@example.test','',now(),'{}','{}',now(),now());

select is(
  public.sync_stripe_subscription_event('evt_active','customer.subscription.updated',now(),'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb','cus_test','sub_test','active',now() + interval '1 month'),
  true,
  'the first signed event is applied'
);
select is((select tier from public.entitlements where user_id = 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb'),'pro','an active subscription grants the server entitlement');
select is(
  public.sync_stripe_subscription_event('evt_active','customer.subscription.updated',now(),'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb','cus_test','sub_test','active',now() + interval '1 month'),
  false,
  'a replayed event is ignored idempotently'
);
select is(
  (select count(*) from public.billing_webhook_events where event_id = 'evt_active'),
  1::bigint,
  'the replay has one durable event record'
);

select * from finish();
rollback;
