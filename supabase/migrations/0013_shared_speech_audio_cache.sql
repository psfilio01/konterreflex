create table public.shared_speech_audio_cache (
  cache_key text primary key
    check (cache_key ~ '^[0-9a-f]{64}$'),
  storage_path text not null unique,
  state text not null default 'pending'
    check (state in ('pending', 'ready', 'failed')),
  claim_token uuid,
  lease_until timestamptz,
  mime_type text,
  provider text,
  model text,
  byte_size integer check (byte_size between 1 and 5242880),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_accessed_at timestamptz
);

alter table public.shared_speech_audio_cache enable row level security;
revoke all on table public.shared_speech_audio_cache
  from public, anon, authenticated;
grant select, insert, update, delete on table public.shared_speech_audio_cache
  to service_role;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'shared-speech-cache',
  'shared-speech-cache',
  false,
  5242880,
  array[
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/ogg',
    'audio/aac',
    'audio/mp4'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

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
  elsif p_kind = 'scenario_turn' then
    return query
      select t.body, 'actor'::text, c.voice_id
      from public.scenario_turns t
      join public.scenarios s on s.id = t.scenario_id
      left join public.scenario_characters c on c.id = t.character_id
      where t.id = p_id
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

revoke all on function public.resolve_shared_speech_resource(text, uuid, text)
  from public, anon, authenticated;
grant execute on function public.resolve_shared_speech_resource(text, uuid, text)
  to service_role;

create or replace function public.claim_shared_speech_audio(
  p_cache_key text,
  p_storage_path text,
  p_claim_token uuid,
  p_lease_seconds integer default 30
)
returns table (
  cache_state text,
  storage_path text,
  mime_type text,
  provider text,
  model text,
  claimed boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_cache_key !~ '^[0-9a-f]{64}$'
    or p_storage_path !~ '^v1/[0-9a-f]{2}/[0-9a-f]{64}$'
    or p_lease_seconds not between 5 and 120 then
    raise exception 'Invalid shared speech cache claim';
  end if;

  insert into public.shared_speech_audio_cache as cache (
    cache_key,
    storage_path,
    state,
    claim_token,
    lease_until
  ) values (
    p_cache_key,
    p_storage_path,
    'pending',
    p_claim_token,
    now() + make_interval(secs => p_lease_seconds)
  )
  on conflict (cache_key) do update set
    storage_path = excluded.storage_path,
    state = 'pending',
    claim_token = excluded.claim_token,
    lease_until = excluded.lease_until,
    updated_at = now()
  where cache.state <> 'ready'
    and (cache.lease_until is null or cache.lease_until <= now());

  return query
    select
      cache.state,
      cache.storage_path,
      cache.mime_type,
      cache.provider,
      cache.model,
      cache.state = 'pending' and cache.claim_token = p_claim_token
    from public.shared_speech_audio_cache cache
    where cache.cache_key = p_cache_key;
end;
$$;

create or replace function public.complete_shared_speech_audio(
  p_cache_key text,
  p_claim_token uuid,
  p_mime_type text,
  p_provider text,
  p_model text,
  p_byte_size integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.shared_speech_audio_cache cache set
    state = 'ready',
    claim_token = null,
    lease_until = null,
    mime_type = p_mime_type,
    provider = p_provider,
    model = p_model,
    byte_size = p_byte_size,
    updated_at = now(),
    last_accessed_at = now()
  where cache.cache_key = p_cache_key
    and cache.state = 'pending'
    and cache.claim_token = p_claim_token
    and p_mime_type like 'audio/%'
    and p_byte_size between 1 and 5242880;
  return found;
end;
$$;

create or replace function public.fail_shared_speech_audio(
  p_cache_key text,
  p_claim_token uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.shared_speech_audio_cache cache set
    state = 'failed',
    claim_token = null,
    lease_until = now(),
    updated_at = now()
  where cache.cache_key = p_cache_key
    and cache.claim_token = p_claim_token;
  return found;
end;
$$;

create or replace function public.invalidate_shared_speech_audio(
  p_cache_key text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.shared_speech_audio_cache cache set
    state = 'failed',
    claim_token = null,
    lease_until = now(),
    updated_at = now()
  where cache.cache_key = p_cache_key;
  return found;
end;
$$;

create or replace function public.touch_shared_speech_audio(
  p_cache_key text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.shared_speech_audio_cache cache set
    last_accessed_at = now()
  where cache.cache_key = p_cache_key
    and cache.state = 'ready';
  return found;
end;
$$;

revoke all on function public.claim_shared_speech_audio(text, text, uuid, integer)
  from public, anon, authenticated;
revoke all on function public.complete_shared_speech_audio(text, uuid, text, text, text, integer)
  from public, anon, authenticated;
revoke all on function public.fail_shared_speech_audio(text, uuid)
  from public, anon, authenticated;
revoke all on function public.invalidate_shared_speech_audio(text)
  from public, anon, authenticated;
revoke all on function public.touch_shared_speech_audio(text)
  from public, anon, authenticated;

grant execute on function public.claim_shared_speech_audio(text, text, uuid, integer)
  to service_role;
grant execute on function public.complete_shared_speech_audio(text, uuid, text, text, text, integer)
  to service_role;
grant execute on function public.fail_shared_speech_audio(text, uuid)
  to service_role;
grant execute on function public.invalidate_shared_speech_audio(text)
  to service_role;
grant execute on function public.touch_shared_speech_audio(text)
  to service_role;
