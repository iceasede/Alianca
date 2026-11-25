-- IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA
-- Restringe a exclusão de fotos exclusivamente à super administradora.
-- A visualização continua disponível para todos os usuários autenticados.

drop policy if exists church_media_admin_delete on public.church_media_photos;
create policy church_media_admin_delete
on public.church_media_photos
for delete to authenticated
using (
  exists (
    select 1
    from public.admin_roles ar
    where ar.user_id = auth.uid()
      and ar.role = 'super_admin'
  )
);

drop policy if exists church_media_storage_admin_delete on storage.objects;
create policy church_media_storage_admin_delete
on storage.objects
for delete to authenticated
using (
  bucket_id = 'cultos-fotos'
  and exists (
    select 1
    from public.admin_roles ar
    where ar.user_id = auth.uid()
      and ar.role = 'super_admin'
  )
);
