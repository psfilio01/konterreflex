alter table public.real_life_cases
  add column client_id uuid not null default gen_random_uuid(),
  add column model_meta jsonb not null default '{}'::jsonb,
  add column updated_at timestamptz not null default now();

create unique index real_life_cases_user_client_id_key
  on public.real_life_cases(user_id, client_id);

create trigger real_life_cases_set_updated_at
  before update on public.real_life_cases
  for each row execute procedure public.set_updated_at();
