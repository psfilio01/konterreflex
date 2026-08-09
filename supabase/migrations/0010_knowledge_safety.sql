create type public.evidence_status as enum ('empirical_supported','mixed','practice_based','historical','speculative');
create type public.safety_decision as enum ('pass','needs_review','block');

create table public.communication_knowledge (
  id uuid primary key default gen_random_uuid(),
  logical_id uuid not null default gen_random_uuid(),
  version integer not null check (version > 0),
  source text not null,
  author text not null,
  concept text not null,
  intended_use text not null,
  evidence_status public.evidence_status not null,
  limitations text not null,
  active boolean not null default true,
  supersedes_id uuid references public.communication_knowledge(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique(logical_id,version)
);
alter table public.communication_knowledge enable row level security;
create policy "admin knowledge read" on public.communication_knowledge for select using (public.is_admin());
create policy "admin knowledge insert" on public.communication_knowledge for insert with check (public.is_admin() and created_by = auth.uid());
create policy "admin knowledge archive" on public.communication_knowledge for update using (public.is_admin()) with check (public.is_admin());

create or replace function public.protect_knowledge_version()
returns trigger language plpgsql set search_path = public as $$
begin
  if row(new.source,new.author,new.concept,new.intended_use,new.evidence_status,new.limitations,new.version,new.logical_id)
     is distinct from
     row(old.source,old.author,old.concept,old.intended_use,old.evidence_status,old.limitations,old.version,old.logical_id) then
    raise exception 'Knowledge content is immutable; create a new version';
  end if;
  return new;
end;
$$;
create trigger knowledge_versions_are_immutable before update on public.communication_knowledge
for each row execute function public.protect_knowledge_version();

create or replace function public.admin_create_knowledge_version(
  p_previous_id uuid,
  p_source text,
  p_author text,
  p_concept text,
  p_intended_use text,
  p_evidence_status public.evidence_status,
  p_limitations text
)
returns uuid language plpgsql set search_path = public as $$
declare
  previous public.communication_knowledge;
  next_id uuid;
  next_logical_id uuid;
  next_version integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_previous_id is null then
    next_logical_id := gen_random_uuid();
    next_version := 1;
  else
    select * into strict previous from public.communication_knowledge where id = p_previous_id;
    update public.communication_knowledge set active = false where id = p_previous_id;
    next_logical_id := previous.logical_id;
    next_version := previous.version + 1;
  end if;
  insert into public.communication_knowledge (
    logical_id,version,source,author,concept,intended_use,evidence_status,
    limitations,active,supersedes_id,created_by
  ) values (
    next_logical_id,next_version,trim(p_source),trim(p_author),trim(p_concept),
    trim(p_intended_use),p_evidence_status,trim(p_limitations),true,p_previous_id,auth.uid()
  ) returning id into next_id;
  return next_id;
end;
$$;
revoke all on function public.admin_create_knowledge_version(uuid,text,text,text,text,public.evidence_status,text) from public, anon, authenticated;
grant execute on function public.admin_create_knowledge_version(uuid,text,text,text,text,public.evidence_status,text) to authenticated;

alter table public.scenarios add column content_revision integer not null default 1;

create table public.scenario_safety_reviews (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid not null references public.scenarios(id) on delete cascade,
  content_revision integer not null,
  decision public.safety_decision not null,
  findings jsonb not null default '[]'::jsonb,
  rationale text not null,
  hostile_content_as_training boolean not null default false,
  protected_trait_linkage boolean not null default false,
  stereotype_risk boolean not null default false,
  provider text not null,
  model text not null,
  prompt_version text not null,
  reviewed_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);
alter table public.scenario_safety_reviews enable row level security;
create policy "admin safety review read" on public.scenario_safety_reviews for select using (public.is_admin());
create policy "admin safety review insert" on public.scenario_safety_reviews for insert with check (public.is_admin() and reviewed_by = auth.uid());

create or replace function public.bump_scenario_content_revision()
returns trigger language plpgsql set search_path = public as $$
begin
  if row(new.title,new.category,new.context,new.moderator_intro,new.trigger_statement,new.underlying_intent,new.evaluation_focus)
     is distinct from
     row(old.title,old.category,old.context,old.moderator_intro,old.trigger_statement,old.underlying_intent,old.evaluation_focus) then
    new.content_revision := old.content_revision + 1;
  end if;
  return new;
end;
$$;
create trigger scenario_content_revision before update on public.scenarios
for each row execute function public.bump_scenario_content_revision();

create or replace function public.invalidate_scenario_safety_from_child()
returns trigger language plpgsql set search_path = public as $$
begin
  update public.scenarios
  set content_revision = content_revision + 1, status = 'draft'
  where id = new.scenario_id;
  return new;
end;
$$;
create trigger scenario_character_invalidates_review
after insert or update on public.scenario_characters
for each row execute function public.invalidate_scenario_safety_from_child();
create trigger scenario_turn_invalidates_review
after insert or update on public.scenario_turns
for each row execute function public.invalidate_scenario_safety_from_child();

create or replace function public.require_scenario_safety_review()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.status = 'active' and old.status is distinct from 'active' and not exists (
    select 1 from public.scenario_safety_reviews review
    where review.scenario_id = new.id
      and review.content_revision = new.content_revision
      and review.decision = 'pass'
  ) then
    raise exception 'Current scenario revision has no passed safety review';
  end if;
  return new;
end;
$$;
create trigger scenario_requires_safety_review before update of status on public.scenarios
for each row execute function public.require_scenario_safety_review();
