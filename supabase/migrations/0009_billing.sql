alter table public.subscriptions
  add column provider_event_created timestamptz not null default 'epoch'::timestamptz;

create table public.billing_webhook_events (
  event_id text primary key,
  event_type text not null,
  provider text not null default 'stripe',
  provider_created_at timestamptz not null,
  processed_at timestamptz not null default now()
);
alter table public.billing_webhook_events enable row level security;

create or replace function public.sync_stripe_subscription_event(
  p_event_id text,
  p_event_type text,
  p_event_created timestamptz,
  p_user_id uuid default null,
  p_customer_id text default null,
  p_subscription_id text default null,
  p_status text default null,
  p_current_period_end timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_user_id uuid := p_user_id;
  entitlement_tier text;
begin
  insert into public.billing_webhook_events (event_id,event_type,provider_created_at)
  values (p_event_id,p_event_type,p_event_created)
  on conflict (event_id) do nothing;
  if not found then return false; end if;

  if resolved_user_id is null and p_subscription_id is not null then
    select user_id into resolved_user_id
    from public.subscriptions
    where provider = 'stripe' and provider_subscription_id = p_subscription_id;
  end if;
  if resolved_user_id is null or p_subscription_id is null or p_status is null then
    return true;
  end if;

  insert into public.subscriptions (
    user_id,provider,provider_customer_id,provider_subscription_id,status,
    current_period_end,provider_event_created,updated_at
  ) values (
    resolved_user_id,'stripe',p_customer_id,p_subscription_id,p_status,
    p_current_period_end,p_event_created,now()
  )
  on conflict (provider,provider_subscription_id) do update set
    provider_customer_id = coalesce(excluded.provider_customer_id,subscriptions.provider_customer_id),
    status = excluded.status,
    current_period_end = excluded.current_period_end,
    provider_event_created = excluded.provider_event_created,
    updated_at = now()
  where subscriptions.provider_event_created <= excluded.provider_event_created
  returning user_id into resolved_user_id;
  if not found then return true; end if;

  entitlement_tier := case when p_status in ('active','trialing') then 'pro' else 'free' end;
  insert into public.entitlements (user_id,tier,valid_until,source,updated_at)
  values (
    resolved_user_id,
    entitlement_tier,
    case when entitlement_tier = 'pro' then p_current_period_end else null end,
    'stripe',
    now()
  )
  on conflict (user_id) do update set
    tier = case
      when entitlements.tier = 'admin' then 'admin'
      when excluded.tier = 'pro' then 'pro'
      when entitlements.source not in ('stripe','default') then entitlements.tier
      else 'free'
    end,
    valid_until = case
      when entitlements.tier = 'admin' then entitlements.valid_until
      when excluded.tier = 'pro' then excluded.valid_until
      when entitlements.source not in ('stripe','default') then entitlements.valid_until
      else null
    end,
    source = case
      when entitlements.tier = 'admin' then entitlements.source
      when excluded.tier = 'pro' or entitlements.source in ('stripe','default') then 'stripe'
      else entitlements.source
    end,
    updated_at = now();
  return true;
end;
$$;

revoke all on function public.sync_stripe_subscription_event(text,text,timestamptz,uuid,text,text,text,timestamptz) from public, anon, authenticated;
grant execute on function public.sync_stripe_subscription_event(text,text,timestamptz,uuid,text,text,text,timestamptz) to service_role;

create policy "public billing config read" on public.app_config
  for select using (key in ('billing_channels','product_limits','product_display'));

insert into public.app_config (key,value) values
  ('billing_channels','{"web":"stripe","ios":"store","android":"store","other":"store"}'::jsonb),
  ('product_limits','{}'::jsonb),
  ('product_display','{"pro_title":"Konterreflex Pro","pro_description":"Alle freigeschalteten Trainingsfunktionen gemäß deinem Abo."}'::jsonb)
on conflict (key) do nothing;
