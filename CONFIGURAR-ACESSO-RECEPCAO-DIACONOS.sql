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

