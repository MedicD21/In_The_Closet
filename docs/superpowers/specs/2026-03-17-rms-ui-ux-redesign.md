# Reset My Space — Full UI/UX Redesign Spec
**Date:** 2026-03-17
**Scope:** Ground-up rebuild of all SwiftUI views. ViewModels, services, and data models are unchanged.

---

## 1. Design System

### Color Tokens — BrandColor migration

The existing `BrandColor` uses function-based accessors (`BrandColor.surface(for: colorScheme)`). The new tokens are dark-first static values. To avoid compiler conflicts, the migration strategy is:

- **Rename** all existing function-based accessors by appending `Adaptive` (e.g., `surface(for:)` → `surfaceAdaptive(for:)`). These are used only in any views intentionally left with the old API — there are none, because all views are being rebuilt.
- **Add** new static dark-first tokens directly to `BrandColor`.
- Since all views are being rebuilt from scratch, there is no backward-compatibility burden. The old function-based API is fully replaced.

| Token | Dark Value | Use |
|---|---|---|
| `background` | `#09141A` | App base |
| `surface` | `#0F2029` | Cards, sheets |
| `surfaceElevated` | `#162C38` | Floating elements, selected states |
| `teal` | `#3D8C9E` | Primary accent, CTAs |
| `tealMuted` | `#1E4F5C` | Teal tinted backgrounds |
| `gold` | `#DEC187` | Score rings, highlights |
| `goldMuted` | `#3B3020` | Gold tinted backgrounds |
| `coral` | `#E36A3E` | Alerts, staging mode |
| `textPrimary` | `#F0E8DB` | Warm white body text |
| `textSecondary` | `#8A9BA3` | Subdued labels |
| `textTertiary` | `#4A6470` | Hints, placeholders |
| `stroke` | `rgba(255,255,255,0.07)` | Card borders |
| `divider` | `rgba(255,255,255,0.05)` | Section dividers |
| `overlay` | `rgba(9,20,26,0.72)` | Sheet scrim |

Light mode: the existing warm-white/teal palette is preserved by checking `colorScheme` at call site where needed. The app is dark-first; light mode uses `warmWhite` background and `textPrimaryLight` text. All new components accept `@Environment(\.colorScheme)` and fall back gracefully.

### Typography Scale — BrandTypography migration

All old tokens are **replaced**. Since all views are rebuilt, no alias compatibility is needed.

| New Token | Old Token | Font Design | Size | Weight | Notes |
|---|---|---|---|---|---|
| `displayTitle` | `brandTitle` | Serif | 44pt | Semibold | Up from 40pt |
| `screenTitle` | `screenTitle` | Rounded | 28pt | Bold | Down from 30pt |
| `sectionTitle` | `sectionTitle` | Rounded | 20pt | Semibold | Unchanged |
| `body` | `body` | Rounded | 16pt | Regular | Unchanged |
| `bodyStrong` | `bodyStrong` | Rounded | 16pt | Semibold | Unchanged |
| `label` | — | Rounded | 13pt | Semibold | New — replaces caption at 12pt |
| `micro` | `caption` | Rounded | 11pt | Semibold | Down from 12pt |
| `button` | `button` | Rounded | 16pt | Semibold | Unchanged |
| `score` | `score` | Rounded | 52pt | Heavy | Up from 48pt |
| `scoreSmall` | — | Rounded | 32pt | Heavy | New |

### Component Primitives
- **RMSCard**: `cornerRadius 24`, `stroke 0.5pt`, subtle drop shadow (`shadowColor 0.15 opacity, radius 16, y 4`), `surface` background. Replaces `BrandCard`.
- **PrimaryButton**: full-width teal pill, `cornerRadius 16`, `height 54`, `textPrimary` label. Replaces `PrimaryActionButton`.
- **SecondaryButton**: ghost pill with `teal` stroke 1pt, `teal` label text. Replaces `SecondaryActionButton`.
- **GhostButton**: text-only, `teal` color, no background.
- **DestructiveButton**: text-only, `coral` color.
- **FAB**: 60×60 circle, gold-to-teal diagonal `LinearGradient`, `shadow(color: teal.opacity(0.4), radius: 20, y: 8)`.
- **ScoreRing**: SwiftUI `Canvas` arc using `angularGradient` (not `linearGradient`) to produce a smooth color sweep along the arc path. Dark track arc drawn first, then gold angular gradient arc on top. Score number centered using `Text` overlay.
- **TagChip**: `cornerRadius 8`, `height 26`, `micro` font. Init: `TagChip(title: String, accent: Color, variant: TagChipVariant = .outlined)`. `.filled` variant: `accent.opacity(0.18)` bg + `accent` text. `.outlined` variant: `accent` stroke 1pt + `accent` text.
- **SheetHandle**: 36×4 rounded rect, `textTertiary` fill, centered at sheet top, 8pt top padding.
- **NavPill**: `cornerRadius 32`, `height 64`, `ultraThinMaterial` background + `surface` overlay 85% + `stroke` border 0.5pt.
- **MetricBar**: `RoundedRectangle(cornerRadius: 4)` on a `surface` track. Fill color: `coral` (<40), `gold` (40–69), `teal` (70+). Animated with `.spring(response: 0.7)` on appear. `isExpanded` is view-local `@State` in `ResultsView`.

### Animation Constants
- **Sheet spring**: `.spring(response: 0.45, dampingFraction: 0.82)`
- **Card stagger**: `.spring(response: 0.5)`, 0.06s delay per card index
- **Score ring draw**: `.easeOut(duration: 1.1)` animating a `@State var ringProgress: CGFloat` from 0 to `score/100`
- **Metric bars**: `.spring(response: 0.7)`, 0.05s stagger per bar index
- **Tab transition**: `.easeInOut(duration: 0.22)`, 4pt Y offset, opacity 0→1
- **FAB pulse**: `@State var isPulsing` scale 1.0→1.06→1.0, 2s, `repeatForever`, `autoreverse`, active only when `appModel.projects.isEmpty`
- **Analyzing ring**: `@State var rotation: Double = 0`. `.onAppear { withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) { rotation = 360 } }`. Arc drawn with `angularGradient` teal→gold.
- **Budget card press**: `.scaleEffect(isPressed ? 0.97 : 1.0)` via `ButtonStyle`

---

## 2. Navigation Shell

### RMSShellView — replaces MainTabView + AppShellView integration

`AppShellView.swift` is modified to use `RMSShellView` in the `.main` case. `MainTabView.swift` is deleted.

`RMSShellView` is a `ZStack`:
```
ZStack(alignment: .bottom) {
    content(for: selectedTab)   // full-screen, ignores safe areas for immersive headers
    RMSNavPill(selectedTab: $selectedTab, onFABTap: { isShowingUpload = true })
        .padding(.bottom, 24)
}
.sheet(isPresented: $isShowingUpload) {
    UploadFlowContainerView(container: ..., currentUser: ..., initialDraft: uploadDraft)
}
```

**FAB state ownership:** `isShowingUpload: Bool` and `uploadDraft: UploadDraft` live in `RMSShellView`, not in `HomeView`. `HomeView` receives a callback `onStartUpload: (UploadDraft) -> Void` to trigger the shell-level sheet. The quick-action buttons and space-type strip in `HomeView` call this callback with a pre-configured `UploadDraft`.

### RMSNavPill
Five slots: Home · Projects · [FAB] · Staging · Settings

```
[house.fill] [square.stack.3d.up.fill] [FAB↑] [sparkles.fill] [gearshape.fill]
```

- FAB floats 16pt above the pill's vertical center, breaking the top edge visually
- FAB: 60×60 circle, `LinearGradient(colors: [gold, teal], startPoint: .topLeading, endPoint: .bottomTrailing)`
- `shadow(color: teal.opacity(0.4), radius: 20, y: 8)` on FAB
- Active tab icons: filled SF Symbol variant, `teal` tint
- Inactive: outlined variant, `textTertiary`
- Pill: `ultraThinMaterial` + `surface` 85% overlay + `stroke` 0.5pt border
- Tab content transition: opacity + 4pt Y offset, `.easeInOut(duration: 0.22)`

---

## 3. Splash Screen

### SplashView — in scope, light update only
`SplashView` is **in scope** but receives only a cosmetic update — background color changed to `background` (`#09141A`) from the current `SplashBackground`. The `RMS_Splash` asset display logic is unchanged. No structural rebuild required. File: `Features/Splash/SplashView.swift` (modified, not rebuilt).

---

## 4. Onboarding

### OnboardingView — Full rebuild
3 full-screen pages. No card wrappers.

**Each page structure:**
- Full-bleed `background` color + page-specific top radial glow (page 1: `tealMuted`, page 2: `goldMuted`, page 3: `coral` at 15% opacity)
- Top 38%: SF Symbol at 64pt in a radial glow circle (120×120, symbol accent at 18% opacity fill)
  - Page 1: `camera.viewfinder`, `teal`
  - Page 2: `chart.bar.doc.horizontal`, `gold`
  - Page 3: `sparkles.rectangle.stack`, `coral`
- Middle: `displayTitle` serif headline (2 lines max)
- Below headline: `body` subtext in `textSecondary`
- Page 3 only: a 160×280 card preview of the home dashboard rendered as a static `Image("OnboardingHomePreview")` blurred behind a `ultraThinMaterial` frosted card shape, showing app personality

**Fixed bottom controls (not in scroll):**
- Page dot indicator: custom — filled `teal` circle (8pt) for current, `textTertiary` circle (6pt) for others, 8pt spacing
- "Continue" → "Get Started" on page 3: `PrimaryButton`
- "Already have an account? Sign in": `GhostButton`, page 3 only, calls `appModel.completeOnboarding()` then navigates to auth

**Transitions:** `.easeInOut(duration: 0.3)` horizontal slide.

---

## 5. Auth Screen

### AuthView — Full rebuild (AuthViewModel unchanged)

No card wrapper. Content floats on `background` with `tealMuted` radial glow top-right.

**Layout (scrollable to handle keyboard):**
1. RMS app icon `Image("AppIcon")` 56×56 `cornerRadius 14` + "Reset My Space" `displayTitle` serif centered
2. Custom segmented control: "Sign In" / "Sign Up" — `surfaceElevated` track, `teal` sliding capsule indicator animated with `.spring(response: 0.4)`
3. Text fields: `surfaceElevated` fill, `stroke` border 0.5pt, `cornerRadius 14`, `textPrimary` text, `textTertiary` placeholder label
4. Name field: visible only in Sign Up mode, slides in via `.transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))`
5. Primary action button
6. "Forgot Password": `GhostButton`, visible in Sign In mode only. Calls `viewModel.resetPassword(using:)`. Shows a success/error notice via `appModel.notice`.
7. Divider with "or" label in `textTertiary`
8. Apple button: full-width, `surfaceElevated` bg, `stroke` border, Apple logo SF Symbol + "Continue with Apple" — shown only if `authService.supportsAppleSignIn`
9. Google button: same treatment, `Text("G")` in `bodyStrong` `coral` + "Continue with Google" — shown only if `authService.supportsGoogleSignIn`
10. Guest button: `GhostButton` "Continue as Guest" — shown only if `authService.supportsGuestAccess`

**Staggered appear:** Fields and buttons animate in with `.spring(response: 0.5)` at 0.06s intervals using `@State var appeared = false` + `.onAppear`.

---

## 6. Home Screen (Dashboard)

### HomeView — Full rebuild

`HomeView` receives `onStartUpload: (UploadDraft) -> Void` from `RMSShellView` (no local sheet state).

**Background:** `background` + `RadialGradient(colors: [tealMuted.opacity(0.3), .clear], center: .topTrailing, startRadius: 0, endRadius: 380)`

**Sections (in a `ScrollView`, toolbar hidden, ignores top safe area for edge-to-edge):**

#### 6a. Header Bar (sticky-ish — part of scroll but visually first)
```
[Image("AppIcon") 40×40 r:12]  "Reset My Space" sectionTitle serif   [Avatar 36×36]
```
Avatar: initials from `currentUser.displayName`, `teal` text on `surfaceElevated` circle. Tap → sets `selectedTab = .settings` in parent.

#### 6b. Greeting
```
"Good morning, Dustin."      ← screenTitle, textPrimary
"Your spaces are looking [adjective]."  ← body, textSecondary
```
Adjective from best project score: `<40` → "like they need you", `40–59` → "like a work in progress", `60–79` → "pretty good", `≥80` → "fantastic". If no projects: "ready for their first reset."

#### 6c. Score Ring Hero (200×200)
- `Canvas`-drawn arc, `angularGradient` gold sweep, dark track (`textTertiary` at 20% opacity)
- Track lineWidth 10, score arc lineWidth 10
- Center: `Text(score)` in `score` font `textPrimary`, space name in `micro` `textSecondary` below
- Source: `appModel.projects.max(by: { ($0.currentScore ?? 0) < ($1.currentScore ?? 0) })`
- If no projects: empty ring (track only), center "—" `score` font `textTertiary`, FAB hint "Tap ✦ to start" in `micro` below ring
- `@State var ringProgress: CGFloat = 0`. Animate to `CGFloat(score) / 100` on appear.

#### 6d. Quick Action Row
Three pill buttons in an `HStack`, equal width:
- "New Reset": `PrimaryButton` (teal) → `onStartUpload(UploadDraft(mode: .organize))`
- "Compare": `SecondaryButton` (gold outline, gold text) → `onStartUpload(UploadDraft(mode: .compareProgress))`
- "Stage": `SecondaryButton` (coral outline, coral text) → `onStartUpload(UploadDraft(mode: .stageForSelling))`

#### 6e. Recent Projects Strip
`ScrollView(.horizontal, showsIndicators: false)` of project cards:
- Card: 200×140, `surface`, `cornerRadius 20`, `stroke`
- Top 80pt: `ProjectImageView` full-bleed, bottom gradient overlay
- Bottom: title `bodyStrong` `textPrimary`, score chip, date `micro` `textSecondary`
- "See all →" `GhostButton` triggers `selectedTab = .projects` in parent
- Empty state: single placeholder card, dashed `stroke`, "+" SF Symbol centered, `textTertiary`

#### 6f. Space Type Quick-Start
"Reset a space" `label` `textSecondary` header + `ScrollView(.horizontal)` of space type pills:
- Pill: SF Symbol icon + space name, `surfaceElevated` bg, `cornerRadius 12`, `stroke`
- Tap → `onStartUpload(UploadDraft(spaceType: type))`

---

## 7. Upload Flow (Bottom Sheet Progressive Reveal)

### UploadFlowContainerView — Full rebuild (UploadFlowViewModel unchanged)

**ViewModel step → UI stage mapping:**

| ViewModel Step | UI Stage | Sheet Detent |
|---|---|---|
| `.chooseSpace` | Stage 1 — photo + space selection | `.medium` |
| `.customName` | Stage 1b — custom name inline expansion | `.medium` (expands content only) |
| `.upload` (photo selected) | Stage 2 — configured, ready to analyze | `.large` |
| `.analyzing` | Stage 3 — full-screen loading | `.fraction(1.0)` |
| `.results` | Stage 4 — results in sheet | `.fraction(1.0)` |
| `.confirmation` | Stage 5 — compare confirmation | `.medium` snap-back |

The sheet uses `@State var sheetDetent: PresentationDetent` driven by `viewModel.step`. Step changes trigger `.onChange(of: viewModel.step)` which updates `sheetDetent` with a `withAnimation(sheetSpring)` call.

**Stage 1 — `.medium` detent**
- Sheet handle
- Camera icon 48pt `teal` centered (if no photo selected)
- "Choose a photo" `sectionTitle`
- `PhotosPicker` as primary button + "Take Photo" ghost button
- Space type horizontal pill scroll below (default: first type or pre-selected from quick-start)
- Note: `.medium` detent is ~50% screen height. Space type strip is a single horizontal scroll row — no vertical list — fitting comfortably.

**Stage 1b — Custom name inline (`.customName` step)**
A `TextField` slides in below the space type strip with `.transition(.move(edge: .bottom).combined(with: .opacity))`. Sheet detent remains `.medium`. The "Continue" button calls `viewModel.continueFromCustomName()`.

**Stage 2 — `.large` detent (photo selected)**
Sheet springs to `.large`. Layout:
- Selected photo: 220pt tall, `cornerRadius 20`, gold `stroke` 1pt, fill top of sheet below handle
- Space type selector: horizontal pill scroll, selected = teal filled
- Mode selector: 3 custom pills (Organize · Stage · Compare) with sliding `teal` capsule — driven by `$viewModel.draft.mode`
- "Analyze My Space" `PrimaryButton` at bottom, disabled when `viewModel.draft.selectedImageData == nil`

**Stage 3 — Analyzing (`.fraction(1.0)`)**
- Photo as full-bleed blurred background (`.blur(radius: 14)`)
- Centered overlay:
  - Rotating gradient arc ring (teal→gold, `lineWidth 6`, 80×80) — `angularGradient` with `@State var rotation`
  - "Analyzing your space…" `sectionTitle` `textPrimary`
  - Status messages cycling with `.easeInOut(duration: 0.4)` fade, 2.5s interval:
    `"Reading surfaces…"` → `"Scoring organization…"` → `"Building your reset plan…"` → `"Finding smart products…"` → `"Generating concept preview…"`

**Stage 4 — Results (`.fraction(1.0)`, cross-fade from Stage 3)**
Results content replaces loading content with `.transition(.opacity)`. See Section 8.

**Stage 5 — Compare confirmation (`.medium`)**
Sheet snaps back to `.medium` showing `ResetTrackingConfirmationView` content:
- Score delta displayed as `"+X pts"` in `scoreSmall` `teal` (or `coral` if negative)
- "Progress Saved" `sectionTitle`
- Before/after score chips side by side
- "View Full Comparison" `PrimaryButton` → navigates to `ProjectDetailView` Compare tab
- "Done" `GhostButton` → dismisses sheet

---

## 8. Results Screen

### ResultsView — Full rebuild (ViewModel bindings unchanged)

Rendered inside the upload sheet at `.fraction(1.0)` detent. The sheet clips the top corners.

**Photo hero (top of scroll content, full-width)**
- `ProjectImageView` or `imageData` → Image, `frame(height: 280)`, `clipped()`
- Gradient overlay: `LinearGradient([background, .clear], startPoint: .bottom, endPoint: .center)`, height 280, overlay aligned `.bottom`
- Over gradient overlay (`.overlay(alignment: .bottomLeading)`): TagChip (mode, top-left via separate ZStack layer), space title `screenTitle` bottom-left, score `scoreSmall` `gold` bottom-right

**Scrollable content (VStack below hero):**

**Score card (RMSCard)**
- Centered `ScoreRing` 120pt, `ringProgress` animates on appear
- Score interpretation `label` `textSecondary` below ring
- `summaryText` `body` `textPrimary`
- `supportiveCoachingText` `body` italic (`.italic()`) `textSecondary`
- HStack: reset time TagChip + interpretation TagChip

**Metrics accordion (RMSCard, collapsible)**
- Header HStack: "Score Breakdown" `sectionTitle` + chevron Button toggling `@State var metricsExpanded = true`
- When expanded: 7 `MetricBar` rows with staggered `.spring` fill on appear
- Bar colors: `coral` (<40), `gold` (40–69), `teal` (70+)
- Below bars: "Best opportunities" `bodyStrong` + bullet list items

**Reset Plan (RMSCard)**
- "Your Reset Plan" `sectionTitle` + estimated time TagChip
- Step rows: gold `Text("\(step.order)")` circle (32×32, `goldMuted` fill), title `bodyStrong`, detail `body` `textSecondary`, impact `label` `teal`
- `Divider` `stroke` between steps

**Budget path picker (no card wrapper — cards are the picker items)**
- "Budget Options" `sectionTitle`
- Horizontal `ScrollView` of 3 `BudgetTierCard` views (220×160):
  - Tier name `label` `textSecondary`, spend `screenTitle` `textPrimary`, 2-line why `body`, item count `micro` badge
  - Selected: `teal` border 1.5pt + `surfaceElevated` bg; unselected: `surface` + `stroke`
  - Press animation: `.scaleEffect(0.97)` via `ButtonStyle`
- Below picker: selected tier's top 3 product rows (title `bodyStrong`, reason `body` `textSecondary`, "Open on Amazon" teal capsule button using `Link`)

**Action strip (`.safeAreaInset(edge: .bottom)`)**
- "Save Project" `PrimaryButton`
- "View Shopping" `SecondaryButton` → navigates to `ShoppingView` (see Section 8a)
- "See AI Concept" `GhostButton` → navigates to `VisualizationView` (see Section 8b)

Navigation from results uses `NavigationStack` wrapping the sheet's content OR `@State var shoppingPath / visualizationPath` presented as nested sheets. Given this is already inside a sheet, use `NavigationStack` wrapping the `ResultsView` content with `.navigationBarHidden(true)` and `NavigationLink` for sub-screens.

### 8a. ShoppingView (replaces ShoppingRecommendationsView + BudgetTierSelectorView)

These two existing screens are merged into a single `ShoppingView`:
- Header: "Shopping Tools" `screenTitle` + dismiss button
- Tier picker: horizontal scroll of 3 `BudgetTierCard` views (same as results picker, 160×120)
- Selected tier's full item list: `RMSCard` per item — title `bodyStrong`, price `sectionTitle` `gold`, reason `body` `textSecondary`, impact `label` `teal`, "Open on Amazon" teal capsule `Link`
- File: `Features/Results/ShoppingView.swift`

### 8b. VisualizationView init signature

The rebuilt `VisualizationView` init: `VisualizationView(analysis: SpaceAnalysis, project: SpaceProject)`. `selectedBudgetTier` is dropped from the init — it is sourced locally as `@State var selectedBudgetTier: BudgetTier = .budget` within the view, matching the pattern used in `ShoppingView`. The view still displays a product items section using the locally-selected tier from `analysis.budgetRecommendations`.

When reached from `ResultsView`: `NavigationLink` or sheet push passing the current `analysis` and `project`.
When reached from `ProjectDetailView` Concept tab: passes `project.analyses.last` as the `analysis` argument (or an empty-state if `analyses` is empty).

### 8c. CompareView init signature and dual entry point

The rebuilt `CompareView` init: `CompareView(project: SpaceProject, comparison: ProjectComparison?, beforeAnalysis: SpaceAnalysis?, afterAnalysis: SpaceAnalysis?, onSave: (() -> Void)?)`. All parameters after `project` are optional to support both entry points.

- **From upload flow** (Stage 4 results, mode = `.compareProgress`): `onSave` is provided (calls `viewModel.save(using: appModel)`), both analyses are present from `viewModel`.
- **From `ProjectDetailView` Compare tab**: `onSave` is `nil` (already saved), analyses pulled from `project.analyses`. If `project.comparisons.isEmpty`, shows an empty state — "No comparison yet. Start a Compare Reset to see before/after progress."

Stage 5 "View Full Comparison" button navigates to `ProjectDetailView` (not directly to `CompareView`) — specifically deep-linking to the Compare tab via `@Binding var selectedDetailTab: DetailTab` passed down.

### 8d. StagingResultsView — Full rebuild

Reached when `viewModel.draft.mode == .stageForSelling`. Replaces current `StagingResultsView` inside the upload sheet.

Same photo hero as `ResultsView`. Score card uses `coral` ring accent instead of `gold`. Adds a "Staging Advice" `RMSCard` section:
- Readiness score ring (80pt, `coral`)
- Remove / Hide / Add three-column grid of item pills
- "Quick Wins" `bodyStrong` + bullet list
- "Showing Day Checklist" rows with tappable circular checkbox (`coral` when checked, `@State` local array `checkedItems: Set<UUID>`)

Action strip: "Save Project" primary + "View Shopping" secondary + "See AI Concept" ghost (same as ResultsView).

File: `Features/Staging/StagingResultsView.swift`

### 8c. CompareView — Full rebuild

Reached when `viewModel.draft.mode == .compareProgress`. Shows before/after comparison.

- Photo hero: before photo fills left half, after photo fills right half, split by draggable vertical divider
- Draggable divider: `DragGesture` updates `@State var dividerPosition: CGFloat = 0.5` (0–1 normalized)
- Score delta card: `RMSCard` — large `"+X"` or `"-X"` in `scoreSmall` `teal`/`coral`, per-metric delta rows (green arrow up / red arrow down)
- Summary text `body`
- Action strip: "Save Comparison" primary + "View Full Analysis" secondary

File: `Features/Compare/CompareView.swift`

### 8d. VisualizationView — Full rebuild

Reached from "See AI Concept" ghost button in results action strip.

**Layout:**
- Header: "Concept Preview" `screenTitle` + dismiss
- If `generatedImageURL != nil`: side-by-side or stacked before/after (toggle `@State var layout: Layout`). Before = original photo, After = generated image. Draggable divider (same pattern as CompareView) in side-by-side mode.
- If no generated image yet: centered generating state (same rotating arc ring + "Generating concept…"). Service call is triggered in `VisualizationViewModel` (already exists as `container.visualizationService`).
- Below images: "What improved" bullet list in `RMSCard`, "Still needs work" bullet list, concept caption `body` italic.
- Projected score chip: `gold` accent, "+X pts projected"

File: `Features/Visualization/VisualizationView.swift`

---

## 9. Projects Screen

### ProjectsView — Full rebuild

**Header:** "Your Spaces" `displayTitle` serif + project count `micro` `textSecondary`

**Filter strip:** All · Organized · Staged · Compared — `ScrollView(.horizontal)` pill chips. Filter applied to `appModel.projects` by `mode`.

**Project cards:** `LazyVStack` of full-width cards, 220pt tall:
- `ProjectImageView` as full-bleed background image, `cornerRadius 24`
- Bottom gradient overlay (60% height, `background` to `.clear`)
- Title `bodyStrong` `textPrimary`, score chip, mode TagChip (top-right), date `micro` `textSecondary`
- Tap → opens `ProjectDetailView` as a `.sheet`

**Empty state:** Centered illustration placeholder, "No spaces yet" `sectionTitle`, "Tap ✦ to start your first reset" `body` `textSecondary`.

### ProjectDetailView — New file, full-screen sheet

Presented as `.sheet` (replacing existing push navigation).

**Top:** Photo hero 280pt (same gradient overlay pattern). Dismiss button top-right.

**Tab switcher:** Horizontal row of 4 tabs — Analysis · Shopping · Compare · Concept — with a sliding `teal` underline indicator (not iOS default). `@State var selectedTab: DetailTab`.

**Analysis tab:** Score ring (120pt) + metrics accordion + reset plan. Same layout as ResultsView score/metrics/plan sections.

**Shopping tab:** `ShoppingView` content embedded (same as Section 8a).

**Compare tab:**
- If `project.comparisons.isEmpty`: "No comparisons yet" empty state + "Start a Compare Reset" button
- If comparisons exist: before/after draggable divider photos (same as CompareView pattern) + metric delta rows

**Concept tab:**
- If `project.analyses.last?.visualizationConcept?.generatedImageURL != nil`: shows the concept image full-width + what-improved / still-needs-work cards
- Else: "Generate Concept" `PrimaryButton` which calls `container.visualizationService`

File: `Features/Projects/ProjectDetailView.swift`

---

## 10. Staging Hub

### StagingHubView — Full rebuild

**Data source:** `appModel.projects.filter { $0.mode == .stageForSelling }`. If multiple staging projects exist, the most recently updated is displayed. A project picker pill strip at the top allows switching. If no staging projects: empty state.

`StagingHubView` receives `onStartUpload: (UploadDraft) -> Void` from `RMSShellView`, matching the same callback pattern established in `HomeView`. It does not manage its own upload sheet state.

**Empty state:** "Stage Mode" `displayTitle` + coral accent glow. "No staged spaces yet" `sectionTitle`. "Start a Staging Reset" `PrimaryButton` → `onStartUpload(UploadDraft(mode: .stageForSelling))`.

**Non-empty layout:**
1. Project picker strip (horizontal scroll of project title pills, selected = coral filled) — only if >1 staging project
2. Coral `ScoreRing` 160pt (coral arc vs gold elsewhere), center: readiness score + "Ready to show" label
3. "Showing Day Checklist" `sectionTitle` + `ForEach(checklist.checklistItems)` as tappable rows: circular checkbox (`coral` when `isDone`), title `bodyStrong`. Checkbox tap updates `@State var localChecklist` (view-local copy of checklist items).
4. Recommendations grid: "Remove · Hide · Add" three-column header row + item pills per column
5. "Share Staging Report" `PrimaryButton` (coral tint): this is a **future feature placeholder** — tapping shows an `AppNotice` "Coming soon — export your staging report as a PDF." No functional implementation required.

---

## 11. Settings Screen

### SettingsView — Full rebuild

Custom `VStack` sections, no `List`. `ScrollView` on `background`.

**Account section (RMSCard):**
- Avatar circle (48×48) + display name `sectionTitle` + email `label` `textSecondary`
- "Edit Profile" row (name + email edit fields in an inline expansion, toggled by `@State var isEditingProfile`)
- "Sign Out" `DestructiveButton` — calls `appModel.signOut()`, no confirmation needed (non-destructive data-wise)

**Preferences section (RMSCard):**
- "Theme" row: custom 3-option segmented (Light / Dark / System) with sliding capsule, drives `themeStore.preference`
- "AI Quality" row: custom 3-option segmented (Free / Budget / High) — **display only**. Adding live control would require modifying `AppContainer` and the services that consume `qualityMode` at bootstrap time, which is out of scope for this rebuild. The control renders with "Free" permanently selected and a `micro` `textTertiary` note "Quality changes take effect on next launch — coming soon." No service-layer changes required.

**About section (RMSCard):**
- App version row (`micro` `textTertiary`)
- "Rate the App" → `UIApplication.shared.open` to App Store URL
- "Privacy Policy" → Link
- "Terms of Service" → Link

**Danger Zone section (standalone, no card):**
- "Delete Account" `DestructiveButton` → confirmation `.alert` before calling `appModel.deleteAccount()`

---

## 12. File Structure

### New or fully rebuilt files:
```
REASON/Core/Theme/BrandColor.swift              (rebuilt)
REASON/Core/Theme/BrandTypography.swift         (rebuilt)
REASON/Core/Components/RMSCard.swift            (new — replaces BrandCard)
REASON/Core/Components/RMSButton.swift          (new — replaces BrandButton, ActionLabel)
REASON/Core/Components/ScoreRing.swift          (new)
REASON/Core/Components/RMSNavPill.swift         (new)
REASON/Core/Components/TagChip.swift            (rebuilt)
REASON/Core/Components/MetricBar.swift          (rebuilt — was MetricBarView)

REASON/Features/Shell/RMSShellView.swift        (new)
REASON/Features/Splash/SplashView.swift         (modified — background color only)
REASON/Features/Onboarding/OnboardingView.swift (rebuilt)
REASON/Features/Auth/AuthView.swift             (rebuilt)
REASON/Features/Home/HomeView.swift             (rebuilt)
REASON/Features/Upload/UploadFlowContainerView.swift (rebuilt)
REASON/Features/Results/ResultsView.swift       (rebuilt)
REASON/Features/Results/ShoppingView.swift      (new — merges ShoppingRecommendationsView + BudgetTierSelectorView)
REASON/Features/Staging/StagingResultsView.swift (rebuilt)
REASON/Features/Staging/StagingHubView.swift    (rebuilt)
REASON/Features/Compare/CompareView.swift       (rebuilt)
REASON/Features/Visualization/VisualizationView.swift (rebuilt)
REASON/Features/Projects/ProjectsView.swift     (rebuilt)
REASON/Features/Projects/ProjectDetailView.swift (new)
REASON/Features/Settings/SettingsView.swift     (rebuilt)
```

### Modified (not rebuilt):
```
REASON/App/AppShellView.swift   — .main case uses RMSShellView instead of MainTabView
```

### Deleted:
```
REASON/Features/Home/MainTabView.swift
REASON/Features/Analysis/AnalysisLoadingView.swift    (replaced by Stage 3 inline in UploadFlowContainerView)
REASON/Core/Components/BrandCard.swift
REASON/Core/Components/BrandButton.swift
REASON/Core/Components/ActionLabel.swift
REASON/Core/Components/MetricBarView.swift
REASON/Core/Components/BrandBackground.swift
REASON/Core/Components/SectionHeader.swift
```

### Unchanged (not touched):
All ViewModels, all Services, all Models, AppContainer, AppModel, AppConsole, AppError, SampleSeed, ReferenceImageLoader, JSONResponseSanitizer, ScoreEngine, ProjectImageView, ReferenceImageView, ScoreChip.

---

## 13. Implementation Notes

- `ScoreRing` uses `Canvas` + `.angularGradient` (not `linearGradient`) for a smooth color sweep along the arc path. The gradient angle is mapped to the arc's sweep angle.
- `AppShellView` is modified to replace `MainTabView()` with `RMSShellView()` in the `.main` rootDestination case.
- The `NavigationStack` that previously wrapped each tab now wraps the content inside each tab slot in `RMSShellView`.
- `ProjectDetailView` is presented as a `.sheet` from `ProjectsView` and from the recent projects strip in `HomeView`. It uses its own internal `NavigationStack` for the tab content if sub-navigation is needed.
- `ShoppingRecommendationsView` and `BudgetTierSelectorView` (in old `ResultsView.swift`) are replaced by `ShoppingView.swift`. The `ResultsView` navigation links to `ShoppingView`.
- The `DragGesture` divider in `CompareView` and `ProjectDetailView` compare tab: `@State var dividerOffset: CGFloat = 0` updated via `.onChanged { dividerOffset = $0.translation.width }`, bounded by `GeometryReader` width, normalized to 0–1 for the overlay mask.
- `@State var localChecklist: [ChecklistItem]` in `StagingHubView` is initialized from the project's checklist in `.onAppear` and not persisted back (staging checklist persistence is a future feature).
- "Share Staging Report" shows `appModel.notice = AppNotice(title: "Coming Soon", message: "PDF export is coming in a future update.")`.
- `MetricBar` collapse state is `@State var metricsExpanded = true` in `ResultsView` — view-local, not in ViewModel.
- The rotating analyzing ring: `@State var rotation: Double = 0`. On appear: `withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) { rotation = 360 }`. The arc is drawn using `Canvas` with an `angularGradient` color sweep.
