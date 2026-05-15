-- Rasa Nusantara · reader star ratings
-- Paste this once into the Supabase SQL editor for project wltoejicaqvwnmrengsi.

create table if not exists public.recipe_ratings (
  id          bigserial primary key,
  recipe_id   text       not null,
  rating      smallint   not null check (rating between 1 and 5),
  created_at  timestamptz not null default now()
);

create index if not exists recipe_ratings_recipe_id_idx
  on public.recipe_ratings (recipe_id);

alter table public.recipe_ratings enable row level security;

-- Anyone can submit a rating; the CHECK clamps it to 1..5
drop policy if exists "rate_insert_anyone" on public.recipe_ratings;
create policy "rate_insert_anyone"
  on public.recipe_ratings
  for insert
  to anon, authenticated
  with check (rating between 1 and 5);

-- Reads are open (the rows contain no PII; we only render aggregates)
drop policy if exists "rate_select_anyone" on public.recipe_ratings;
create policy "rate_select_anyone"
  on public.recipe_ratings
  for select
  to anon, authenticated
  using (true);

-- Aggregate function used by the front-end on page load
create or replace function public.get_recipe_rating_summary()
returns table(recipe_id text, votes bigint, average numeric)
language sql
stable
security invoker
as $$
  select
    recipe_id,
    count(*)::bigint                 as votes,
    round(avg(rating)::numeric, 2)   as average
  from public.recipe_ratings
  group by recipe_id;
$$;

grant execute on function public.get_recipe_rating_summary() to anon, authenticated;
