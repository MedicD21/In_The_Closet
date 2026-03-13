# REASON

REASON is a production-minded native iOS app scaffold for supportive home organization and staging. Users can upload a space photo, receive a score-based reset plan, explore Amazon-only product suggestions, preview an AI-inspired optimization concept, compare progress over time, and run a staging-focused mode for selling or showings.

## What’s included

- SwiftUI app scaffold with MVVM-style feature view models
- Brand-aligned light and dark theme system
- Onboarding, auth, home, upload, analysis, results, shopping, visualization, compare, staging, projects, and settings screens
- Supabase client/config scaffolding for auth, storage, and persistence
- OpenAI and Anthropic provider abstractions with mock fallback routing
- Amazon affiliate-ready product recommendation service using valid Amazon search URLs
- File-backed local persistence so the app is usable before Supabase wiring is finalized
- Seed data and sample images for previews and first-run content
- Unit tests for score interpretation and affiliate link composition

## Architecture

- `REASON/App`: app entry, dependency container, root state
- `REASON/Core`: theme, reusable UI, extensions, sample seed helpers
- `REASON/Features`: user-facing screens and feature-specific view models
- `REASON/Models`: domain, analysis, and comparison models
- `REASON/Services/Auth`: auth abstractions plus mock and Supabase scaffolds
- `REASON/Services/AI`: score engine, provider abstractions, router, and mock analysis
- `REASON/Services/ProductRecommendations`: Amazon-only recommendation layer
- `REASON/Services/Persistence`: file-backed and Supabase repository scaffolds
- `REASON/Services/Supabase`: build config and client factory
- `Supabase/schema.sql`: starter schema and RLS policies

## Setup

1. Install Xcode 17+ and `xcodegen`.
2. Copy `REASON/Config/Secrets.example.xcconfig` to `REASON/Config/Secrets.xcconfig`.
3. Fill in these values:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY`
   - `AMAZON_ASSOCIATE_TAG`
   - `AMAZON_AFFILIATE_BASE_URL`
4. Generate the project:

```bash
xcodegen generate
```

5. Open `REASON.xcodeproj` in Xcode and run the `REASON` scheme.

## Supabase setup

1. Create a Supabase project.
2. Enable Auth providers:
   - Email/password
   - Sign in with Apple
   - Google
3. Create a private storage bucket for project photos and generated previews.
4. Run the SQL in [schema.sql](/Users/dustinschaaf/Code/REASON/Supabase/schema.sql).
5. Add your project URL and anon key to `Secrets.xcconfig`.

## Auth notes

- Email and guest flows are usable immediately through the mock auth service.
- `SupabaseAuthService` is scaffolded for production wiring.
- Apple and Google buttons are present in the UI, but the live OAuth token exchange still needs the final SDK + Supabase session mapping pass.
- Account deletion is intentionally left as a scaffold because production cleanup should also remove storage objects and related rows.

## AI provider notes

- `AIRouterService` is designed for OpenAI primary analysis and Anthropic supportive coaching.
- The current runtime safely falls back to a local mock analysis path until the live prompt contracts and structured response parsing are completed.
- This keeps the app demoable while preserving the provider abstraction points for production.

## Amazon affiliate link strategy

- All product recommendations are Amazon-only.
- The current implementation uses real Amazon search URLs instead of fake ASINs.
- Affiliate tagging is appended through `AmazonAffiliateLinkBuilder`.
- Replace the curated search-query data with one of these later:
  - Supabase-hosted curated catalog
  - Amazon affiliate API
  - Server-side Amazon search proxy
  - Manually seeded category collections

## Replacing mock product data

- Start in [CuratedAmazonRecommendationService.swift](/Users/dustinschaaf/Code/REASON/REASON/Services/ProductRecommendations/CuratedAmazonRecommendationService.swift).
- Keep the `ProductRecommendation` and `BudgetRecommendation` models as the contract.
- Swap the query-based items for live results while continuing to return:
  - title
  - retailer
  - category
  - price
  - destination URL
  - optional image URL
  - optional ASIN
  - budget tier
  - reason recommended

## Environment configuration

Build settings are passed through `Info.plist` via the xcconfig files. This keeps secrets out of source while still allowing the app to read configuration safely at runtime through `AppConfig`.

## Current limitations called out in code

- Supabase CRUD and storage syncing are scaffolded, not fully mapped yet
- Apple and Google live auth exchange is not complete
- OpenAI and Anthropic live request/response parsing is not complete
- Generated image output is represented as concept data and placeholder visual treatment, not live image generation yet

## Roadmap ideas

- Finalize live Supabase auth/session syncing
- Store uploaded images in Supabase Storage with signed URLs
- Implement structured OpenAI vision analysis and Anthropic coaching refinement
- Add local caching for recent projects
- Add favorites and shopping boards
- Add export/share summary cards
- Add premium gating hooks for advanced visualizations and reports
