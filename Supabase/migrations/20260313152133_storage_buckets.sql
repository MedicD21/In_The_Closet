insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    (
        'project-photos',
        'project-photos',
        false,
        52428800, -- 50 MiB
        array['image/jpeg', 'image/png', 'image/heic', 'image/heif', 'image/webp']
    ),
    (
        'generated-previews',
        'generated-previews',
        false,
        52428800, -- 50 MiB
        array['image/jpeg', 'image/png', 'image/webp']
    )
on conflict (id) do nothing;

-- Project photos: users can manage their own
create policy "project photos are owner managed"
    on storage.objects
    for all
    to authenticated
    using (
        bucket_id = 'project-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'project-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Generated previews: users can manage their own
create policy "generated previews are owner managed"
    on storage.objects
    for all
    to authenticated
    using (
        bucket_id = 'generated-previews'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'generated-previews'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
