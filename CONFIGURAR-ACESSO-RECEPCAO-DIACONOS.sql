-- VERSAO 62 - FUNCAO DIACONO(A) E ACESSO RESTRITO AO CADASTRO DE VISITANTES
-- Execute uma vez no Supabase > SQL Editor. Mantem os cadastros existentes.

-- Permite que a administracao aprove a nova funcao Diacono(a).
-- A tabela church_role_requests nao possui constraint de funcao nesta instalacao.

-- Atualiza o gatilho de novos cadastros para reconhecer a funcao diacono.
create or replace function public.capture_church_role_request()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  requested text;
begin
  requested := coalesce(new.raw_user_meta_data->>'church_role_requested','membro');
  if requested not in ('membro','lider_celula','pastor','apostolo','diacono') then
    requested := 'membro';
  end if;
  insert into public.church_role_requests
    (user_id, full_name, requested_role, status, approved_role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), requested,
    case when requested = 'membro' then 'aprovado' else 'pendente' end, null)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- Apenas Apóstolos, Pastores e Diáconos com função aprovada podem cadastrar visitantes.
drop policy if exists church_visitor_contacts_authenticated_insert on public.church_visitor_contacts;
create policy church_visitor_contacts_authorized_insert
on public.church_visitor_contacts
for insert to authenticated
with check (
  auth.uid() = registered_by
  and contact_consent = true
  and public.current_approved_church_role() in ('apostolo','pastor','diacono')
);


-- VERSÃO 63 - GESTÃO E ACOMPANHAMENTO DE VISITANTES
-- Executar após a configuração inicial da recepção.

-- Campos de acompanhamento: pendente, encaminhado ou concluído.
alter table public.church_visitor_contacts
  add column if not exists followup_status text not null default 'pendente',
  add column if not exists followup_notes text,
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists completed_at timestamptz;

alter table public.church_visitor_contacts
  drop constraint if exists church_visitor_contacts_followup_status_check;
alter table public.church_visitor_contacts
  add constraint church_visitor_contacts_followup_status_check
  check (followup_status in ('pendente','encaminhado','concluido'));

-- Administradores também podem cadastrar visitantes, além de apóstolos,
-- pastores e diáconos com função aprovada.
drop policy if exists church_visitor_contacts_authorized_insert
  on public.church_visitor_contacts;
create policy church_visitor_contacts_authorized_insert
on public.church_visitor_contacts
for insert to authenticated
with check (
  auth.uid() = registered_by
  and contact_consent = true
  and (
    public.can_manage_registration(null)
    or public.current_approved_church_role() in ('apostolo','pastor','diacono')
  )
);

-- Leitura, atualização e exclusão pela administração autorizada.
drop policy if exists church_visitor_contacts_admin_select
  on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_select
on public.church_visitor_contacts
for select to authenticated
using (public.can_manage_registration(null));

drop policy if exists church_visitor_contacts_admin_update
  on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_update
on public.church_visitor_contacts
for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

drop policy if exists church_visitor_contacts_admin_delete
  on public.church_visitor_contacts;
create policy church_visitor_contacts_admin_delete
on public.church_visitor_contacts
for delete to authenticated
using (public.can_manage_registration(null));

grant select, insert, update, delete
on public.church_visitor_contacts to authenticated;
