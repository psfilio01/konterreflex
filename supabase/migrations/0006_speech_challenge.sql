create table public.speech_challenge_sets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  active boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.speech_challenge_prompts (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.speech_challenge_sets(id) on delete cascade,
  remark text not null,
  context text not null default '',
  sort_order integer not null default 0
);

alter table public.user_responses add column context jsonb not null default '{}'::jsonb;
alter table public.speech_challenge_sets enable row level security;
alter table public.speech_challenge_prompts enable row level security;

create policy "active challenge sets readable" on public.speech_challenge_sets
  for select using (active or public.is_admin());
create policy "admin challenge sets all" on public.speech_challenge_sets
  for all using (public.is_admin()) with check (public.is_admin());
create policy "active challenge prompts readable" on public.speech_challenge_prompts
  for select using (exists (
    select 1 from public.speech_challenge_sets sets
    where sets.id = set_id and (sets.active or public.is_admin())
  ));
create policy "admin challenge prompts all" on public.speech_challenge_prompts
  for all using (public.is_admin()) with check (public.is_admin());

insert into public.speech_challenge_sets (id,title,description,active,sort_order) values
  ('40000000-0000-0000-0000-000000000001','Klare Grenzen','Spontan Grenzen setzen, ohne unnötig zu verschärfen.',true,0),
  ('40000000-0000-0000-0000-000000000002','Präzise Position','Eine Haltung kurz und anschlussfähig ausdrücken.',true,1);

insert into public.speech_challenge_prompts (id,set_id,remark,context,sort_order) values
  ('41000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Jetzt stell dich nicht so an.','Eine Person spielt dein Anliegen herunter.',0),
  ('41000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001','Das war doch nur Spaß.','Nach einem unpassenden Kommentar wird deine Reaktion relativiert.',1),
  ('41000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000002','Du weichst der Frage aus.','Deine Position wird direkt angezweifelt.',0),
  ('41000000-0000-0000-0000-000000000004','40000000-0000-0000-0000-000000000002','Warum sollten wir deinen Vorschlag nehmen?','Eine Gruppe erwartet eine kurze Begründung.',1);
