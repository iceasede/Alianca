-- Igreja Comunidade Evangélica da Aliança | Solicitações de contato para células
-- Execute uma única vez no Supabase > SQL Editor.
-- A política permite apenas INSERT público; não há SELECT/UPDATE/DELETE para anon.

create table if not exists public.cell_contact_requests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  phone text not null check (char_length(trim(phone)) between 8 and 30),
  cell_region text not null check (cell_region in ('Setor Norte','Setor Veredas','Vila São José','Chapadinha','Águas Lindas/GO','Ceilândia')),
  congregation_name text not null default 'Sede — Brazlândia/DF',
  status text not null default 'pendente' check (status in ('pendente','em_contato','concluido')),
  created_at timestamptz not null default now()
);

alter table public.cell_contact_requests enable row level security;
revoke all on table public.cell_contact_requests from anon, authenticated;
grant insert on table public.cell_contact_requests to anon, authenticated;

drop policy if exists cell_contact_requests_public_insert on public.cell_contact_requests;
create policy cell_contact_requests_public_insert
  on public.cell_contact_requests
  for insert to anon, authenticated
  with check (
    char_length(trim(full_name)) between 2 and 120
    and char_length(trim(phone)) between 8 and 30
    and cell_region in ('Setor Norte','Setor Veredas','Vila São José','Chapadinha','Águas Lindas/GO','Ceilândia')
    and congregation_name = 'Sede — Brazlândia/DF'
    and status = 'pendente'
  );

-- Não crie política de SELECT público. As solicitações contêm dados pessoais.
