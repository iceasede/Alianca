-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- Versão 53: funções com aprovação e estudos por nível
-- Execute no Supabase SQL Editor, após publicar a versão 53.

-- 1) Solicitações de função: a escolha feita no cadastro NÃO concede acesso.
create table if not exists public.church_role_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  requested_role text not null check (requested_role in ('membro','lider_celula','pastor','apostolo')),
  approved_role text check (approved_role in ('lider_celula','pastor','apostolo')),
  status text not null default 'pendente' check (status in ('pendente','aprovado','recusado')),
  created_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz
);

alter table public.church_role_requests enable row level security;
revoke all on public.church_role_requests from anon, authenticated;
grant select on public.church_role_requests to authenticated;
grant update on public.church_role_requests to authenticated;

drop policy if exists church_role_requests_read_self_or_admin on public.church_role_requests;
create policy church_role_requests_read_self_or_admin
on public.church_role_requests for select to authenticated
using (auth.uid() = user_id or public.can_manage_registration(null));

drop policy if exists church_role_requests_admin_update on public.church_role_requests;
create policy church_role_requests_admin_update
on public.church_role_requests for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

-- Cria/atualiza a solicitação automaticamente quando uma conta é criada.
create or replace function public.capture_church_role_request()
returns trigger language plpgsql security definer set search_path = public, auth
as $$
declare requested text;
begin
  requested := coalesce(new.raw_user_meta_data->>'church_role_requested','membro');
  if requested not in ('membro','lider_celula','pastor','apostolo') then requested := 'membro'; end if;
  insert into public.church_role_requests(user_id,full_name,requested_role,status,approved_role)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),requested,
    case when requested='membro' then 'aprovado' else 'pendente' end,
    case when requested='membro' then null else null end)
  on conflict(user_id) do update set
    full_name=excluded.full_name,
    requested_role=excluded.requested_role,
    status=case when excluded.requested_role='membro' then 'aprovado' else 'pendente' end,
    approved_role=null,
    reviewed_by=null,
    reviewed_at=null;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_church_role on auth.users;
create trigger on_auth_user_created_church_role
after insert on auth.users for each row execute function public.capture_church_role_request();

-- 2) Tabela de estudos: adicionar categoria e restringir leitura a funções aprovadas.
alter table public.church_leader_studies
  add column if not exists category text not null default 'lideres';

alter table public.church_leader_studies
  drop constraint if exists church_leader_studies_category_check;
alter table public.church_leader_studies
  add constraint church_leader_studies_category_check
  check (category in ('lideres','pastoral'));

-- O bucket precisa ser privado. PDFs antigos continuam armazenados, mas deixam de ser públicos.
update storage.buckets set public=false, file_size_limit=20971520,
  allowed_mime_types=array['application/pdf'] where id='leader-studies';

revoke all on public.church_leader_studies from anon;
grant select, insert, update, delete on public.church_leader_studies to authenticated;

drop policy if exists church_leader_studies_public_read on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_read on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_insert on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_update on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_delete on public.church_leader_studies;

create or replace function public.current_approved_church_role()
returns text language sql stable security definer set search_path=public,auth
as $$
  select approved_role from public.church_role_requests
  where user_id=auth.uid() and status='aprovado' limit 1;
$$;

create policy church_leader_studies_role_read
on public.church_leader_studies for select to authenticated
using (
  public.can_manage_registration(null)
  or (published=true and (
    (category='lideres' and public.current_approved_church_role() in ('lider_celula','pastor','apostolo'))
    or (category='pastoral' and public.current_approved_church_role() in ('pastor','apostolo'))
  ))
);

create policy church_leader_studies_admin_insert
on public.church_leader_studies for insert to authenticated
with check (public.can_manage_registration(null) and uploaded_by=auth.uid());
create policy church_leader_studies_admin_update
on public.church_leader_studies for update to authenticated
using (public.can_manage_registration(null)) with check (public.can_manage_registration(null));
create policy church_leader_studies_admin_delete
on public.church_leader_studies for delete to authenticated
using (public.can_manage_registration(null));

-- 3) A leitura do Storage só é permitida se o usuário puder ler o registro do estudo.
drop policy if exists leader_studies_admin_insert on storage.objects;
drop policy if exists leader_studies_admin_update on storage.objects;
drop policy if exists leader_studies_admin_delete on storage.objects;
drop policy if exists leader_studies_member_read on storage.objects;
drop policy if exists leader_studies_role_read on storage.objects;

create policy leader_studies_role_read
on storage.objects for select to authenticated
using (
  bucket_id='leader-studies'
  and (
    public.can_manage_registration(null)
    or exists (
      select 1 from public.church_leader_studies s
      where s.object_path=name and s.published=true
    )
  )
);
create policy leader_studies_admin_insert
on storage.objects for insert to authenticated
with check (bucket_id='leader-studies' and public.can_manage_registration(null));
create policy leader_studies_admin_update
on storage.objects for update to authenticated
using (bucket_id='leader-studies' and public.can_manage_registration(null))
with check (bucket_id='leader-studies' and public.can_manage_registration(null));
create policy leader_studies_admin_delete
on storage.objects for delete to authenticated
using (bucket_id='leader-studies' and public.can_manage_registration(null));

-- 4) Acesso aos registros da função: apenas a própria pessoa ou administração.
-- Não há política de INSERT do cliente; o trigger cria o registro com segurança.
