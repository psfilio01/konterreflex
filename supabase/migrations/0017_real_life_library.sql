create or replace function public.is_valid_real_life_reconstruction(
  snapshot jsonb
)
returns boolean
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  entry jsonb;
  character_names text[] := array[]::text[];
  entry_name text;
begin
  if jsonb_typeof(snapshot) <> 'object'
    or (select count(*) from jsonb_object_keys(snapshot)) <> 4
    or not snapshot ?& array['title', 'moderator_intro', 'characters', 'turns']
    or jsonb_typeof(snapshot -> 'title') <> 'string'
    or length(trim(snapshot ->> 'title')) not between 1 and 80
    or jsonb_typeof(snapshot -> 'moderator_intro') <> 'string'
    or length(trim(snapshot ->> 'moderator_intro')) = 0
    or jsonb_typeof(snapshot -> 'characters') <> 'array'
    or jsonb_array_length(snapshot -> 'characters') not between 1 and 4
    or jsonb_typeof(snapshot -> 'turns') <> 'array'
    or jsonb_array_length(snapshot -> 'turns') not between 1 and 8
  then
    return false;
  end if;

  for entry in select value from jsonb_array_elements(snapshot -> 'characters')
  loop
    if jsonb_typeof(entry) <> 'object'
      or (select count(*) from jsonb_object_keys(entry)) <> 2
      or not entry ?& array['name', 'description']
      or jsonb_typeof(entry -> 'name') <> 'string'
      or length(trim(entry ->> 'name')) = 0
      or jsonb_typeof(entry -> 'description') <> 'string'
    then
      return false;
    end if;
    entry_name := trim(entry ->> 'name');
    if entry_name = any(character_names) then return false; end if;
    character_names := array_append(character_names, entry_name);
  end loop;

  for entry in select value from jsonb_array_elements(snapshot -> 'turns')
  loop
    if jsonb_typeof(entry) <> 'object'
      or (select count(*) from jsonb_object_keys(entry)) <> 3
      or not entry ?& array['character_name', 'body', 'stage_direction']
      or jsonb_typeof(entry -> 'character_name') <> 'string'
      or not trim(entry ->> 'character_name') = any(character_names)
      or jsonb_typeof(entry -> 'body') <> 'string'
      or length(trim(entry ->> 'body')) = 0
      or jsonb_typeof(entry -> 'stage_direction') <> 'string'
    then
      return false;
    end if;
  end loop;

  return true;
end;
$$;

create table public.real_life_reconstructions (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.real_life_cases(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  locale text not null check (locale in ('de', 'en')),
  title text not null check (length(trim(title)) between 1 and 80),
  scenario_snapshot jsonb not null
    check (public.is_valid_real_life_reconstruction(scenario_snapshot)),
  model_meta jsonb not null default '{}'::jsonb
    check (jsonb_typeof(model_meta) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(case_id, locale)
);

create index real_life_reconstructions_user_locale_idx
  on public.real_life_reconstructions(user_id, locale, updated_at desc);

alter table public.real_life_reconstructions enable row level security;

create policy "real life reconstructions own read"
  on public.real_life_reconstructions
  for select
  using (
    user_id = auth.uid()
    and exists (
      select 1 from public.real_life_cases real_case
      where real_case.id = case_id and real_case.user_id = auth.uid()
    )
  );

create policy "real life reconstructions own insert"
  on public.real_life_reconstructions
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.real_life_cases real_case
      where real_case.id = case_id and real_case.user_id = auth.uid()
    )
  );

create policy "real life reconstructions own update"
  on public.real_life_reconstructions
  for update
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.real_life_cases real_case
      where real_case.id = case_id and real_case.user_id = auth.uid()
    )
  );

create policy "real life reconstructions own delete"
  on public.real_life_reconstructions
  for delete
  using (user_id = auth.uid());

create trigger real_life_reconstructions_set_updated_at
  before update on public.real_life_reconstructions
  for each row execute procedure public.set_updated_at();

create or replace function public.save_real_life_case_with_reconstruction(
  p_client_id uuid,
  p_source_transcript text,
  p_extracted_context jsonb,
  p_locale text,
  p_title text,
  p_scenario_snapshot jsonb,
  p_model_meta jsonb
)
returns table(case_id uuid, case_client_id uuid)
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_case_id uuid;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_locale not in ('de', 'en') then raise exception 'Unsupported locale'; end if;
  if length(trim(p_source_transcript)) = 0 then raise exception 'Source transcript required'; end if;
  if jsonb_typeof(p_extracted_context) <> 'object' then raise exception 'Invalid extraction'; end if;
  if not public.is_valid_real_life_reconstruction(p_scenario_snapshot) then
    raise exception 'Invalid reconstruction';
  end if;
  if trim(p_title) <> trim(p_scenario_snapshot ->> 'title') then
    raise exception 'Reconstruction title mismatch';
  end if;

  insert into public.real_life_cases (
    user_id,
    client_id,
    source_transcript,
    extracted_context
  ) values (
    v_user_id,
    p_client_id,
    trim(p_source_transcript),
    p_extracted_context
  )
  on conflict (user_id, client_id) do update set
    source_transcript = excluded.source_transcript,
    extracted_context = excluded.extracted_context
  returning id into v_case_id;

  insert into public.real_life_reconstructions (
    case_id,
    user_id,
    locale,
    title,
    scenario_snapshot,
    model_meta
  ) values (
    v_case_id,
    v_user_id,
    p_locale,
    trim(p_title),
    p_scenario_snapshot,
    coalesce(p_model_meta, '{}'::jsonb)
  )
  on conflict on constraint real_life_reconstructions_case_id_locale_key
  do update set
    title = excluded.title,
    scenario_snapshot = excluded.scenario_snapshot,
    model_meta = excluded.model_meta;

  return query select v_case_id, p_client_id;
end;
$$;

revoke all on function public.save_real_life_case_with_reconstruction(
  uuid, text, jsonb, text, text, jsonb, jsonb
) from public;
grant execute on function public.save_real_life_case_with_reconstruction(
  uuid, text, jsonb, text, text, jsonb, jsonb
) to authenticated;
