alter table public.feedback
  add column strengths jsonb not null default '[]'::jsonb,
  add column improvement text not null default '';

create unique index feedback_response_id_key on public.feedback(response_id);

create policy "feedback own insert"
  on public.feedback
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.user_responses response
      where response.id = response_id and response.user_id = auth.uid()
    )
  );

create policy "feedback own update"
  on public.feedback
  for update
  using (
    user_id = auth.uid()
    and exists (
      select 1 from public.user_responses response
      where response.id = response_id and response.user_id = auth.uid()
    )
  )
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.user_responses response
      where response.id = response_id and response.user_id = auth.uid()
    )
  );
