-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- VERSÃO 54 - integração das solicitações de função e acesso aos estudos
-- Execute UMA vez no Supabase SQL Editor. Não apaga cadastros nem estudos.

-- A. Garantir campos usados pela aplicação
alter table public.church_role_requests
  add column if not exists full_name text not null default '',
  add column if not exists requested_role text not null default 'membro',
  add column if not exists approved_role text,
  add column if not exists status text not null default 'pendente',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists reviewed_by uuid references auth.users(id),
  add column if not exists reviewed_at timestamptz;

-- A tabela foi criada antes da integração. Cadastrar usuários existentes
-- com base na função que já escolheram no formulário de inscrição.
insert into public.church_role_requests
  (user_id, full_name, requested_role, status, approved_role)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'full_name',''),
  case
    when u.raw_user_meta_data->>'church_role_requested'
      in ('lider_celula','pastor','apostolo')
    then u.raw_user_meta_data->>'church_role_requested'
    else 'membro'
  end,
  case
    when u.raw_user_meta_data->>'church_role_requested'
      in ('lider_celula','pastor','apostolo')
    then 'pendente'
    else 'aprovado'
  end,
  null
from auth.users u
on conflict (user_id) do nothing;

-- B. Criar registro automaticamente para cada nova conta.
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

  if requested not in ('membro','lider_celula','pastor','apostolo') then
    requested := 'membro';
  end if;

  insert into public.church_role_requests
    (user_id, full_name, requested_role, status, approved_role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    requested,
    case when requested = 'membro' then 'aprovado' else 'pendente' end,
    null
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_church_role on auth.users;
create trigger on_auth_user_created_church_role
after insert on auth.users
for each row execute function public.capture_church_role_request();

-- C. Permissões da tabela de solicitações.
alter table public.church_role_requests enable row level security;
revoke all on public.church_role_requests from anon, authenticated;
grant select, update on public.church_role_requests to authenticated;

drop policy if exists church_role_requests_read_self_or_admin
  on public.church_role_requests;
create policy church_role_requests_read_self_or_admin
on public.church_role_requests
for select to authenticated
using (
  auth.uid() = user_id
  or public.can_manage_registration(null)
);

drop policy if exists church_role_requests_admin_update
  on public.church_role_requests;
create policy church_role_requests_admin_update
on public.church_role_requests
for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

-- D. Função segura para consultar a função efetivamente aprovada.
create or replace function public.current_approved_church_role()
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select r.approved_role
  from public.church_role_requests r
  where r.user_id = auth.uid()
    and r.status = 'aprovado'
  limit 1;
$$;

revoke all on function public.current_approved_church_role() from public, anon;
grant execute on function public.current_approved_church_role() to authenticated;

-- E. Estudos: categorias e leitura somente para funções aprovadas.
alter table public.church_leader_studies
  add column if not exists category text not null default 'lideres';

alter table public.church_leader_studies
  drop constraint if exists church_leader_studies_category_check;
alter table public.church_leader_studies
  add constraint church_leader_studies_category_check
  check (category in ('lideres','pastoral'));

alter table public.church_leader_studies enable row level security;
revoke all on public.church_leader_studies from anon;
grant select, insert, update, delete
  on public.church_leader_studies to authenticated;

drop policy if exists church_leader_studies_public_read
  on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_read
  on public.church_leader_studies;
drop policy if exists church_leader_studies_role_read
  on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_insert
  on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_update
  on public.church_leader_studies;
drop policy if exists church_leader_studies_admin_delete
  on public.church_leader_studies;

create policy church_leader_studies_role_read
on public.church_leader_studies
for select to authenticated
using (
  public.can_manage_registration(null)
  or (
    published = true
    and (
      (category = 'lideres'
       and public.current_approved_church_role()
           in ('lider_celula','pastor','apostolo'))
      or
      (category = 'pastoral'
       and public.current_approved_church_role()
           in ('pastor','apostolo'))
    )
  )
);

create policy church_leader_studies_admin_insert
on public.church_leader_studies
for insert to authenticated
with check (
  public.can_manage_registration(null)
  and uploaded_by = auth.uid()
);

create policy church_leader_studies_admin_update
on public.church_leader_studies
for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

create policy church_leader_studies_admin_delete
on public.church_leader_studies
for delete to authenticated
using (public.can_manage_registration(null));

-- F. Storage privado. A galeria de fotos não é alterada.
update storage.buckets
set public = false,
    file_size_limit = 20971520,
    allowed_mime_types = array['application/pdf']
where id = 'leader-studies';

drop policy if exists leader_studies_admin_insert on storage.objects;
drop policy if exists leader_studies_admin_update on storage.objects;
drop policy if exists leader_studies_admin_delete on storage.objects;
drop policy if exists leader_studies_member_read on storage.objects;
drop policy if exists leader_studies_role_read on storage.objects;

create policy leader_studies_role_read
on storage.objects
for select to authenticated
using (
  bucket_id = 'leader-studies'
  and (
    public.can_manage_registration(null)
    or exists (
      select 1
      from public.church_leader_studies s
      where s.object_path = name
        and s.published = true
    )
  )
);

create policy leader_studies_admin_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'leader-studies'
  and public.can_manage_registration(null)
);

create policy leader_studies_admin_update
on storage.objects
for update to authenticated
using (
  bucket_id = 'leader-studies'
  and public.can_manage_registration(null)
)
with check (
  bucket_id = 'leader-studies'
  and public.can_manage_registration(null)
);

create policy leader_studies_admin_delete
on storage.objects
for delete to authenticated
using (
  bucket_id = 'leader-studies'
  and public.can_manage_registration(null)
);

notify pgrst, 'reload schema';
