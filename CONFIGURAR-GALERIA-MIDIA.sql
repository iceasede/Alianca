-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- Galeria privada de fotos dos cultos - versão 46
-- Bucket privado: membros autenticados podem visualizar/baixar;
-- somente administradores autorizados podem publicar ou excluir.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cultos-fotos', 'cultos-fotos', false, 15728640, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = false,
  file_size_limit = 15728640,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

create table if not exists public.church_media_photos (
  id uuid primary key default gen_random_uuid(),
  event_date date not null,
  event_title text not null check (char_length(trim(event_title)) between 2 and 100),
  object_path text not null unique,
  uploaded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists church_media_photos_event_date_idx
  on public.church_media_photos (event_date desc, created_at desc);

alter table public.church_media_photos enable row level security;
revoke all on public.church_media_photos from anon;
grant select on public.church_media_photos to authenticated;
grant insert, delete on public.church_media_photos to authenticated;

drop policy if exists church_media_members_read on public.church_media_photos;
create policy church_media_members_read
on public.church_media_photos for select to authenticated
using (auth.uid() is not null);

drop policy if exists church_media_admin_insert on public.church_media_photos;
create policy church_media_admin_insert
on public.church_media_photos for insert to authenticated
with check (
  public.can_manage_registration(null)
  and uploaded_by = auth.uid()
  and char_length(trim(event_title)) between 2 and 100
);

drop policy if exists church_media_admin_delete on public.church_media_photos;
create policy church_media_admin_delete
on public.church_media_photos for delete to authenticated
using (public.can_manage_registration(null));

-- Storage: leitura/visualização/baixa para membros autenticados.
drop policy if exists church_media_storage_member_read on storage.objects;
create policy church_media_storage_member_read
on storage.objects for select to authenticated
using (bucket_id = 'cultos-fotos' and auth.uid() is not null);

-- Somente administradores autorizados podem enviar, substituir ou excluir arquivos.
drop policy if exists church_media_storage_admin_insert on storage.objects;
create policy church_media_storage_admin_insert
on storage.objects for insert to authenticated
with check (bucket_id = 'cultos-fotos' and public.can_manage_registration(null));

drop policy if exists church_media_storage_admin_update on storage.objects;
create policy church_media_storage_admin_update
on storage.objects for update to authenticated
using (bucket_id = 'cultos-fotos' and public.can_manage_registration(null))
with check (bucket_id = 'cultos-fotos' and public.can_manage_registration(null));

drop policy if exists church_media_storage_admin_delete on storage.objects;
create policy church_media_storage_admin_delete
on storage.objects for delete to authenticated
using (bucket_id = 'cultos-fotos' and public.can_manage_registration(null));
