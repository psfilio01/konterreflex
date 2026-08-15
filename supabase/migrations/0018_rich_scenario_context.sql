alter table public.scenarios
  add column response_cue text;

update public.scenarios
set response_cue = case
  when locale = 'en' then 'Your turn. What do you say?'
  else 'Du bist dran. Was antwortest du?'
end;

alter table public.scenarios
  alter column response_cue set not null,
  add constraint scenarios_response_cue_length_check
    check (length(trim(response_cue)) between 2 and 200);

alter table public.admin_scenario_audit
  drop constraint admin_scenario_audit_action_check;

alter table public.admin_scenario_audit
  add constraint admin_scenario_audit_action_check
  check (action in (
    'create_draft',
    'edit_to_draft',
    'generate_batch',
    'import_batch',
    'active',
    'rejected',
    'archived'
  ));

create or replace function public.force_generated_scenario_draft()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.source in ('generated', 'imported') then
    new.status := 'draft';
  end if;
  return new;
end;
$$;

create or replace function public.bump_scenario_content_revision()
returns trigger language plpgsql set search_path = public as $$
begin
  if row(
    new.title,
    new.category,
    new.locale,
    new.context,
    new.moderator_intro,
    new.response_cue,
    new.trigger_statement,
    new.underlying_intent,
    new.evaluation_focus
  ) is distinct from row(
    old.title,
    old.category,
    old.locale,
    old.context,
    old.moderator_intro,
    old.response_cue,
    old.trigger_statement,
    old.underlying_intent,
    old.evaluation_focus
  ) then
    new.content_revision := old.content_revision + 1;
  end if;
  return new;
end;
$$;

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
    or (select count(*) from jsonb_object_keys(snapshot)) <> 5
    or not snapshot ?& array[
      'title',
      'moderator_intro',
      'response_cue',
      'characters',
      'turns'
    ]
    or jsonb_typeof(snapshot -> 'title') <> 'string'
    or length(trim(snapshot ->> 'title')) not between 1 and 80
    or jsonb_typeof(snapshot -> 'moderator_intro') <> 'string'
    or length(trim(snapshot ->> 'moderator_intro')) = 0
    or jsonb_typeof(snapshot -> 'response_cue') <> 'string'
    or length(trim(snapshot ->> 'response_cue')) not between 2 and 200
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

update public.real_life_reconstructions
set scenario_snapshot = scenario_snapshot || jsonb_build_object(
  'response_cue',
  case
    when locale = 'en' then 'Your turn. What do you say?'
    else 'Du bist dran. Was antwortest du?'
  end
)
where not scenario_snapshot ? 'response_cue';

create or replace function public.resolve_shared_speech_resource(
  p_kind text,
  p_id uuid,
  p_language text
)
returns table (
  speech_text text,
  voice_role text,
  voice_id text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_language not in ('de', 'en') then
    return;
  end if;

  if p_kind = 'scenario_intro' then
    return query
      select s.moderator_intro, 'moderator'::text, null::text
      from public.scenarios s
      where s.id = p_id
        and s.status = 'active'
        and s.locale = p_language
        and nullif(btrim(s.moderator_intro), '') is not null;
  elsif p_kind = 'scenario_stage_direction' then
    return query
      select t.stage_direction, 'moderator'::text, null::text
      from public.scenario_turns t
      join public.scenarios s on s.id = t.scenario_id
      where t.id = p_id
        and s.status = 'active'
        and s.locale = p_language
        and nullif(btrim(t.stage_direction), '') is not null;
  elsif p_kind = 'scenario_turn' then
    return query
      select t.body, 'actor'::text, c.voice_id
      from public.scenario_turns t
      join public.scenarios s on s.id = t.scenario_id
      left join public.scenario_characters c on c.id = t.character_id
      where t.id = p_id
        and s.status = 'active'
        and s.locale = p_language;
  elsif p_kind = 'scenario_response_cue' then
    return query
      select s.response_cue, 'moderator'::text, null::text
      from public.scenarios s
      where s.id = p_id
        and s.status = 'active'
        and s.locale = p_language;
  elsif p_kind = 'challenge_prompt' then
    return query
      select p.remark, 'moderator'::text, null::text
      from public.speech_challenge_prompts p
      join public.speech_challenge_sets challenge_set
        on challenge_set.id = p.set_id
      where p.id = p_id
        and challenge_set.active
        and challenge_set.locale = p_language;
  end if;
end;
$$;
