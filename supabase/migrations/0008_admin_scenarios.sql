alter type public.scenario_status add value if not exists 'rejected';

create table public.admin_scenario_audit (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (action in ('create_draft','edit_to_draft','generate_batch','active','rejected','archived')),
  scenario_ids jsonb not null default '[]'::jsonb,
  batch_id text,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.admin_scenario_audit enable row level security;
create policy "admin scenario audit read" on public.admin_scenario_audit
  for select using (public.is_admin());
create policy "admin scenario audit insert" on public.admin_scenario_audit
  for insert with check (public.is_admin() and actor_id = auth.uid());

create policy "role own read" on public.user_roles
  for select using (user_id = auth.uid());

create or replace function public.force_generated_scenario_draft()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.source = 'generated' then
    new.status := 'draft';
  end if;
  return new;
end;
$$;

create trigger generated_scenario_starts_as_draft
before insert on public.scenarios
for each row execute function public.force_generated_scenario_draft();

create trigger scenarios_set_updated_at
before update on public.scenarios
for each row execute function public.set_updated_at();

insert into public.app_config (key,value)
values ('actor_voice_options','[]'::jsonb)
on conflict (key) do nothing;
