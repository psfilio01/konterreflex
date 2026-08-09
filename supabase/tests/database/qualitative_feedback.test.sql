begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

select ok(
  exists(
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'feedback' and column_name = 'strengths'
  ),
  'feedback stores explicit qualitative strengths'
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
