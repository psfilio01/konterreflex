create or replace function public.is_valid_feedback_dimension_signals(
  signals jsonb
)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    when jsonb_typeof(signals) <> 'object' then false
    else (
      select count(*) = 6
        and bool_and(key in (
          'posture',
          'precision',
          'frame',
          'social_effect',
          'naturalness',
          'escalation_fit'
        ))
        and bool_and(value in ('strong', 'developing', 'focus'))
      from jsonb_each_text(signals)
    )
  end;
$$;

alter table public.feedback
  add column overall_signal text not null default 'developing'
    check (overall_signal in ('strong', 'developing', 'focus')),
  add column dimension_signals jsonb not null default '{
    "posture": "developing",
    "precision": "developing",
    "frame": "developing",
    "social_effect": "developing",
    "naturalness": "developing",
    "escalation_fit": "developing"
  }'::jsonb
    check (public.is_valid_feedback_dimension_signals(dimension_signals));
