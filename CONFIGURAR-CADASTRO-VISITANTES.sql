-- Cadastro de visitantes realizado pela equipe de recepção.
-- Execute uma única vez no Supabase > SQL Editor.
-- A inserção é permitida somente a usuários autenticados do aplicativo.
-- A consulta e a administração dos registros ficam restritas aos administradores.

create table if not exists public.church_visitor_contacts (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text not null,
  email text,
  congregation_name text not null,
  visit_date date not null,
  visit_type text not null check (visit_type in ('primeira','retorno')),
  contact_consent boolean not null default false,
  consent_at timestamptz,
  registered_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

alter table public.church_visitor_contacts enable row level security;

 drop policy if exists church_visitor_contacts_authenticated_insert on public.church_visitor_contacts;
create policy church_visitor_contacts_authenticated_insert
on public.church_visitor_contacts
for insert to authenticated
with check (auth.uid() = registered_by and contact_consent = true);

drop policy if exists church_visitor_contacts_admin_select on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_select
on public.church_visitor_contacts
for select to authenticated
using (public.can_manage_registration(null));

drop policy if exists church_visitor_contacts_admin_update on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_update
on public.church_visitor_contacts
for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

drop policy if exists church_visitor_contacts_admin_delete on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_delete
on public.church_visitor_contacts
for delete to authenticated
using (public.can_manage_registration(null));

grant insert on public.church_visitor_contacts to authenticated;
grant select, update, delete on public.church_visitor_contacts to authenticated;

comment on table public.church_visitor_contacts is
'Contatos de visitantes cadastrados pela recepção, com autorização expressa para receber comunicações da Igreja.';
