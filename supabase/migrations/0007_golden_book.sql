create or replace function public.normalize_golden_phrase(value text)
returns text
language sql
immutable
set search_path = public
as $$
  select trim(both ' .,!?:;"„“‚‘’' from lower(regexp_replace(trim(value), '\s+', ' ', 'g')))
$$;

alter table public.golden_book_entries
  add column normalized_phrase text not null default '',
  add column model_meta jsonb not null default '{}'::jsonb;

create or replace function public.set_normalized_golden_phrase()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.phrase := trim(new.phrase);
  new.normalized_phrase := public.normalize_golden_phrase(new.phrase);
  if new.normalized_phrase = '' then
    raise exception 'Golden Book phrase cannot be empty';
  end if;
  return new;
end;
$$;

create trigger golden_book_normalize_phrase
before insert or update of phrase on public.golden_book_entries
for each row execute function public.set_normalized_golden_phrase();

create unique index golden_book_user_normalized_phrase_key
  on public.golden_book_entries(user_id, normalized_phrase);

drop policy "golden book own" on public.golden_book_entries;
create policy "golden book own read" on public.golden_book_entries
  for select using (user_id = auth.uid());
create policy "golden book own insert" on public.golden_book_entries
  for insert with check (
    user_id = auth.uid()
    and (source_session_id is null or exists (
      select 1 from public.training_sessions session
      where session.id = source_session_id and session.user_id = auth.uid()
    ))
  );
create policy "golden book own update" on public.golden_book_entries
  for update using (user_id = auth.uid()) with check (
    user_id = auth.uid()
    and (source_session_id is null or exists (
      select 1 from public.training_sessions session
      where session.id = source_session_id and session.user_id = auth.uid()
    ))
  );
create policy "golden book own delete" on public.golden_book_entries
  for delete using (user_id = auth.uid());
