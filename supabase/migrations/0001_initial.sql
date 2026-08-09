create extension if not exists "pgcrypto";

create type public.scenario_status as enum ('draft','active','archived');
create type public.training_mode as enum ('simulation','real_life','speech_challenge');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text not null default 'de',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('user','admin')) default 'user'
);

create table public.scenarios (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,
  context jsonb not null default '{}'::jsonb,
  moderator_intro text,
  trigger_statement text,
  underlying_intent text,
  evaluation_focus jsonb not null default '[]'::jsonb,
  status public.scenario_status not null default 'draft',
  source text not null default 'manual',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.scenario_characters (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid not null references public.scenarios(id) on delete cascade,
  name text not null,
  description text,
  voice_id text,
  sort_order integer not null default 0
);

create table public.scenario_turns (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid not null references public.scenarios(id) on delete cascade,
  character_id uuid references public.scenario_characters(id) on delete set null,
  body text not null,
  stage_direction text,
  sort_order integer not null
);

create table public.training_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  scenario_id uuid references public.scenarios(id) on delete set null,
  mode public.training_mode not null,
  state jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.user_responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.training_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  transcript text,
  audio_path text,
  created_at timestamptz not null default now()
);

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  response_id uuid not null references public.user_responses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  headline text not null,
  explanation text not null,
  alternatives jsonb not null default '[]'::jsonb,
  dimensions jsonb not null default '{}'::jsonb,
  model_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.real_life_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_transcript text not null,
  extracted_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.golden_book_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  phrase text not null,
  category text,
  note text,
  source_session_id uuid references public.training_sessions(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  provider_customer_id text,
  provider_subscription_id text,
  status text not null,
  current_period_end timestamptz,
  updated_at timestamptz not null default now(),
  unique(provider, provider_subscription_id)
);

create table public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tier text not null default 'free',
  valid_until timestamptz,
  source text not null default 'default',
  updated_at timestamptz not null default now()
);

create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

create table public.prompt_versions (
  id uuid primary key default gen_random_uuid(),
  task text not null,
  version text not null,
  prompt text not null,
  active boolean not null default false,
  created_at timestamptz not null default now(),
  unique(task, version)
);

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.scenarios enable row level security;
alter table public.scenario_characters enable row level security;
alter table public.scenario_turns enable row level security;
alter table public.training_sessions enable row level security;
alter table public.user_responses enable row level security;
alter table public.feedback enable row level security;
alter table public.real_life_cases enable row level security;
alter table public.golden_book_entries enable row level security;
alter table public.subscriptions enable row level security;
alter table public.entitlements enable row level security;
alter table public.app_config enable row level security;
alter table public.prompt_versions enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = 'admin'
  );
$$;

create policy "profile own read" on public.profiles for select using (id = auth.uid());
create policy "profile own update" on public.profiles for update using (id = auth.uid());
create policy "active scenarios readable" on public.scenarios for select using (status = 'active' or public.is_admin());
create policy "admin scenarios all" on public.scenarios for all using (public.is_admin()) with check (public.is_admin());
create policy "scenario characters readable" on public.scenario_characters for select using (exists (select 1 from public.scenarios s where s.id = scenario_id and (s.status = 'active' or public.is_admin())));
create policy "admin scenario characters all" on public.scenario_characters for all using (public.is_admin()) with check (public.is_admin());
create policy "scenario turns readable" on public.scenario_turns for select using (exists (select 1 from public.scenarios s where s.id = scenario_id and (s.status = 'active' or public.is_admin())));
create policy "admin scenario turns all" on public.scenario_turns for all using (public.is_admin()) with check (public.is_admin());
create policy "sessions own" on public.training_sessions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "responses own" on public.user_responses for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "feedback own" on public.feedback for select using (user_id = auth.uid());
create policy "real life own" on public.real_life_cases for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "golden book own" on public.golden_book_entries for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "subscriptions own read" on public.subscriptions for select using (user_id = auth.uid());
create policy "entitlements own read" on public.entitlements for select using (user_id = auth.uid());
create policy "admin config" on public.app_config for all using (public.is_admin()) with check (public.is_admin());
create policy "admin prompts" on public.prompt_versions for all using (public.is_admin()) with check (public.is_admin());
