-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- Biblioteca de Estudos para Líderes - versão 52
-- Os estudos publicados ficam disponíveis para download na página principal.
-- Somente administradores autorizados podem inserir, alterar ou excluir estudos.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'leader-studies',
  'leader-studies',
  true,
  20971520,
  array['application/pdf']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 20971520,
  allowed_mime_types = array['application/pdf'];

create table if not exists public.church_leader_studies (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 2 and 140),
  description text not null default '',
  study_date date not null,
  object_path text not null unique,
  uploaded_by uuid not null references auth.users(id),
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists church_leader_studies_date_idx
  on public.church_leader_studies (study_date desc, created_at desc);

alter table public.church_leader_studies enable row level security;

revoke all on public.church_leader_studies from anon, authenticated;
grant select on public.church_leader_studies to anon, authenticated;
grant insert, update, delete on public.church_leader_studies to authenticated;

drop policy if exists church_leader_studies_public_read on public.church_leader_studies;
create policy church_leader_studies_public_read
on public.church_leader_studies
for select to anon, authenticated
using (published = true);

drop policy if exists church_leader_studies_admin_read on public.church_leader_studies;
create policy church_leader_studies_admin_read
on public.church_leader_studies
for select to authenticated
using (public.can_manage_registration(null));

drop policy if exists church_leader_studies_admin_insert on public.church_leader_studies;
create policy church_leader_studies_admin_insert
on public.church_leader_studies
for insert to authenticated
with check (
  public.can_manage_registration(null)
  and uploaded_by = auth.uid()
  and char_length(trim(title)) between 2 and 140
);

drop policy if exists church_leader_studies_admin_update on public.church_leader_studies;
create policy church_leader_studies_admin_update
on public.church_leader_studies
for update to authenticated
using (public.can_manage_registration(null))
with check (public.can_manage_registration(null));

drop policy if exists church_leader_studies_admin_delete on public.church_leader_studies;
create policy church_leader_studies_admin_delete
on public.church_leader_studies
for delete to authenticated
using (public.can_manage_registration(null));

-- Somente administradores podem enviar ou remover PDFs no bucket.
drop policy if exists leader_studies_admin_insert on storage.objects;
create policy leader_studies_admin_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'leader-studies'
  and public.can_manage_registration(null)
);

drop policy if exists leader_studies_admin_update on storage.objects;
create policy leader_studies_admin_update
on storage.objects
for update to authenticated
using (bucket_id = 'leader-studies' and public.can_manage_registration(null))
with check (bucket_id = 'leader-studies' and public.can_manage_registration(null));

drop policy if exists leader_studies_admin_delete on storage.objects;
create policy leader_studies_admin_delete
on storage.objects
for delete to authenticated
using (bucket_id = 'leader-studies' and public.can_manage_registration(null));
