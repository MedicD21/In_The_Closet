create extension if not exists "pgcrypto";

create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    email text,
    display_name text,
    avatar_url text,
    preferred_theme text default 'system',
    preferred_tone text default 'warm',
    onboarding_completed boolean default false,
    created_at timestamptz default timezone('utc', now()),
    updated_at timestamptz default timezone('utc', now())
);

create table if not exists public.projects (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    title text not null,
    space_type text not null,
    custom_space_name text,
    mode text not null,
    status text not null default 'draft',
    current_score integer,
    created_at timestamptz default timezone('utc', now()),
    updated_at timestamptz default timezone('utc', now()),
    archived_at timestamptz
);

create table if not exists public.project_images (
    id uuid primary key default gen_random_uuid(),
    project_id uuid not null references public.projects (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
    image_type text not null,
    storage_path text not null,
    public_url text,
    created_at timestamptz default timezone('utc', now())
);

create table if not exists public.analyses (
    id uuid primary key default gen_random_uuid(),
    project_id uuid not null references public.projects (id) on delete cascade,
    provider_primary text not null,
    provider_secondary text,
    raw_input_summary text,
    total_score integer not null,
    clutter_score integer not null,
    accessibility_score integer not null,
    zoning_score integer not null,
    visibility_score integer not null,
    shelf_efficiency_score integer not null,
    visual_calm_score integer not null,
    staging_readiness_score integer not null,
    summary_text text,
    supportive_coaching_text text,
    reset_plan_json jsonb,
    estimated_reset_minutes integer,
    confidence_notes_json jsonb,
    created_at timestamptz default timezone('utc', now())
);

create table if not exists public.recommendations (
    id uuid primary key default gen_random_uuid(),
    analysis_id uuid not null references public.analyses (id) on delete cascade,
    category text not null,
    budget_tier text not null,
    item_title text not null,
    amazon_url text not null,
    asin text,
    image_url text,
    price numeric(10, 2),
    reason_text text,
    expected_impact text,
    created_at timestamptz default timezone('utc', now())
);

create table if not exists public.comparisons (
    id uuid primary key default gen_random_uuid(),
    project_id uuid not null references public.projects (id) on delete cascade,
    before_analysis_id uuid not null references public.analyses (id) on delete cascade,
    after_analysis_id uuid not null references public.analyses (id) on delete cascade,
    score_delta integer not null,
    summary_text text,
    metric_deltas_json jsonb,
    created_at timestamptz default timezone('utc', now())
);

create table if not exists public.saved_products (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    project_id uuid references public.projects (id) on delete set null,
    recommendation_id uuid references public.recommendations (id) on delete set null,
    item_title text not null,
    amazon_url text not null,
    created_at timestamptz default timezone('utc', now())
);

create table if not exists public.staging_checklists (
    id uuid primary key default gen_random_uuid(),
    project_id uuid not null references public.projects (id) on delete cascade,
    checklist_json jsonb not null,
    created_at timestamptz default timezone('utc', now())
);

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.project_images enable row level security;
alter table public.analyses enable row level security;
alter table public.recommendations enable row level security;
alter table public.comparisons enable row level security;
alter table public.saved_products enable row level security;
alter table public.staging_checklists enable row level security;

create policy "profiles are self readable"
    on public.profiles
    for select
    using (auth.uid() = id);

create policy "profiles are self writable"
    on public.profiles
    for all
    using (auth.uid() = id)
    with check (auth.uid() = id);

create policy "projects are self readable"
    on public.projects
    for select
    using (auth.uid() = user_id);

create policy "projects are self writable"
    on public.projects
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "project_images are self readable"
    on public.project_images
    for select
    using (auth.uid() = user_id);

create policy "project_images are self writable"
    on public.project_images
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "analyses follow project ownership"
    on public.analyses
    for all
    using (
        exists (
            select 1 from public.projects
            where projects.id = analyses.project_id
            and projects.user_id = auth.uid()
        )
    )
    with check (
        exists (
            select 1 from public.projects
            where projects.id = analyses.project_id
            and projects.user_id = auth.uid()
        )
    );

create policy "recommendations follow analysis ownership"
    on public.recommendations
    for all
    using (
        exists (
            select 1
            from public.analyses
            join public.projects on projects.id = analyses.project_id
            where analyses.id = recommendations.analysis_id
            and projects.user_id = auth.uid()
        )
    )
    with check (
        exists (
            select 1
            from public.analyses
            join public.projects on projects.id = analyses.project_id
            where analyses.id = recommendations.analysis_id
            and projects.user_id = auth.uid()
        )
    );

create policy "comparisons follow project ownership"
    on public.comparisons
    for all
    using (
        exists (
            select 1 from public.projects
            where projects.id = comparisons.project_id
            and projects.user_id = auth.uid()
        )
    )
    with check (
        exists (
            select 1 from public.projects
            where projects.id = comparisons.project_id
            and projects.user_id = auth.uid()
        )
    );

create policy "saved_products are self owned"
    on public.saved_products
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "staging_checklists follow project ownership"
    on public.staging_checklists
    for all
    using (
        exists (
            select 1 from public.projects
            where projects.id = staging_checklists.project_id
            and projects.user_id = auth.uid()
        )
    )
    with check (
        exists (
            select 1 from public.projects
            where projects.id = staging_checklists.project_id
            and projects.user_id = auth.uid()
        )
    );
