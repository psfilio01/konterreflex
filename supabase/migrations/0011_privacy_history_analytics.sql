create table public.user_privacy_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  recording_retention_days integer not null default 0 check (recording_retention_days in (0,7,30,90)),
  analytics_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.user_privacy_preferences enable row level security;
create policy "privacy preferences own" on public.user_privacy_preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.user_responses add column audio_expires_at timestamptz;

create or replace function public.enforce_recording_retention()
returns trigger language plpgsql set search_path = public as $$
declare retention_days integer;
begin
  if new.audio_path is null then
    new.audio_expires_at := null;
    return new;
  end if;
  select recording_retention_days into retention_days
  from public.user_privacy_preferences where user_id = new.user_id;
  if coalesce(retention_days,0) = 0 then
    raise exception 'Raw recording retention is disabled';
  end if;
  new.audio_expires_at := now() + make_interval(days => retention_days);
  return new;
end;
$$;
create trigger response_recording_retention before insert or update of audio_path on public.user_responses
for each row execute function public.enforce_recording_retention();

create or replace function public.set_own_privacy_preferences(p_retention_days integer, p_analytics_enabled boolean)
returns void language plpgsql set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_retention_days not in (0,7,30,90) then raise exception 'Unsupported retention period'; end if;
  insert into public.user_privacy_preferences (user_id,recording_retention_days,analytics_enabled,updated_at)
  values (auth.uid(),p_retention_days,p_analytics_enabled,now())
  on conflict (user_id) do update set
    recording_retention_days = excluded.recording_retention_days,
    analytics_enabled = excluded.analytics_enabled,
    updated_at = now();
  if p_retention_days = 0 then
    update public.user_responses set audio_path = null where user_id = auth.uid() and audio_path is not null;
  end if;
end;
$$;

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_name text not null check (event_name in ('mode_opened','session_started','session_completed','feedback_viewed','subscription_opened')),
  feature_key text not null check (feature_key in ('training','real_life','speech_challenge','golden_book','subscription')),
  step_key text check (step_key in ('entry','scene','response','feedback','completion')),
  outcome_key text check (outcome_key in ('started','completed','cancelled','failed')),
  platform_key text not null check (platform_key in ('web','ios','android','other')),
  created_at timestamptz not null default now()
);
alter table public.analytics_events enable row level security;
create policy "analytics own insert with consent" on public.analytics_events
  for insert with check (
    user_id = auth.uid() and exists (
      select 1 from public.user_privacy_preferences preferences
      where preferences.user_id = auth.uid() and preferences.analytics_enabled
    )
  );
create policy "analytics own read" on public.analytics_events for select using (user_id = auth.uid() or public.is_admin());
create policy "analytics own delete" on public.analytics_events for delete using (user_id = auth.uid());

create or replace function public.delete_own_training_session(p_session_id uuid)
returns boolean language plpgsql set search_path = public as $$
begin
  delete from public.training_sessions where id = p_session_id and user_id = auth.uid();
  return found;
end;
$$;

create or replace function public.delete_own_real_life_case(p_case_id uuid)
returns boolean language plpgsql set search_path = public as $$
begin
  if not exists (select 1 from public.real_life_cases where id = p_case_id and user_id = auth.uid()) then
    return false;
  end if;
  delete from public.training_sessions
  where user_id = auth.uid() and state ->> 'real_life_case_id' = p_case_id::text;
  delete from public.real_life_cases where id = p_case_id and user_id = auth.uid();
  return found;
end;
$$;
