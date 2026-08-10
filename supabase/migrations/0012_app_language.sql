update public.profiles
set locale = 'de'
where locale not in ('de', 'en');

alter table public.profiles
  add constraint profiles_locale_supported_check
  check (locale in ('de', 'en'));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, locale)
  values (
    new.id,
    case
      when new.raw_user_meta_data ->> 'locale' in ('de', 'en')
        then new.raw_user_meta_data ->> 'locale'
      else 'de'
    end
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, 'user')
  on conflict (user_id) do nothing;

  insert into public.entitlements (user_id, tier, source)
  values (new.id, 'free', 'default')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

alter table public.scenarios
  add column locale text not null default 'de'
  check (locale in ('de', 'en'));

alter table public.speech_challenge_sets
  add column locale text not null default 'de'
  check (locale in ('de', 'en'));

create index scenarios_active_locale_idx
  on public.scenarios(locale, title)
  where status = 'active';

create index speech_challenge_sets_active_locale_idx
  on public.speech_challenge_sets(locale, sort_order)
  where active;

insert into public.scenarios (
  id,
  title,
  category,
  context,
  moderator_intro,
  trigger_statement,
  underlying_intent,
  evaluation_focus,
  status,
  source,
  locale
)
values
  (
    '11000000-0000-0000-0000-000000000001',
    'The spontaneous follow-up',
    'Work · 1:1',
    '{"format":"one_to_one","setting":"brief conversation after a meeting"}',
    'After a meeting, a teammate approaches you directly.',
    'You were unusually quiet today. Do you even have an opinion on this?',
    'The comment asks for a clear position and puts your earlier restraint under social pressure.',
    '["clear position","calm framing","natural brevity"]',
    'active',
    'curated',
    'en'
  ),
  (
    '11000000-0000-0000-0000-000000000002',
    'Interrupted in a team discussion',
    'Work · Group',
    '{"format":"group","setting":"team discussion"}',
    'You are presenting an idea in a team discussion. Two people respond before you can finish your thought.',
    'We have already moved on to the next item.',
    'The group is speeding up the decision. Your task is to briefly reclaim space without escalating the discussion unnecessarily.',
    '["presence in the group","precise interruption","appropriate intensity"]',
    'active',
    'curated',
    'en'
  )
on conflict (id) do nothing;

insert into public.scenario_characters (
  id,
  scenario_id,
  name,
  description,
  sort_order
)
values
  (
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000001',
    'Sam',
    'A direct teammate',
    0
  ),
  (
    '21000000-0000-0000-0000-000000000002',
    '11000000-0000-0000-0000-000000000002',
    'Alex',
    'Keeps the team discussion moving quickly',
    0
  ),
  (
    '21000000-0000-0000-0000-000000000003',
    '11000000-0000-0000-0000-000000000002',
    'Kim',
    'Responds briefly to the idea',
    1
  )
on conflict (id) do nothing;

insert into public.scenario_turns (
  id,
  scenario_id,
  character_id,
  body,
  sort_order
)
values
  (
    '31000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000001',
    '21000000-0000-0000-0000-000000000001',
    'You were unusually quiet today. Do you even have an opinion on this?',
    0
  ),
  (
    '31000000-0000-0000-0000-000000000002',
    '11000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000002',
    'Thanks, we need to move on.',
    0
  ),
  (
    '31000000-0000-0000-0000-000000000003',
    '11000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000003',
    'We have already moved on to the next item.',
    1
  )
on conflict (id) do nothing;

insert into public.speech_challenge_sets (
  id,
  title,
  description,
  active,
  sort_order,
  locale
)
values
  (
    '42000000-0000-0000-0000-000000000001',
    'Clear boundaries',
    'Set boundaries spontaneously without escalating unnecessarily.',
    true,
    0,
    'en'
  ),
  (
    '42000000-0000-0000-0000-000000000002',
    'Precise position',
    'Express a position briefly while keeping the conversation open.',
    true,
    1,
    'en'
  )
on conflict (id) do nothing;

insert into public.speech_challenge_prompts (
  id,
  set_id,
  remark,
  context,
  sort_order
)
values
  (
    '43000000-0000-0000-0000-000000000001',
    '42000000-0000-0000-0000-000000000001',
    'Stop making such a big deal out of it.',
    'Someone dismisses your concern.',
    0
  ),
  (
    '43000000-0000-0000-0000-000000000002',
    '42000000-0000-0000-0000-000000000001',
    'It was only a joke.',
    'After an inappropriate comment, your reaction is being dismissed.',
    1
  ),
  (
    '43000000-0000-0000-0000-000000000003',
    '42000000-0000-0000-0000-000000000002',
    'You are avoiding the question.',
    'Your position is challenged directly.',
    0
  ),
  (
    '43000000-0000-0000-0000-000000000004',
    '42000000-0000-0000-0000-000000000002',
    'Why should we choose your proposal?',
    'A group expects a brief explanation.',
    1
  )
on conflict (id) do nothing;
