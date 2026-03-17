# Reset My Space — Full UI/UX Redesign Spec
**Date:** 2026-03-17
**Scope:** Ground-up rebuild of all SwiftUI views. ViewModels, services, and data models are unchanged.

---

## 1. Design System

### Color Tokens (BrandColor updates)
| Token | Light (unused — dark-first) | Dark Value | Use |
|---|---|---|---|
| `background` | — | `#09141A` | App base |
| `surface` | — | `#0F2029` | Cards, sheets |
| `surfaceElevated` | — | `#162C38` | Floating elements, selected states |
| `teal` | — | `#3D8C9E` | Primary accent, CTAs |
| `tealMuted` | — | `#1E4F5C` | Teal tinted backgrounds |
| `gold` | — | `#DEC187` | Score rings, highlights |
| `goldMuted` | — | `#3B3020` | Gold tinted backgrounds |
| `coral` | — | `#E36A3E` | Alerts, staging mode |
| `textPrimary` | — | `#F0E8DB` | Warm white body text |
| `textSecondary` | — | `#8A9BA3` | Subdued labels |
| `textTertiary` | — | `#4A6470` | Hints, placeholders |
| `stroke` | — | `rgba(255,255,255,0.07)` | Card borders |

The app is dark-first. Light mode support is preserved via the existing `ColorScheme` pattern but the dark palette is the primary design target.

### Typography Scale (BrandTypography updates)
| Token | Font Design | Size | Weight |
|---|---|---|---|
| `displayTitle` | Serif | 44pt | Semibold |
| `screenTitle` | Rounded | 28pt | Bold |
| `sectionTitle` | Rounded | 20pt | Semibold |
| `body` | Rounded | 16pt | Regular |
| `bodyStrong` | Rounded | 16pt | Semibold |
| `label` | Rounded | 13pt | Semibold |
| `micro` | Rounded | 11pt | Semibold |
| `score` | Rounded | 52pt | Heavy |
| `scoreSmall` | Rounded | 32pt | Heavy |

### Component Primitives
- **RMSCard**: `cornerRadius 24`, `stroke 0.5pt`, inner shadow, `surface` background
- **PrimaryButton**: full-width teal pill, `cornerRadius 16`, `height 54`
- **SecondaryButton**: ghost pill with teal stroke
- **GhostButton**: text-only, teal color
- **FAB**: 60×60 circle, gold-to-teal diagonal gradient, `shadowRadius 20` teal glow
- **ScoreRing**: SwiftUI Canvas arc, gold gradient stroke, dark track, score number centered
- **TagChip**: `cornerRadius 8`, `height 26`, `micro` font, filled or outlined variants
- **SheetHandle**: 36×4 rounded rect, `textTertiary` fill, centered at sheet top
- **NavPill**: `cornerRadius 32`, `height 64`, `ultraThinMaterial` + `surface` 85% overlay, `stroke` border

### Animation Constants
- **Sheet spring**: `.spring(response: 0.45, dampingFraction: 0.82)`
- **Card stagger**: `.spring(response: 0.5)`, 0.06s delay per card
- **Score ring draw**: `.easeOut(duration: 1.1)` from 0 to value
- **Metric bars**: `.spring(response: 0.7)`, 0.05s stagger
- **Tab transition**: `.easeInOut(duration: 0.22)`, 4pt Y offset
- **FAB pulse**: scale 1.0→1.06→1.0, 2s, `repeatForever`, `autoreverse`, only when projects count == 0
- **Analyzing ring**: continuous rotation, 0.8 rps, gradient arc
- **Budget card press**: scale 0.97 on press, spring release

---

## 2. Navigation Shell

### MainTabView → RMSShellView
Replace `TabView` with a custom `ZStack` layout:
- Content area fills the full screen (including safe areas for immersive photo headers)
- `RMSNavPill` overlaid at bottom, inset 24pt from home indicator

### RMSNavPill
Five slots: Home · Projects · FAB · Staging · Settings

```
[house] [square.stack.3d.up] [FAB↑] [sparkles] [gearshape]
```

- FAB floats 16pt above the pill's vertical center (breaks the pill top edge)
- FAB: 60×60, gold→teal gradient, `shadow(color: teal.opacity(0.4), radius: 20)`
- Active icons: filled variant, `teal` color
- Inactive icons: outlined variant, `textTertiary`
- Pill: `ultraThinMaterial` background + `surface` overlay 85% + `stroke` 0.5pt border
- Tab switch: opacity + 4pt Y offset transition, 0.22s easeInOut
- FAB tap: opens upload sheet (same as before)

### AppShellView
`AppShellView` is updated to use `RMSShellView` in place of `MainTabView`.

---

## 3. Onboarding

### OnboardingView — Full rebuild
3 full-screen pages, no card containers. Each page is an independent view.

**Page layout (each page):**
- Full bleed dark background (page-specific tint: teal / gold / coral)
- Top 40%: large SF Symbol in a radial glow circle (symbol at 64pt, circle 120×120)
- Middle 30%: `displayTitle` serif headline (2 lines max)
- Lower 20%: `body` subtext in `textSecondary`
- Page 3 only: blurred home screen preview behind a frosted `ultraThinMaterial` overlay

**Bottom controls (fixed, not scrolling):**
- Dot indicator row (custom: filled circle = current, small circle = other)
- "Continue" / "Get Started" primary pill button
- "Already have an account? Sign in" ghost button (page 3 only)

**Transitions:** `.easeInOut` horizontal slide between pages.

---

## 4. Auth Screen

### AuthView — Full rebuild
No `BrandCard` wrapper. Content floats directly on `background`.

**Layout:**
1. RMS app icon (56×56, `cornerRadius 14`) + "Reset My Space" `displayTitle` serif — centered hero at top
2. Custom segmented control: "Sign In" / "Sign Up" with sliding `teal` capsule indicator
3. Text fields: `surfaceElevated` fill, `stroke` border, `cornerRadius 14`, `textPrimary` text, `textTertiary` placeholder
4. Name field visible only in Sign Up mode, slides in with `.spring`
5. Primary action button: "Sign In" or "Create Account"
6. Divider: "or continue with"
7. Apple sign-in button: full-width, `surfaceElevated` background, Apple logo + "Continue with Apple"
8. Google sign-in button: same treatment with Google "G" logo using `Text("G")` styled bold coral

**Staggered appear animation:** Fields and buttons animate in with `.spring(response: 0.5)` at 0.06s intervals.

---

## 5. Home Screen (Dashboard)

### HomeView — Full rebuild

**Background:** `background` color + radial gradient glow (`tealMuted` at 30% opacity) from top-right corner.

**Sections (scrollable, no nav bar — toolbar hidden):**

#### 5a. Header Bar
```
[RMS AppIcon 40×40 r:12]  "Reset My Space" sectionTitle serif   [Avatar circle]
```
- Avatar: initials in `teal` on `surfaceElevated` circle, 36×36. Taps to Settings.
- RMS AppIcon loaded from `Assets.xcassets/AppIcon` via `Image("AppIcon")`

#### 5b. Greeting
```
"Good morning, Dustin."  ← screenTitle, textPrimary
"Your spaces are looking [adjective]."  ← body, textSecondary
```
Adjective based on best score: <40 "like they need you", 40-60 "like a work in progress", 60-80 "pretty good", >80 "fantastic".

#### 5c. Score Ring Hero
- 200×200 SwiftUI Canvas arc ring
- Gold gradient arc stroke (lineWidth 10), dark track
- Center: best/most-recent score in `score` font, space name in `micro` `textSecondary`
- If no projects: empty ring, "—" center, pulsing FAB hint label below
- Ring draws on appear: `.easeOut(duration: 1.1)`

#### 5d. Quick Action Row
Horizontal HStack of 3 pill buttons (not scrollable — they fit):
- "New Reset" → teal filled
- "Compare" → gold outline
- "Stage" → coral outline

Each pre-selects the relevant `ProjectMode` in the upload sheet.

#### 5e. Recent Projects Strip
Horizontal `ScrollView` of project cards:
- Card: 200×140, `surface` background, `cornerRadius 20`
- Top 80pt: space photo full-bleed with bottom gradient
- Bottom: title `bodyStrong`, score chip, date `micro`
- "See all" link navigates to Projects tab

If empty: single placeholder card with dashed `stroke` border and "+" centered.

#### 5f. Space Type Quick-Start
"Reset a space" `label` header + horizontal scroll of space type pills:
- Pill: space icon + name, `surfaceElevated`, `cornerRadius 12`
- Tapping triggers upload sheet with space type pre-selected

---

## 6. Upload Flow (Bottom Sheet Progressive Reveal)

### UploadFlowContainerView — Full rebuild (ViewModel unchanged)

The sheet is presented as a `.sheet` with programmatic detent control.

**Stage 1 — Photo selection (`.medium` detent)**
- Sheet handle at top
- Large camera icon (48pt, `teal`) centered
- "Choose a photo" `sectionTitle`
- Photo picker primary button
- "Take Photo" ghost button below
- Space type horizontal pill scroll (pre-selected from quick-start if applicable)

**Stage 2 — Photo selected (`.large` detent, spring expansion)**
- Selected photo fills top 220pt, `cornerRadius 20`, gold `stroke` border 1pt
- Space type selector: horizontal pill scroll, selected = teal filled
- Mode selector: 3 custom pills (Organize · Stage · Compare), sliding capsule selection
- Custom name `TextField` slides in (`.spring`) when "Custom" space selected
- "Analyze My Space" primary button at bottom, disabled until photo + space type chosen

**Stage 3 — Analyzing (full-screen, `.fraction(1.0)` detent)**
- Photo blurs (`.blur(radius: 12)`) as background
- Centered: rotating gradient arc ring (teal→gold, `lineWidth 6`, 80×80)
- "Analyzing your space…" `sectionTitle`
- Status messages in `body` `textSecondary`, cycling every 2.5s with `.easeInOut` fade:
  - "Reading surfaces…"
  - "Scoring organization…"
  - "Building your reset plan…"
  - "Finding smart products…"
  - "Generating concept preview…"
- No cancel button (analysis is fast, ~5-10s)

**Stage 4 — Results (full-screen, same sheet)**
- Cross-fade transition from loading state to results content
- Results layout (see Section 7) renders inside the sheet's ScrollView

---

## 7. Results Screen

### ResultsView — Full rebuild (bindings and callbacks unchanged)

**Photo Hero (top, outside scroll — sticky)**
- Full-width photo, 280pt tall, `cornerRadius 0` (sheet clips it)
- Bottom gradient overlay: `background` → clear, bottom 50%
- Over gradient: TagChip (mode) top-left, space title `screenTitle` bottom-left, score `scoreSmall` bottom-right

**Scrollable content below hero:**

#### Score Card
- Centered 120pt ScoreRing (gold arc, animated on appear)
- Score interpretation label `label` `textSecondary`
- `summaryText` `body`
- `supportiveCoachingText` in italic serif `body` `textSecondary`
- Time chip + interpretation chip HStack

#### Metrics Accordion (collapsible)
- Header row: "Score Breakdown" `sectionTitle` + chevron
- 7 metric rows: label + animated horizontal bar + score number
- Bar colors: coral (<40), gold (40-69), teal (70+)
- Staggered `.spring` fill on appear

#### Reset Plan
- "Your Reset Plan" `sectionTitle` + estimated time chip
- Step rows: gold step number circle (32×32), title `bodyStrong`, detail `body` `textSecondary`, impact `label` `teal`
- Dividers between steps

#### Budget Path Picker
- "Budget Options" `sectionTitle`
- Horizontal scroll of 3 budget cards (220×160 each):
  - Tier name `label`, spend `screenTitle`, 2-line why, item count badge
  - Selected: `teal` border 1.5pt + `surfaceElevated` background
  - Unselected: `surface` + `stroke`
- Below picker: selected tier's top 3 product rows with "Open on Amazon" teal capsule button

#### Action Strip (sticky bottom inside scroll — `.safeAreaInset`)
- "Save Project" primary button (full width)
- "View Shopping" secondary button
- "See AI Concept" ghost button

---

## 8. Projects Screen

### ProjectsView — Full rebuild

**Header:** "Your Spaces" `displayTitle` serif

**Filter strip:** All · Organized · Staged · Compared — horizontal scroll of pill chips

**Project cards:** Full-width, 220pt tall
- Space photo as full-bleed background
- Bottom gradient overlay (60% height)
- Title `bodyStrong`, score chip, date `micro` — bottom-left
- Mode tag chip — top-right

**Project Detail Sheet:**
- Full-screen `.sheet`
- Photo hero 280pt
- Sliding tab indicator: Analysis · Shopping · Compare · Concept
- Compare tab: two photos with draggable `DragGesture` vertical divider
- Before/after score deltas shown as colored metric rows

---

## 9. Staging Hub

### StagingHubView — Full rebuild

**Header:** "Stage Mode" `displayTitle` + coral accent

**Readiness ring:** 160pt ScoreRing in coral accent (vs gold elsewhere)

**Showing Day Checklist:** Large tappable rows with circular checkbox (coral when checked), title `bodyStrong`

**Recommendations grid:** 3 columns — Remove · Hide · Add — each with item pills

**Footer:** "Share Staging Report" primary button (coral tint)

---

## 10. Settings Screen

### SettingsView — Full rebuild

Clean grouped sections on `background`. No NavigationList style — custom `VStack` sections.

**Sections:**
1. **Account** — avatar, name, email; "Edit Profile" row; "Sign Out" (coral text)
2. **Preferences** — Theme (Light/Dark/System custom segmented), AI Quality Mode (Free/Budget/High custom segmented)
3. **About** — App version, "Rate the App", "Privacy Policy", "Terms"
4. **Danger Zone** — "Delete Account" coral destructive button, confirmation alert

---

## 11. File Structure

All new/modified files under `REASON/Features/` and `REASON/Core/`:

**Core (updated):**
- `Core/Theme/BrandColor.swift` — updated color tokens
- `Core/Theme/BrandTypography.swift` — updated type scale
- `Core/Components/RMSCard.swift` — replaces BrandCard
- `Core/Components/RMSButton.swift` — replaces BrandButton + ActionLabel
- `Core/Components/ScoreRing.swift` — new Canvas-based ring
- `Core/Components/RMSNavPill.swift` — new floating nav
- `Core/Components/TagChip.swift` — updated
- `Core/Components/MetricBar.swift` — updated with animation

**Features (rebuilt):**
- `Features/Shell/RMSShellView.swift` — replaces MainTabView
- `Features/Onboarding/OnboardingView.swift`
- `Features/Auth/AuthView.swift`
- `Features/Home/HomeView.swift`
- `Features/Upload/UploadFlowContainerView.swift`
- `Features/Results/ResultsView.swift`
- `Features/Projects/ProjectsView.swift`
- `Features/Projects/ProjectDetailView.swift`
- `Features/Staging/StagingHubView.swift`
- `Features/Settings/SettingsView.swift`

**Unchanged:** All ViewModels, all Services, all Models, AppContainer, AppModel.

---

## 12. Implementation Notes

- All existing `EnvironmentObject` injection patterns preserved
- `AppShellView` updated to use `RMSShellView`
- `BrandCard`, `BrandButton`, `PrimaryActionButton`, `SecondaryActionButton`, `ActionLabel` kept as typealiases or deprecated — new code uses `RMSCard`, `RMSButton`
- `ProjectDetailView` is a new file (currently referenced but not in features list)
- The draggable before/after divider in Compare uses `DragGesture` with a `@State var dividerPosition: CGFloat`
- Score ring uses `Canvas` with `context.stroke(path, with: .linearGradient(...))`
- The rotating analyzing ring uses `@State var rotation: Double` + `.onAppear { withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) { rotation = 360 } }`
