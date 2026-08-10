begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

select ok(
  exists(
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'feedback' and column_name = 'strengths'
  ),
  'feedback stores explicit qualitative strengths'
);

select ok(
  public.is_valid_feedback_dimension_signals('{
    "posture":"strong",
    "precision":"developing",
    "frame":"developing",
    "social_effect":"strong",
    "naturalness":"strong",
    "escalation_fit":"focus"
  }'::jsonb),
  'categorical feedback signals accept the six qualitative dimensions'
);

select ok(
  not public.is_valid_feedback_dimension_signals('{
    "posture":"5",
    "precision":"developing"
  }'::jsonb),
  'numeric or incomplete dimension signals are rejected'
);

select ok(
  not exists(
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'feedback'
      and column_name in ('score', 'rating', 'points', 'percentage')
  ),
  'feedback schema contains no numeric scoring field'
);

select * from finish();
rollback;
