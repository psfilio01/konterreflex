alter table public.training_sessions
  add column client_id uuid not null default gen_random_uuid();

alter table public.user_responses
  add column client_id uuid not null default gen_random_uuid();

create unique index training_sessions_user_client_id_key
  on public.training_sessions(user_id, client_id);

create unique index user_responses_user_client_id_key
  on public.user_responses(user_id, client_id);

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
  source
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'Die spontane Rückfrage',
    'Arbeit · 1:1',
    '{"format":"one_to_one","setting":"kurzes Gespräch nach einem Termin"}',
    'Nach einem gemeinsamen Termin spricht dich ein Teammitglied direkt an.',
    'Du warst heute ungewöhnlich still. Hast du überhaupt eine Meinung dazu?',
    'Die Aussage fordert eine klare Position und setzt die bisherige Zurückhaltung unter sozialen Druck.',
    '["klare Position","ruhiger Frame","natürliche Kürze"]',
    'active',
    'curated'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Unterbrochen im Teamgespräch',
    'Arbeit · Gruppe',
    '{"format":"group","setting":"Teamrunde"}',
    'Du stellst in einer Teamrunde einen Vorschlag vor. Zwei Personen reagieren, bevor du deinen Gedanken beenden kannst.',
    'Wir sind schon beim nächsten Punkt.',
    'Die Gruppe beschleunigt die Entscheidung. Deine Aufgabe ist, dir kurz Raum zu nehmen, ohne die Runde unnötig zu verschärfen.',
    '["Präsenz in der Gruppe","präzise Unterbrechung","passende Intensität"]',
    'active',
    'curated'
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
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Sam',
    'Ein direktes Teammitglied',
    0
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Alex',
    'Moderiert die Teamrunde zügig',
    0
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    'Kim',
    'Reagiert knapp auf den Vorschlag',
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
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'Du warst heute ungewöhnlich still. Hast du überhaupt eine Meinung dazu?',
    0
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    'Danke, wir müssen langsam weiter.',
    0
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000003',
    'Wir sind schon beim nächsten Punkt.',
    1
  )
on conflict (id) do nothing;
