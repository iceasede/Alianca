-- Igreja Comunidade Evangélica da Aliança | Versão 44
-- Execute no Supabase SQL Editor. Pode ser executado novamente com segurança.

create table if not exists public.cell_contact_requests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text not null,
  cell_region text not null,
  congregation_name text not null,
  status text not null default 'pendente',
  created_at timestamptz not null default now()
);

alter table public.cell_contact_requests add column if not exists congregation_name text;
alter table public.cell_contact_requests add column if not exists cell_region text;
alter table public.cell_contact_requests add column if not exists status text not null default 'pendente';

-- Atualiza restrições antigas da versão 43 para aceitar as três congregações e regiões digitadas.
alter table public.cell_contact_requests drop constraint if exists cell_contact_requests_cell_region_check;
alter table public.cell_contact_requests drop constraint if exists cell_contact_requests_congregation_name_check;
alter table public.cell_contact_requests drop constraint if exists cell_contact_requests_status_check;
alter table public.cell_contact_requests
  add constraint cell_contact_requests_region_length_check check (char_length(trim(cell_region)) between 2 and 100),
  add constraint cell_contact_requests_congregation_check check (congregation_name in ('Sede — Brazlândia/DF','Jardim Botânico/DF','Vendinha/GO')),
  add constraint cell_contact_requests_status_check check (status in ('pendente','encaminhada','concluido'));

-- Converte registros anteriores da versão 43 para o novo formato.
update public.cell_contact_requests set congregation_name='Sede — Brazlândia/DF' where congregation_name is null or trim(congregation_name)='';
update public.cell_contact_requests set status='pendente' where status is null or status not in ('pendente','encaminhada','concluido');

alter table public.cell_contact_requests enable row level security;
revoke all on table public.cell_contact_requests from anon, authenticated;
grant insert on table public.cell_contact_requests to anon, authenticated;
grant select, update on table public.cell_contact_requests to authenticated;

drop policy if exists cell_contact_requests_public_insert on public.cell_contact_requests;
create policy cell_contact_requests_public_insert
  on public.cell_contact_requests for insert to anon, authenticated
  with check (
    char_length(trim(full_name)) between 2 and 120
    and char_length(trim(phone)) between 8 and 30
    and char_length(trim(cell_region)) between 2 and 100
    and congregation_name in ('Sede — Brazlândia/DF','Jardim Botânico/DF','Vendinha/GO')
    and status = 'pendente'
  );

drop policy if exists cell_contact_requests_admin_read on public.cell_contact_requests;
create policy cell_contact_requests_admin_read
  on public.cell_contact_requests for select to authenticated
  using (public.can_manage_registration(null));

drop policy if exists cell_contact_requests_admin_update on public.cell_contact_requests;
create policy cell_contact_requests_admin_update
  on public.cell_contact_requests for update to authenticated
  using (public.can_manage_registration(null))
  with check (public.can_manage_registration(null) and status in ('pendente','encaminhada','concluido'));

-- Não existe leitura pública: somente usuários autenticados com permissão administrativa
-- podem consultar e atualizar as solicitações.
