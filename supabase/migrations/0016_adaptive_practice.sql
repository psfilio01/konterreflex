create table public.practice_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_kind text not null check (item_kind in ('training', 'real_life')),
  scenario_id uuid references public.scenarios(id) on delete cascade,
  real_life_case_id uuid references public.real_life_cases(id) on delete cascade,
  locale text not null check (locale in ('de', 'en')),
  stage smallint not null check (stage between 0 and 5),
  last_signal text not null check (last_signal in ('strong', 'developing', 'focus')),
  last_response_id uuid references public.user_responses(id) on delete set null,
  last_practiced_at timestamptz not null,
  next_due_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (item_kind = 'training' and scenario_id is not null and real_life_case_id is null)
    or
    (item_kind = 'real_life' and scenario_id is null and real_life_case_id is not null)
  )
);

create unique index practice_schedules_training_key
  on public.practice_schedules(user_id, scenario_id)
  where item_kind = 'training';

create unique index practice_schedules_real_life_key
  on public.practice_schedules(user_id, real_life_case_id, locale)
  where item_kind = 'real_life';

create index practice_schedules_due_idx
  on public.practice_schedules(user_id, item_kind, locale, next_due_at);

alter table public.practice_schedules enable row level security;

create policy "practice schedules own read"
  on public.practice_schedules
  for select
  using (user_id = auth.uid());

grant select on public.practice_schedules to authenticated;

create or replace function public.next_practice_stage(
  p_current_stage smallint,
  p_signal text
)
returns smallint
language sql
immutable
set search_path = public, pg_temp
as $$
  select case p_signal
    when 'focus' then 0::smallint
    when 'developing' then least(greatest(coalesce(p_current_stage, 1), 1), 2)::smallint
    when 'strong' then least(coalesce(p_current_stage + 1, 2), 5)::smallint
    else null::smallint
  end;
$$;

create or replace function public.practice_interval_days(p_stage smallint)
returns integer
language sql
immutable
strict
set search_path = public, pg_temp
as $$
  select case p_stage
    when 0 then 1
    when 1 then 3
    when 2 then 7
    when 3 then 14
    when 4 then 30
    when 5 then 60
  end;
$$;

create or replace function public.advance_practice_schedule_from_feedback()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_mode public.training_mode;
  v_scenario_id uuid;
  v_case_id uuid;
  v_locale text;
  v_practiced_at timestamptz;
  v_initial_stage smallint;
begin
  select
    session.mode,
    session.scenario_id,
    case
      when session.state ->> 'real_life_case_id'
        ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      then (session.state ->> 'real_life_case_id')::uuid
    end,
    response.created_at
  into v_mode, v_scenario_id, v_case_id, v_practiced_at
  from public.user_responses response
  join public.training_sessions session on session.id = response.session_id
  where response.id = new.response_id
    and response.user_id = new.user_id
    and session.user_id = new.user_id;

  if not found or v_mode = 'speech_challenge' then
    return new;
  end if;

  v_initial_stage := public.next_practice_stage(null, new.overall_signal);

  if v_mode = 'simulation' and v_scenario_id is not null then
    select scenario.locale into v_locale
    from public.scenarios scenario
    where scenario.id = v_scenario_id;

    if v_locale is null then return new; end if;

    insert into public.practice_schedules (
      user_id,
      item_kind,
      scenario_id,
      locale,
      stage,
      last_signal,
      last_response_id,
      last_practiced_at,
      next_due_at
    ) values (
      new.user_id,
      'training',
      v_scenario_id,
      v_locale,
      v_initial_stage,
      new.overall_signal,
      new.response_id,
      v_practiced_at,
      now() + make_interval(days => public.practice_interval_days(v_initial_stage))
    )
    on conflict (user_id, scenario_id) where item_kind = 'training'
    do update set
      stage = public.next_practice_stage(
        public.practice_schedules.stage,
        excluded.last_signal
      ),
      last_signal = excluded.last_signal,
      last_response_id = excluded.last_response_id,
      last_practiced_at = excluded.last_practiced_at,
      next_due_at = now() + make_interval(
        days => public.practice_interval_days(
          public.next_practice_stage(
            public.practice_schedules.stage,
            excluded.last_signal
          )
        )
      ),
      updated_at = now()
    where public.practice_schedules.last_response_id
      is distinct from excluded.last_response_id;

    return new;
  end if;

  if v_mode = 'real_life' and v_case_id is not null then
    select case
      when session_locale.locale in ('de', 'en') then session_locale.locale
      else 'de'
    end into v_locale
    from (
      select coalesce(
        nullif(session.state ->> 'locale', ''),
        profile.locale,
        'de'
      ) as locale
      from public.training_sessions session
      left join public.profiles profile on profile.id = session.user_id
      join public.user_responses response on response.session_id = session.id
      where response.id = new.response_id
    ) session_locale;

    if not exists (
      select 1 from public.real_life_cases real_case
      where real_case.id = v_case_id and real_case.user_id = new.user_id
    ) then
      return new;
    end if;

    insert into public.practice_schedules (
      user_id,
      item_kind,
      real_life_case_id,
      locale,
      stage,
      last_signal,
      last_response_id,
      last_practiced_at,
      next_due_at
    ) values (
      new.user_id,
      'real_life',
      v_case_id,
      v_locale,
      v_initial_stage,
      new.overall_signal,
      new.response_id,
      v_practiced_at,
      now() + make_interval(days => public.practice_interval_days(v_initial_stage))
    )
    on conflict (user_id, real_life_case_id, locale)
      where item_kind = 'real_life'
    do update set
      stage = public.next_practice_stage(
        public.practice_schedules.stage,
        excluded.last_signal
      ),
      last_signal = excluded.last_signal,
      last_response_id = excluded.last_response_id,
      last_practiced_at = excluded.last_practiced_at,
      next_due_at = now() + make_interval(
        days => public.practice_interval_days(
          public.next_practice_stage(
            public.practice_schedules.stage,
            excluded.last_signal
          )
        )
      ),
      updated_at = now()
    where public.practice_schedules.last_response_id
      is distinct from excluded.last_response_id;
  end if;

  return new;
end;
$$;

revoke all on function public.advance_practice_schedule_from_feedback() from public;

create trigger feedback_advance_practice_schedule
after insert or update of response_id, overall_signal
on public.feedback
for each row execute function public.advance_practice_schedule_from_feedback();

create or replace function public.select_next_practice_item(
  p_pool text,
  p_locale text
)
returns table(item_id uuid, item_kind text)
language plpgsql
volatile
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if p_pool not in ('training', 'real_life') then
    raise exception 'Unsupported practice pool';
  end if;
  if p_locale not in ('de', 'en') then
    raise exception 'Unsupported locale';
  end if;

  return query
  with candidates as (
    select
      scenario.id as candidate_id,
      'training'::text as candidate_kind,
      schedule.id as schedule_id,
      schedule.last_practiced_at,
      schedule.next_due_at
    from public.scenarios scenario
    left join public.practice_schedules schedule
      on schedule.user_id = v_user_id
      and schedule.item_kind = 'training'
      and schedule.scenario_id = scenario.id
    where p_pool = 'training'
      and scenario.status = 'active'
      and scenario.locale = p_locale

    union all

    select
      real_case.id as candidate_id,
      'real_life'::text as candidate_kind,
      schedule.id as schedule_id,
      schedule.last_practiced_at,
      schedule.next_due_at
    from public.real_life_cases real_case
    left join public.practice_schedules schedule
      on schedule.user_id = v_user_id
      and schedule.item_kind = 'real_life'
      and schedule.real_life_case_id = real_case.id
      and schedule.locale = p_locale
    where p_pool = 'real_life'
      and real_case.user_id = v_user_id
  ),
  classified as (
    select
      candidate_id,
      candidate_kind,
      last_practiced_at,
      next_due_at,
      case
        when schedule_id is not null and next_due_at <= now() then 0
        when schedule_id is null then 1
        else 2
      end as priority_bucket
    from candidates
  ),
  chosen_bucket as (
    select min(priority_bucket) as value from classified
  ),
  latest_item as (
    select candidate_id
    from classified
    where last_practiced_at is not null
    order by last_practiced_at desc
    limit 1
  ),
  eligible as (
    select classified.*
    from classified, chosen_bucket
    where classified.priority_bucket = chosen_bucket.value
      and (
        classified.candidate_id is distinct from (
          select latest_item.candidate_id from latest_item
        )
        or not exists (
          select 1
          from classified alternative
          where alternative.priority_bucket = chosen_bucket.value
            and alternative.candidate_id is distinct from classified.candidate_id
        )
      )
  ),
  ranked as (
    select
      eligible.*,
      row_number() over (
        order by
          case when priority_bucket in (0, 2) then next_due_at end asc nulls last,
          case when priority_bucket = 1 then random() end
      ) as priority_rank
    from eligible
  ),
  shortlist as (
    select *
    from ranked
    where (priority_bucket = 0 and priority_rank <= 5)
       or priority_bucket = 1
       or (priority_bucket = 2 and priority_rank <= 3)
  )
  select shortlist.candidate_id, shortlist.candidate_kind
  from shortlist
  order by random()
  limit 1;
end;
$$;

revoke all on function public.select_next_practice_item(text, text) from public;
grant execute on function public.select_next_practice_item(text, text) to authenticated;
