-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- VERSÃO 64 - CONSULTA SEGURA DE ANIVERSARIANTES
-- Retorna somente nome e dia/mês, sem expor ano de nascimento ou outros dados pessoais.

create or replace function public.get_church_birthdays()
returns table (
  full_name text,
  birth_day integer,
  birth_month integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.full_name::text,
    extract(day from p.birth_date)::integer as birth_day,
    extract(month from p.birth_date)::integer as birth_month
  from public.profiles p
  where auth.uid() is not null
    and p.birth_date is not null
    and coalesce(trim(p.full_name), '') <> ''
  order by
    extract(month from p.birth_date),
    extract(day from p.birth_date),
    p.full_name;
$$;

revoke all on function public.get_church_birthdays() from public;
revoke all on function public.get_church_birthdays() from anon;
grant execute on function public.get_church_birthdays() to authenticated;

notify pgrst, 'reload schema';
