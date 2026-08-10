create or replace function public.is_valid_speech_challenge_result(payload jsonb)
returns boolean
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  summary jsonb;
  details jsonb;
  detail jsonb;
begin
  if jsonb_typeof(payload) <> 'object' then
    return false;
  end if;

  if (select count(*) from jsonb_object_keys(payload)) <> 2
    or jsonb_typeof(payload -> 'summary') <> 'object'
    or jsonb_typeof(payload -> 'details') <> 'array'
  then
    return false;
  end if;

  summary := payload -> 'summary';
  details := payload -> 'details';

  if (select count(*) from jsonb_object_keys(summary)) <> 8
    or coalesce(summary ->> 'overall_signal', '')
      not in ('strong', 'developing', 'focus')
    or not public.is_valid_feedback_dimension_signals(
      summary -> 'dimension_signals'
    )
    or jsonb_array_length(details) < 1
    or jsonb_array_length(details) > 15
  then
    return false;
  end if;

  for detail in select value from jsonb_array_elements(details)
  loop
    if jsonb_typeof(detail) <> 'object' then
      return false;
    end if;

    if (select count(*) from jsonb_object_keys(detail)) <> 7
      or coalesce(detail ->> 'signal', '')
        not in ('strong', 'developing', 'focus')
      or coalesce(detail ->> 'response_id', '') = ''
      or coalesce(detail ->> 'prompt_id', '') = ''
      or coalesce(detail ->> 'headline', '') = ''
      or coalesce(detail ->> 'strength', '') = ''
      or coalesce(detail ->> 'improvement', '') = ''
      or coalesce(detail ->> 'alternative', '') = ''
    then
      return false;
    end if;
  end loop;

  return true;
end;
$$;

create table public.speech_challenge_results (
  session_id uuid primary key
    references public.training_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  result jsonb not null
    check (public.is_valid_speech_challenge_result(result)),
  model_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.speech_challenge_results enable row level security;

create policy "challenge results own"
  on public.speech_challenge_results
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.training_sessions session
      where session.id = session_id
        and session.user_id = auth.uid()
        and session.mode = 'speech_challenge'
    )
  );

insert into public.speech_challenge_prompts (
  id,
  set_id,
  remark,
  context,
  sort_order
)
values
  ('41000000-0000-0000-0000-000000000005','40000000-0000-0000-0000-000000000001','Du bist aber empfindlich.','Eine Person stellt deine Reaktion als übertrieben dar.',2),
  ('41000000-0000-0000-0000-000000000006','40000000-0000-0000-0000-000000000001','Mach das doch eben noch schnell.','Kurz vor Feierabend wird dir ungefragt eine zusätzliche Aufgabe gegeben.',3),
  ('41000000-0000-0000-0000-000000000007','40000000-0000-0000-0000-000000000001','Wir brauchen dich da, keine Diskussion.','Deine Teilnahme wird vorausgesetzt, obwohl du bereits abgesagt hast.',4),
  ('41000000-0000-0000-0000-000000000008','40000000-0000-0000-0000-000000000001','Ich habe deine Idee einfach schon weitergegeben.','Eine Person hat deinen Vorschlag ohne Rücksprache als eigenen nächsten Schritt kommuniziert.',5),
  ('41000000-0000-0000-0000-000000000009','40000000-0000-0000-0000-000000000001','Kannst du deine Pause nicht verschieben?','Eine kurzfristige Bitte kollidiert mit deiner vereinbarten Pause.',6),
  ('41000000-0000-0000-0000-000000000010','40000000-0000-0000-0000-000000000001','Das musst du jetzt aushalten.','Dein Einwand gegen einen unangemessenen Ton wird abgewiesen.',7),
  ('41000000-0000-0000-0000-000000000011','40000000-0000-0000-0000-000000000001','Warum antwortest du nicht sofort?','Eine Person erwartet außerhalb einer dringenden Situation ständige Erreichbarkeit.',8),
  ('41000000-0000-0000-0000-000000000012','40000000-0000-0000-0000-000000000001','Lass uns das unter uns klären, ohne so ein großes Thema daraus zu machen.','Ein wiederholtes Problem soll informell beiseitegeschoben werden.',9),
  ('41000000-0000-0000-0000-000000000013','40000000-0000-0000-0000-000000000001','Alle anderen haben damit kein Problem.','Deine Grenze wird mit dem Verhalten anderer relativiert.',10),
  ('41000000-0000-0000-0000-000000000014','40000000-0000-0000-0000-000000000001','Sei nicht so kompliziert.','Eine klare Rückfrage wird als unnötig schwierig dargestellt.',11),
  ('41000000-0000-0000-0000-000000000015','40000000-0000-0000-0000-000000000001','Ich habe dich doch nur ein bisschen aufgezogen.','Eine abwertende Bemerkung wird nachträglich verharmlost.',12),
  ('41000000-0000-0000-0000-000000000016','40000000-0000-0000-0000-000000000001','Komm, eine Ausnahme kannst du machen.','Nach deinem Nein wird weiter Druck aufgebaut.',13),
  ('41000000-0000-0000-0000-000000000017','40000000-0000-0000-0000-000000000001','Du kannst das doch übernehmen, du bist darin schneller.','Eine Aufgabe wird dir wiederholt aufgrund deiner Verlässlichkeit zugeschoben.',14),
  ('41000000-0000-0000-0000-000000000018','40000000-0000-0000-0000-000000000002','Was genau schlägst du vor?','Eine Gruppe braucht eine konkrete Empfehlung.',2),
  ('41000000-0000-0000-0000-000000000019','40000000-0000-0000-0000-000000000002','Bist du dafür oder dagegen?','Deine Haltung soll kurz erkennbar werden.',3),
  ('41000000-0000-0000-0000-000000000020','40000000-0000-0000-0000-000000000002','Was ist dein wichtigster Einwand?','In einer Diskussion ist wenig Zeit für eine Begründung.',4),
  ('41000000-0000-0000-0000-000000000021','40000000-0000-0000-0000-000000000002','Warum ist das jetzt relevant?','Die Bedeutung deines Punktes ist noch nicht deutlich.',5),
  ('41000000-0000-0000-0000-000000000022','40000000-0000-0000-0000-000000000002','Was soll als Nächstes passieren?','Nach der Diskussion fehlt ein konkreter nächster Schritt.',6),
  ('41000000-0000-0000-0000-000000000023','40000000-0000-0000-0000-000000000002','Kannst du das in einem Satz sagen?','Eine Person bittet um die kürzeste verständliche Fassung.',7),
  ('41000000-0000-0000-0000-000000000024','40000000-0000-0000-0000-000000000002','Welche Option bevorzugst du?','Mehrere plausible Möglichkeiten stehen zur Wahl.',8),
  ('41000000-0000-0000-0000-000000000025','40000000-0000-0000-0000-000000000002','Was überzeugt dich daran?','Deine Empfehlung braucht eine kurze tragende Begründung.',9),
  ('41000000-0000-0000-0000-000000000026','40000000-0000-0000-0000-000000000002','Wo liegt für dich das größte Risiko?','Eine Entscheidung soll mit einem klaren Vorbehalt ergänzt werden.',10),
  ('41000000-0000-0000-0000-000000000027','40000000-0000-0000-0000-000000000002','Was brauchst du für eine Entscheidung?','Die nächsten notwendigen Informationen sollen benannt werden.',11),
  ('41000000-0000-0000-0000-000000000028','40000000-0000-0000-0000-000000000002','Warum reicht der bisherige Weg nicht?','Du sollst den Änderungsbedarf knapp erklären.',12),
  ('41000000-0000-0000-0000-000000000029','40000000-0000-0000-0000-000000000002','Worauf sollten wir uns heute festlegen?','Ein Gespräch braucht einen klaren gemeinsamen Beschlusspunkt.',13),
  ('41000000-0000-0000-0000-000000000030','40000000-0000-0000-0000-000000000002','Was würdest du konkret anders machen?','Deine Kritik soll in eine umsetzbare Alternative übersetzt werden.',14),
  ('43000000-0000-0000-0000-000000000005','42000000-0000-0000-0000-000000000001','You are being too sensitive.','Someone frames your reaction as exaggerated.',2),
  ('43000000-0000-0000-0000-000000000006','42000000-0000-0000-0000-000000000001','Just do this quickly before you go.','An extra task is assigned to you shortly before the end of your workday.',3),
  ('43000000-0000-0000-0000-000000000007','42000000-0000-0000-0000-000000000001','We need you there. This is not up for discussion.','Your attendance is assumed even though you already declined.',4),
  ('43000000-0000-0000-0000-000000000008','42000000-0000-0000-0000-000000000001','I already passed your idea along.','Someone communicated your proposal as the next step without asking you.',5),
  ('43000000-0000-0000-0000-000000000009','42000000-0000-0000-0000-000000000001','Can you move your break?','A last-minute request conflicts with your agreed break.',6),
  ('43000000-0000-0000-0000-000000000010','42000000-0000-0000-0000-000000000001','You just have to put up with it.','Your objection to an inappropriate tone is dismissed.',7),
  ('43000000-0000-0000-0000-000000000011','42000000-0000-0000-0000-000000000001','Why do you not answer immediately?','Someone expects constant availability outside an urgent situation.',8),
  ('43000000-0000-0000-0000-000000000012','42000000-0000-0000-0000-000000000001','Let us keep this between us instead of making it a big issue.','A recurring problem is being pushed aside informally.',9),
  ('43000000-0000-0000-0000-000000000013','42000000-0000-0000-0000-000000000001','Nobody else has a problem with it.','Your boundary is being minimized by comparison with others.',10),
  ('43000000-0000-0000-0000-000000000014','42000000-0000-0000-0000-000000000001','Do not make this so complicated.','A clear question is framed as unnecessarily difficult.',11),
  ('43000000-0000-0000-0000-000000000015','42000000-0000-0000-0000-000000000001','I was only teasing you a little.','A demeaning comment is minimized afterward.',12),
  ('43000000-0000-0000-0000-000000000016','42000000-0000-0000-0000-000000000001','Come on, you can make one exception.','Pressure continues after you have said no.',13),
  ('43000000-0000-0000-0000-000000000017','42000000-0000-0000-0000-000000000001','You can take this on. You are faster at it.','A task is repeatedly shifted to you because you are dependable.',14),
  ('43000000-0000-0000-0000-000000000018','42000000-0000-0000-0000-000000000002','What exactly are you proposing?','A group needs a concrete recommendation.',2),
  ('43000000-0000-0000-0000-000000000019','42000000-0000-0000-0000-000000000002','Are you for it or against it?','Your position needs to become clear quickly.',3),
  ('43000000-0000-0000-0000-000000000020','42000000-0000-0000-0000-000000000002','What is your main objection?','There is little time for an explanation in the discussion.',4),
  ('43000000-0000-0000-0000-000000000021','42000000-0000-0000-0000-000000000002','Why is that relevant now?','The importance of your point is not yet clear.',5),
  ('43000000-0000-0000-0000-000000000022','42000000-0000-0000-0000-000000000002','What should happen next?','The discussion still lacks a concrete next step.',6),
  ('43000000-0000-0000-0000-000000000023','42000000-0000-0000-0000-000000000002','Can you say that in one sentence?','Someone asks for the shortest clear version.',7),
  ('43000000-0000-0000-0000-000000000024','42000000-0000-0000-0000-000000000002','Which option do you prefer?','Several plausible options are available.',8),
  ('43000000-0000-0000-0000-000000000025','42000000-0000-0000-0000-000000000002','What makes that convincing to you?','Your recommendation needs one concise supporting reason.',9),
  ('43000000-0000-0000-0000-000000000026','42000000-0000-0000-0000-000000000002','What is the biggest risk in your view?','A decision needs one clear reservation.',10),
  ('43000000-0000-0000-0000-000000000027','42000000-0000-0000-0000-000000000002','What do you need to make a decision?','The next necessary information should be named.',11),
  ('43000000-0000-0000-0000-000000000028','42000000-0000-0000-0000-000000000002','Why is the current approach not enough?','You need to explain the reason for change briefly.',12),
  ('43000000-0000-0000-0000-000000000029','42000000-0000-0000-0000-000000000002','What should we decide today?','A conversation needs one clear shared decision point.',13),
  ('43000000-0000-0000-0000-000000000030','42000000-0000-0000-0000-000000000002','What would you do differently in concrete terms?','Your criticism should become an actionable alternative.',14)
on conflict (id) do nothing;
