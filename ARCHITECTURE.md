# Architecture

English · [中文](ARCHITECTURE.zh.md)

This file is the **contract for dependency directions**. Code is negotiable; the
dependency directions here are not. Product behavior lives in [docs/SPEC.md](docs/SPEC.md).

## One sentence

A paper-thin Xcode project shell (iOS app + iOS widget + Mac app + Mac widget); all
logic and UI live in the local Swift package `MeterKit`. Android has a separate Compose
shell and Windows a separate WinUI 3 shell, and both only draw UI: the cost math,
fetching, formatting, catalog, and cat-bubble line picking all link the same Swift
(`MeterCore` + `MeterProviders` + `MeterFormat` + the platform-neutral `MeterBridge`;
Android via JNI, Windows via a C ABI / P/Invoke). Cross-platform pure data (brand
glyphs, cat geometry, API contract, bridge copy table) is single-sourced in
`shared/*.json`, with generated outputs committed to the repo.

## Why it is cut this way

1. **`.pbxproj` should never be edited by an agent.** The project file is generated
   from `project.yml` (XcodeGen); adding files doesn't touch it — SPM discovers source
   files by directory.
2. **Dependency direction is the product constraint.** SPEC section 09 requires that
   "the widget must not call APIs itself". Rather than a reminder comment, the widget
   target **simply does not link `MeterProviders`** — a violation won't even compile.
3. **The cost math must be testable without UI or network.** `MeterCore` is
   zero-dependency, pure functions; each row of the conversion table in SPEC section 02
   maps to one test case.
4. **`MeterCore` must compile for Android.** The second, harder reason for zero
   dependencies: the four-kinds-of-money math is the real asset of this product. It
   must not be tied to Apple platforms, and it must not be re-translated into Kotlin.
   The Android UI is Compose (`Android/`); the math is the very same `MeterCore` built
   with the official Swift Android SDK. Time is always injected as a parameter; **any
   Apple-only API appearing inside `MeterCore` counts as breaking the architecture**.

## Directory layout

```
cost/
├── shared/                     # Cross-platform sources of truth (JSON). Edit here, then run scripts/generate-shared.py
├── project.yml                 # XcodeGen project definition: iOS / iPadOS (architecture contract — think before touching)
├── project-mac.yml             # Same, for the macOS direct-download shell. Sparkle is declared only here
├── project-common.yml          # Options and base settings shared by both specs (team ID, version)
├── TollCat.xcodeproj           # Generated artifact, committed to the repo
├── TollCatMac.xcodeproj        # Same, for the Mac shell
├── TollCat.xcworkspace         # Hand-written snippet of XML. Only so both projects can be
│                               # open in Xcode at once — the local MeterKit package is loaded
│                               # once; otherwise the second one reports Missing package
│                               # product. Command-line builds still use -project
├── App/                        # iOS shell: entry point + composition, no business logic
│   ├── TollCatApp.swift
│   ├── AppEnvironment.swift    # Composition root: the only place that news up concrete implementations
│   └── Resources/
├── Mac/                        # macOS shell: WindowGroup + MenuBarExtra. Composition reuses AppEnvironment
├── Widget/                     # Widget source. iOS / Mac extension targets each compile a copy
├── Android/                    # Compose shell + JNI. Math, money copy, and catalog are the Swift in Packages/
│   ├── app/                    # Kotlin UI + Keystore/SQLite adapters. Does no math, never formats money itself
│   └── native/                 # SwiftPM: symlinks MeterCore + MeterProviders + MeterFormat + MeterBridge, produces libMeterCoreJNI.so
│                               #   MeterBridge is platform-neutral JSON in/out; MeterCoreJNI is only the JNI skin
├── Windows/                    # WinUI 3 shell + C ABI. Math, money copy, and catalog are the same Swift
│   ├── app/                    # C# UI + Credential Manager / JSON ledger. Does no math, never talks HTTP itself
│   └── native/                 # SwiftPM: same symlinks, produces MeterCoreCLR.dll
├── Packages/MeterKit/
│   ├── Package.swift           # Dependency directions are enforced here — do not loosen
│   ├── Sources/
│   │   ├── MeterCore/          # Domain model + cost math. Zero dependencies
│   │   ├── MeterDesign/        # Design system. Knows no domain type
│   │   ├── MeterFormat/        # Domain values → user-visible strings. Depends only on Core; shared by Widget and Features
│   │   ├── MeterProviders/     # Fetching. Depends on Core
│   │   ├── MeterPersistence/   # SwiftData + Keychain. Depends on Core
│   │   ├── MeterTips / MeterInbox / MeterFeedback / MeterUsage
│   │   │                       # Leaves: tips / inbox / feedback / anonymous page counts. None links Providers
│   │   ├── MeterModules/       # Dashboard modules: views + values + the builders
│   │   │                       # Core/Design/Format only — a widget can link it
│   │   └── MeterFeatures/      # UI. Depends on all of the above
│   └── Tests/
│       ├── MeterCoreTests/     # The tests that matter most live here
│       └── MeterProvidersTests/
├── worker/                     # api.tollcat.app. Never touches billing credentials
├── ops/                        # Local TUI: uses wrangler permissions to view feedback / tips / inbox / usage / migrations
└── docs/SPEC.md
```

## Dependency graph (the only legal directions)

```
        MeterCore  ←──────────────┐
          ↑   ↑                   │
          │   └── MeterProviders  │   (nothing depends on MeterDesign)
          │            ↑          │
   MeterPersistence    │     MeterDesign
          ↑            │          ↑
          │            │     MeterModules ──→ Core + Design + Format
          ↑            │          ↑
          └──── MeterFeatures ────┘
                     ↑
                App target        Widget target ──→ Core + Design + Format + Modules + Persistence
                Mac target        Mac Widget         (no Providers)
                     │            same Widget/ source, each with its own App Group
                     │
                     │  JNI / C ABI, same Core + Providers + Format + MeterBridge
                     ▼
               Android/app (Compose)    Windows/app (WinUI 3)
```

Hard rules:

- `MeterCore` **imports nothing** (except Foundation). No SwiftUI, no SwiftData, no Security.
- **The wall clock enters `MeterCore` through exactly one door: `MeterClock.swift`.** Folding, the ledger and the modules take an injected `MeterClock` / `now` / `calendar`; no other file may contain `Date()` or `Calendar.current` (the gate and `ArchitectureGuardrailTests` scan for it). The clock used to live in Features, which kept the letter of "no `Date()` in Core" while leaving Modules / Persistence / Widget without a clock — they reached for the system time zone instead, and that was the real leak.
  It renders **numbers**, never **sentences**: how an amount is written (`$1,234.56` —
  symbol, grouping, decimal places) belongs to `Money` itself and must be independent of
  the system region (a Chinese locale writes USD as `US$`, which the mockup doesn't).
  `String(localized:)`, `NumberFormatter`, `DateFormatter` and `Locale.current` /
  `.autoupdatingCurrent` are all banned there — the gate matches with a regex, so the
  implicit-member spelling counts too; anything language- or region-dependent lives in
  `MeterFormat`. **One file is exempt: `MeterClock.swift`.** Its locale isn't there to
  produce sentences — calendar + time zone + locale together are the formatter cache key,
  and a clock missing one of them makes two locales share one formatter. The allowlist
  lives in `check-source-invariants.py`'s `LOCALE_EXEMPT_CORE_FILES` and in
  `ArchitectureGuardrailTests.meterCoreStaysPure`; change both together.
- `MeterDesign` **imports no `Meter*` module at all** — it doesn't know what a Provider
  or a Snapshot is; components receive pre-formatted strings and `0...1` fractions, not
  domain objects. Apple's own UI frameworks are fair game (SwiftUI, Charts, CoreGraphics,
  the ImageIO / CoreImage / UniformTypeIdentifiers needed for bitmap export, `os`, and
  the UIColor / NSColor that the dynamic `Color(light:dark:)` implementation touches;
  Features must not touch those last two).
- **Which shell you're in is a value, not a compile-time fork.**
  `MeterDesign/MeterShell.swift` (`.phone / .pad / .mac`) is the single source, and
  wide chrome (the old `usesPadChrome`) is derived from it. In the presentation layer
  `#if os` is **only** for API availability — `NSPasteboard`, `SMAppService`,
  `UIPageControl` simply don't exist on the other side, and no runtime check saves the
  compile. "This sentence differs on Mac", "don't draw this title on Mac" goes through
  `MeterShell`: a compile-time fork means the other branch isn't compiled at all, so a
  mistake in it waits until you switch platforms. `MeterModules` may not contain a
  single `#if os` (the commit gate greps for it).
- `MeterProviders` imports neither SwiftUI nor SwiftData.
- The widget target does not link `MeterProviders` (reason 2 above).
- Reverse dependencies are never allowed; if a callback is needed, define a protocol
  and inject the concrete implementation in `AppEnvironment`.
- **The presentation path never holds the snapshot log.** `Snapshot` is an event
  stream, not a read model: one row per account per refresh, so "what did August
  cost" would cost time proportional to *how often you refreshed in August*. Views
  and their models receive `LedgerView` (a materialised read model) and ask named
  questions; raw readings come only from the one named opening,
  `DashboardModel.readings(for:since:)` — a ranged query. **Not even `DashboardModel`
  holds the log**; the only read side is `MeterPersistence/SnapshotLog`.
  `check-source-invariants.py`'s `LEDGER_ALLOWED` and `LedgerBoundaryTests` enforce
  it — **that allowlist only ever shrinks**. `since` has no default value: the one
  production caller used to omit it, so "the gate decides the range" was a comment while
  the real range was "everything". See [docs/LEDGER.md](docs/LEDGER.md).
- **Calendar days are stored as components, never as instants.** Daily-bucket keys and
  ledger months are positions on a calendar, not "midnight in some time zone":
  `DailySpendCodec` stores `yyyy-MM-dd`, `MonthlyRollupRecord` stores year + month,
  `SubscriptionRecord` stores year / month / day, `SnapshotRecord` stores the billing
  period endpoints as `periodStartDay` / `periodEndDay`, and `ProviderConfigRecord`
  stores the day a connection ended as `archivedDay` — four places, all re-materialised
  against the current calendar on read (`MeterCore/CalendarKeys.swift`: `DayKey` / `MonthKey`).
  Stored as timestamps, one time-zone change shifts every table by a day and counts
  the same provider day twice.
- **Every read on `DashboardStore` `throws`.** What a read failure looks like is decided
  in exactly one place, `DashboardModel.loadFromPersistence` (keep the last good state,
  raise `PersistenceStatus.didFailToRead`); the layer below must not swallow it into an
  empty array — that turns one read error into "no services" and then into an empty
  ledger.

## Module responsibilities

### MeterCore — domain model and cost math

Zero dependencies, pure functions, 100% testable.

- `ProviderID` (the vendor), `ProviderMembership` (whether the vendor is in the
  services list), `AccountID` (one usage identity: key, snapshots, refresh; a vendor
  may have several), `ProviderKind` (`.usage` / `.prepaid` / `.subscription` / `.freeTier`)
- `Money`: a USD amount value type. **Never use a bare `Double` in business logic.**
  Display currency is `MoneyPresentation` — converted only at the moment of rendering,
  never stored in the ledger.
  - **The one written-down exception is `HistoryChartMath`.** It produces *chart geometry*
    (bar heights, line values, segment deltas) that feeds Swift Charts, whose `Plottable`
    only takes `Double`. The conversion goes one way only — nothing computed there flows
    back into the ledger. The file header says so too.
  - `Money(roundedUSD:)` rounds to cents **at construction** (`0.004 → 0`). It is for
    fixtures and ratios only; vendor adapters all go through `FlexibleDecimal →
    Money(usd: Decimal)` and lose nothing. The name carries `rounded` so the behaviour is
    visible at the call site — it used to be `init(usd: Double)`, indistinguishable from
    the other two overloads.
- `Confidence`: `.exact` / `.estimated` / `.partial`
- `Snapshot`: see SPEC section 10, fields map one-to-one
- `MonthToDate`: the computed result
- `MonthToDateCalculator.compute(snapshots:subscriptions:now:calendar:) -> MonthToDate`
  - **Time must be passed in as a parameter**; `Date()` / `Date.now` must never appear
    inside the module. Otherwise it can't be tested.

**Confidence is computed by the model, but no longer produces an `≈` sign.**
`MonthToDate.confidence` is still merged as before (any estimated account makes the
total estimated); the explanation for estimates goes through the inspectable
`estimatedAccounts` path (provider detail page). Money formatting outputs no
approximation marker of any kind.

### MeterDesign — design system

Every visual decision from the design mockup in the SPEC lands here, **and only here**.
Features must contain no literal color values and no magic-number spacing.

- `MeterColor`: lifted verbatim from the mockup's CSS variables (ground / surface /
  surface2 / ink / ink2 / ink3 / rule / ruleSoft / accent / accentBright / accentSoft /
  good / warn / crit + the eight provider colors), **light + dark sets**
- `MeterFont`: body (system font) / mono (SF Mono, for captions, field labels, amounts).
  **No serif** — the design spec document uses serif for its own headings, but nothing
  inside the phone mockup sets a `font-family`; it all inherits `-apple-system`. The app
  uses the system font, and amounts are always `.monospacedDigit()`.
- The mockup's phone is 292px wide representing a 393pt screen, about 1.35×. **Do not
  copy px values**; prefer iOS semantic type sizes.
- `MeterSpacing`, `MeterRadius`
- Components: `GaugeArc`, `SegmentBar`, `ModuleCard`, `ProviderRow`, `StepList`,
  `CopyBox`, `CredentialFieldRow`, `FillProgressButton`, `FieldRow`,
  `PrimaryButton` / `GhostButton`, `StatusPill`
- Every component ships a `#Preview`, one light and one dark

**Liquid Glass discipline** (SPEC section 04): glass exists only in the system
navigation layer. Hand-rolled glass like `.ultraThinMaterial` is **forbidden** in this
module.

### MeterProviders — fetching

```swift
protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

protocol BillingProvider: Sendable {
    static var descriptor: ProviderDescriptor { get }
    func fetch(credential: Credential) async throws -> Snapshot
}
```

- `ProviderDescriptor`: static metadata (id / displayName / kind / colorKey /
  **billingURL** / **credentialSetupURL** / costsMoneyToRefresh /
  supportsDailyGranularity / **minimumRefreshInterval** / **accessStatus**).
  `minimumRefreshInterval` is for vendors whose billing API is quota’d per day
  (or whose data only updates daily). Auto-refresh and pull-to-refresh both
  honor it via `RefreshCadence`; setup verify and history backfill do not.
  Vendors with `accessStatus == .declined` keep their identity and icon in the catalog,
  but are filtered out of the iOS / Android add lists and landing pages.
  **Both URLs are always compiled into the app and never come from the remote catalog**
  (SPEC section 07 security red line): `billingURL` is the vendor's billing page,
  `credentialSetupURL` is the page where the token is actually created — the wizard
  deep-links to the creation page, not the home page (SPEC section 06, rule one).
- `HTTPClient` is the transport seam. Every `BillingProvider` initializer takes an
  `HTTPClient`. The app injects `LiveHTTPTransport`; unit tests inject
  `StubHTTPClient`, and callers don't change.
- Each vendor with a public read-only billing API gets one file, one struct; none knows
  the others exist. Vendors without one (AWS Cost Explorer charges per call, Anthropic
  personal accounts, and the four inbox-only vendors Fly / Clerk / Render / Expo) stay
  out of the fetch map.

#### Test doubles are allowed at the transport layer only

1. **Transport layer** — inject an `HTTPClient` that returns canned HTTP responses.
   `URLSessionHTTPClient` is the real one; `StubHTTPClient` reads canned responses from
   fixtures shaped like the official APIs. URL building, JSON parsing, and status-code
   mapping all genuinely run.
2. **Replacing `fetch` at the provider layer** — forbidden. There is no
   `MockBillingProvider`.
3. **Stuffing the persistence layer and calling it runtime fetching** — forbidden.
   Previews / demo seeds may write the SPEC section 04 mockup snapshots; that is not
   the same path as the user tapping refresh.

### MeterPersistence — storage

- SwiftData `@Model`s: `SnapshotRecord` (never deleted), `SubscriptionRecord`,
  `ProviderConfigRecord` (usage identity), `ProviderMembershipRecord` (the vendor's
  front door)
- **The container lives in the App Group from day one** (SPEC section 09: changing this
  later is very painful)
- `CredentialStore` protocol + `KeychainCredentialStore`
  (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) + `InMemoryCredentialStore` (tests
  and previews)
- **Secrets themselves never appear in SwiftData** — only Keychain reference identifiers
- Cross-device migration encryption and Keychain I/O live here. The payload model is in
  `MeterCore` (pure `Codable`, no CryptoKit import); AES-GCM + PBKDF2 must not sink
  into Core, nor leak into `MeterProviders`
- `CatalogSource` protocol + `BundledCatalogSource` + `RemoteCatalogSource`. Callers
  only know the protocol.
- `CatalogResolver` handles the three-tier fallback: bundled copy, last successful
  fetch, freshest from the network. One background fetch after launch, silent on
  failure. Exchange rates are a catalog field — no separate rates network call.

### MeterTips / MeterInbox / MeterFeedback / MeterUsage — worker leaves

Four modules, each owning one path to `api.tollcat.app`, none importing another, and
none linking `MeterProviders`. See SPEC section 12.5: having a server ≠ being allowed
to use the server. Billing credentials and billing data must never travel this channel.
The worker source lives in `worker/` at the repo root.

- `MeterTips`: StoreKit 2 consumable IAP + tip messages. Depends only on Foundation
  and StoreKit
- `MeterInbox`: the readings inbox. Depends on MeterCore (it produces Snapshots), knows
  nothing about the catalog
- `MeterFeedback`: in-app feedback. Doesn't even depend on MeterCore — it can't reach
  `Money`
- `MeterUsage`: anonymous page counts. Doesn't depend on MeterCore either. Reports only
  allowlisted page names, the platform, and whether this UTC day is a first open. No
  device identifiers

### MeterModules — the dashboard modules

The module views, the values they read (`XxxModuleContent`), and **the builders that
turn the ledger into those values** (`DashboardContentsBuilder` is the single entry
point). `DashboardModel`, pages and navigation stay in MeterFeatures.

**How many there are is `DashboardModuleID`'s business; prose never spells a number.**
It said "12 modules" in three places, and retiring Upcoming Charges made all three wrong —
the kind of wrong nothing ever catches. The commit gate greps for `N 块模块` /
`N dashboard modules`.

**The rules inside a builder do not live here — the pure ones live in `MeterCore`.**
`HeatmapMonths`, `CategoryShares`, `SuperlativeSelection`, `BudgetGauge`, `SpendGrouping`:
which months have cells and where the first of the month sits, how categories add up and
why the integer percentages must total 100, which account is "the biggest rise" and in
what order the three lines appear, when the budget bar turns amber, how spend lines
bucket and collapse into "other". The builders here only turn those values into
sentences.

The reason is Android and Windows: their bridge **cannot link this target** (it pulls in
SwiftUI through MeterDesign), so before the split it re-implemented five of these
builders in `ProductDashboardModules.swift` — and they had already drifted. Superlatives
came out in a different order and pinned the whole month's change ratio on whichever
vendor happened to be first; categories rounded each share on its own, so the column
could add up to 99. A rule that two platforms need is a rule that belongs in the
zero-dependency layer both of them already compile.

There is exactly one reason this is its own target: **a widget can link it.** A widget
cannot link MeterFeatures — that would drag thirty-odd billing adapters into the
extension, and SPEC §09 forbids a widget from calling APIs itself. The builders can
come down here because all they need above the domain is "what is this provider
called, what colour, what category" — and that is
`MeterCore/ProviderIdentity.swift` (generated; the authority is `ProviderCatalog.swift`),
which is data, not fetching. The dependency list (Core / Design / Format) is the
safety datasheet for what a widget pulls in; `ArchitectureGuardrailTests` and
`check-source-invariants.py` each enforce it.

So the number on the Home Screen and the number in the app are computed by the same
code from the same data — not by a second, simplified copy inside the widget. That
copy would drift with no compile-time signal at all.

The same module views appear in many shells: iPhone list rows, wide-shell bento cards,
the iPad/Mac sidebar card, the share card, and iOS / macOS widgets. Layout differences
are decided by **three orthogonal axes** and nothing else:

| Axis | Values | Governs | Set by |
|---|---|---|---|
| `ModuleWidth` | compact / regular / wide / expanded | Horizontal layout: chart beside the list or stacked, one column or two | The container; breakpoints in `shared/module-size.json` |
| `ModuleHeight` | tight / regular / tall / unbounded | Vertical budget: leading headline or not, chart size, how many rows | Same |
| `ModuleContainer` | listRow / card / snapshot | Chrome and interaction: who draws the chevron, who supplies row height, whether anything is tappable | The container |

All three are declared together: `.meterModuleStyle(width:height:container:)`.

Why none can be dropped: a single bool ("am I in a card") cannot express a
`systemLarge` widget — it is wide, yet it has no `List` and nothing in it is tappable.
And height cannot ride on the container either: a widget's `systemMedium` and
`systemLarge` are both `.snapshot` with a content width of about 300, yet their
heights differ by 2.5x.

**A module must never measure itself.** Measuring yourself and then changing layout
from it is a feedback loop — measure, change content, content changes the ideal size —
and that is exactly how the first version of the dashboard lab froze the main thread
(column width climbing 12pt per pass, forever). Every container already knows its size
(the bento row computes the card width, a widget can measure the box it was handed,
the share card is fixed), so the rule costs nothing. Guard: any `GeometryReader` /
`onGeometryChange` under `MeterModules` fails the build gate.

Modules also do not know how to push a page: they emit a route (`ModuleLink` +
`DashboardRoute`) and the shell injects the push (`dashboardModuleLinks()`; the widget
injects `Link(destination:)`, with the URL table in `DashboardDeepLink`). With nothing
injected the link degrades to plain text — which is precisely what the share card wants.

### Widget — one dashboard module on the Home Screen

A widget is one block from the dashboard; the user picks which one in the widget's
configuration (`TollCatWidgetIntent`, whose options come straight from
`DashboardModuleID`). **The widget must not keep its own module list**: what to draw is
decided by the single switch in `DashboardModuleFactory`, and what can be picked by
`DashboardModuleID.defaultOrder`. Two guards watch this — `check_widget_module_list`
and `DashboardLayoutTests.widgetDoesNotKeepItsOwnModuleList` — and a second module name
appearing anywhere under `Widget/` fails them.

The widget reads the raw readings from the App Group (`SharedStoreReader`) and runs
`DashboardContentsBuilder` itself. Its frame only follows the subscription scope
(`SharedStoreContents.widgetFilter`): always "this month, all accounts".

**Android's home-screen widget is a written-down exception to "the same builder".**
Glance renders inside a broadcast, and loading `libMeterCoreJNI.so` there costs more
than the widget is worth — so the app writes a small read-only file after every
recompute (`WidgetSnapshot`) and the widget only draws it. Two consequences, accepted
on purpose: the number is as old as the last time the app ran (a month boundary is
handled explicitly, a fresh projection is not), and rolling the composition up by vendor
is a second, simpler implementation. What it does *not* do is call an API or link
`MeterProviders` — SPEC §09 holds. The frame is the same `widgetFilter`: this month,
all accounts, subscription scope only.

### MeterFeatures — UI

Subdirectories by feature: `Dashboard/`, `Services/`, `Setup/`, `Settings/`.

- State lives in `@Observable` models, one per screen, named `XxxModel`
- Views never new up dependencies; everything is constructor-injected
- The dashboard is a data-driven list of modules: a `DashboardModule` enum/protocol +
  one view each; adding a module doesn't touch the container (SPEC section 05)
- Every screen must have a working `#Preview` with mock data

## Source-of-truth registry

The lesson from the cross-platform duplication audit (2026-08): the same fact
hand-copied two or three times will drift, always. Each kind of fact has exactly one
authority; everything else is a generated artifact (with a `GENERATED` header,
committed to the repo — same philosophy as the xcodeproj).
`scripts/check-source-invariants.py` carries the regenerate-diff gate: editing an
authority without running its generator, or hand-editing a generated file, turns the
commit gate red.

| Fact | Authority | Generated artifacts | Command |
|---|---|---|---|
| Cost math / fetching | `MeterCore` / `MeterProviders` (Swift source) | The same source double-compiled via symlinks on the Android / Windows side | `scripts/android-run.sh`; for Windows see `Windows/native/build.ps1` |
| Provider visual identity (Simple Icons path, light/dark brand colors, fill, evenOdd, letterReason) | `shared/providers.json` | `ProviderGlyphArtwork.swift/.kt/.cs`, `ProviderPalette.swift`, `ProviderColors.kt`, `ProviderPalette.cs`, `site/src/providers.ts` | `scripts/generate-shared.py` |
| Provider access tiers (fully supported / theoretically supported / readings inbox / not onboarded) | `accessStatus` and `supportsInboxIngest` in `ProviderCatalog.swift` | `site/src/supportTiers.ts` | same as above |
| Landing-page service details (billing kind, credential fields, plans, official URLs) | `ProviderCatalog.swift` + `Catalog/catalog.json` | `site/src/catalogEntries.ts` | same as above |
| Cat geometry (layer paths, anchors, silhouette segment control points) | `shared/cat.json` (master: `docs/assets/tollcat.svg`) | `CatArtwork.swift/.kt/.cs`, entire files | same as above |
| Cat motion constants | Hand-written on all three platforms (rendering belongs to each platform) | — (the `check_cat_motion_constants` gate enforces identical values) | — |
| User-visible copy | Each module's `Localizable.xcstrings` (zh source strings + en/ja) | Android `values-en/`, `values-ja/`; Windows `en-US`/`ja-JP` resw. Platform-only strings live in `strings-android-only.json` / `strings-windows-only.json` | `scripts/generate-android-strings.py`; `scripts/generate-windows-strings.py` |
| Copy exported over the bridge | `shared/jni-copy.json` picks the keys; translations come from xcstrings | `Android/native/Sources/MeterBridge/JNICopy.swift` (the trilingual table compiled into the dynamic library) | `scripts/generate-shared.py` |
| API contract (field limits, category enums, anonymous page allowlist) | `shared/api-contract.json` | `worker/src/contract.ts`, `TipFieldLimits.swift`, `FeedbackFieldLimits.swift`, `UsageAnalyticsScreen.swift`, `UsageFieldLimits.swift`, `UsageScreens.kt`, `UsageScreens.cs`, site forms (patch-style) | same as above |
| Onboarding catalog (tutorials, plans, exchange rates) | `Packages/.../MeterPersistence/Catalog/catalog.json` (Chinese is the canonical field; `en` / `ja` are optional overlays, resolved at display time, falling back to Chinese) | worker, Android bridge, and Windows shell resources are all symlinks (the `check_catalog_sync` gate) | — |
| Brand icon (app icon, favicon, Android launcher, BrandMark.astro) | `scripts/render-app-icon.py` (cat geometry from `shared/cat.json`) | Every slot across App/site/docs/Android | `python3 scripts/render-app-icon.py` |
| System permission usage strings | `INFOPLIST_KEY_NS*UsageDescription` in `project.yml` (Chinese) + `App/Resources/InfoPlist.xcstrings` (en / ja) | System permission dialogs | — |
| Landing-page SNS images | `.github/readme/hero-{zh,en,ja}.png` | `site/public/og-{locale}.png` (copied at Astro startup) | after swapping a README hero, `pnpm build` |
| UI smoke anchors (iOS accessibilityIdentifier / Android testTag) | `shared/ui-test-ids.json` | `MeterDesign/UITestID.swift`, `Android/.../ui/UITestId.kt`; `maestro/*.yaml` may only reference ids from the table, and every id in the table must be used by some flow | `scripts/generate-shared.py` |
| Dashboard module size buckets (width / height breakpoints and what each means) | `shared/module-size.json` | `MeterDesign/ModuleSize.swift` (when Android adopts these axes, generate its Kotlin from the same file — do not copy the numbers) | `scripts/generate-shared.py` |
| Provider identity (display name, colour key, category, market tier, whether refreshing costs money) | `ProviderCatalog.swift` (same place as the access tiers) | `MeterCore/ProviderIdentity.swift`; the generator also checks its names agree with `shared/providers.json` | Same |
| User-visible version X.Y.Z | `shared/version.json` | `project-common.yml` MARKETING_VERSION (shared by both specs), `build.gradle.kts` versionName, `TollCat.csproj`, `Package.appxmanifest`, `TollCat.appinstaller`, winget manifests (patch-style); the build number is filled by the CI run number | `scripts/generate-shared.py` |
| Release notes (the what's-new drawer, the changelog page, store copy) | `shared/changelog.json` (Chinese is the canonical field; `en` / `ja` are in-place overlays, same shape as `catalog.json`) | `site/src/changelog.ts`, `WhatsNewCatalog.swift/.kt/.cs`, `docs/release/notes.md`, `docs/release/appcast-notes/*.html` (Sparkle `<description>`), `docs/appstore/metadata/*/release_notes.txt`, `Android/app/distribution/whatsnew/*` | `scripts/generate-shared.py` |
| Bridge JSON schema | Hand-written on all three platforms (`JNISchema.version` ↔ Kotlin / C# `EXPECTED_JNI_SCHEMA`) | — (the `check_jni_schema` gate enforces matching numbers) | — |
| Cross-device transfer envelope (magic, header layout, PBKDF2 work factor and its bounds, key/salt/nonce/tag lengths, code length, file lifetime) | `MeterPersistence/TransferFileFormat.swift` + `TransferKeyDeriver.swift` + `MeterCore/TransferCode.swift` | Hand-written again in `DeviceTransfer.kt` (each platform uses its own system crypto) — the `check_transfer_envelope` gate enforces identical numbers; a mismatch is invisible until the day a user changes phones | — |
| Which reading counts (for a month, and for "now") | The fold: `LedgerFolder` + `AccountLatest.reduce` | — (the `check_ledger_boundary` gate stops the presentation path from deciding it a second time; `LedgerSelfCheck` proves the fold agrees with a full recompute) | — |

### What adding a provider touches

This list is **not generated**, and shouldn't be: per-provider prose like `tierReason`
and console URLs (a SPEC §07 security line) have to be written by hand. What *can* be
automated is telling you which spot you forgot — the ✅ rows are enforced by
`check_provider_wiring`.

| File | What goes in | What forgetting it looks like |
|---|---|---|
| `MeterCore/ProviderID.swift` | the rawValue | build error (the only spot the compiler catches) |
| `MeterProviders/ProviderCatalog.swift` | the descriptor (name, category, tier, URLs, keywords…) | not searchable, can't be added |
| `MeterProviders/ProviderAssembly.swift` | `liveRESTProviderIDs` **and** the switch case ✅ | half of it: that provider never fetches — the row just says "no readings", silently |
| `MeterProviders/OutboundHosts.swift` | every URL's host ✅ | the outbound allowlist blocks it, and the error reads like "their API is down" |
| `Catalog/catalog.json` | the setup guide, all three languages ✅ | step two of the wizard is blank |
| `shared/providers.json` | brand colours + icon path | generator gate goes red |
| `MeterProviders/Fixtures/<id>.json` | design / demo readings | affects only the demo seed and screenshots — **not required for every provider** |


Deliberately **not** unified: M3 bento vs. iOS inset-grouped spacing/radii/typography
(each platform designs its own), the site's layout and marketing copy, platform
adapters like SQLite/Keystore, and the chart rendering layer (data decisions are
already shared).

## Engineering conventions

- Swift 6, strict concurrency fully on. Mark cross-actor types `Sendable` where they
  should be; never paper over it with `@unchecked`
- Minimum iOS 26.0 / macOS 26.0. iPhone uses native `TabView` / `NavigationStack`;
  landscape iPad and Mac use `NavigationSplitView` for Services / Settings — never
  hand-roll a split view. Mac settings are the third sidebar item in the main window,
  reachable via ⌘, — no `Settings` scene. Sheets on iPad / Mac use the system
  form / page style; don't drag the iPhone detent drawer onto wide shells. No Mac
  Catalyst, and don't let the iOS build masquerade as the Mac version on Apple Silicon
- Tests use Swift Testing (`import Testing`, `@Test`), not XCTest
- **Adding or removing a file under `Tests/` means re-running xcodegen and committing both
  `.xcodeproj`s.** The `.pbxproj` lists files explicitly — it is not a synchronised folder —
  so a new test that isn't regenerated in simply never compiles, and `xcodebuild` still
  prints green. This applies to `Tests/` only; `Sources/` is discovered by SPM
- No third-party dependencies. This app doesn't need any. The exceptions are written
  down here and nowhere else:
  - **Sparkle**, the auto-update framework for the direct-download Mac build — linked
    only into `TollCatMac`, appearing only in `Mac/MacUpdater.swift` (replacing a
    running .app inside the sandbox requires its XPC installer service; writing our own
    would mean rebuilding an installer).
  - **AndroidX Glance** and **Play Billing** on the Android shell. These are the
    platform's own WidgetKit and StoreKit — a home-screen widget and in-app purchase
    cannot be written without them, exactly as Sparkle can't. They are not a licence for
    a general-purpose third-party library on that shell.

  The rule's real target is a library that *does* something the app could do itself.
  What we will not take is a crypto library: `MeterProviders` signs vendor requests
  (SigV4, TC3, EdgeGrid…) and **must cross-compile for Android**, where `CryptoKit`
  does not exist — so the digests live in `MeterCore/MeterDigest.swift` +
  `MeterHMAC.swift`, pure Swift, pinned to the published test vectors.
- User-facing copy is Chinese (source language); code identifiers are English
- Comments explain "why", never "what"

## Commands

```bash
# Open both shells in Xcode at once (opening the two .xcodeproj separately makes them
# fight over the local package)
open TollCat.xcworkspace

# Generate the projects (after editing either spec, or adding/removing files under
# Tests/ — both are committed artifacts). XcodeGen 2.46.0.
xcodegen generate
xcodegen generate --spec project-mac.yml

# Build
xcodebuild -project TollCat.xcodeproj -scheme TollCat \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project TollCatMac.xcodeproj -scheme TollCatMac \
  -destination 'platform=macOS' build

# Run tests
xcodebuild -project TollCat.xcodeproj -scheme TollCat \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Android acceptance screen (the same MeterCore → JNI → Compose)
bash scripts/android-run.sh

# Should we ship, and which platforms (cadence in docs/RELEASE.md)
bash scripts/release-status.sh

# Cross-platform follow-up (directory ACK; stale stamps do not fail pre-commit)
python3 scripts/check-follow-up.py due --platform android
python3 scripts/check-follow-up.py show dashboard --platform android
# python3 scripts/check-follow-up.py stamp dashboard android --decision reviewed --note "…"

# UI smoke (Maestro, by id not by text; both platforms share maestro/*.yaml; CI runs iOS Simulator only)
bash scripts/maestro-smoke.sh            # iOS
bash scripts/maestro-smoke.sh android    # Android; needs the jniLibs built by android-run.sh first

# After editing shared/*.json: regenerate outputs (--check is the compare mode used by the commit gate)
python3 scripts/generate-shared.py

# After editing xcstrings: regenerate Android en/ja
python3 scripts/generate-android-strings.py

# Regenerate Windows en-US / ja-JP resw
python3 scripts/generate-windows-strings.py

# After changing the brand icon: refill every slot across App / site / docs / Android launcher
python3 scripts/render-app-icon.py

# Permissions / privacy manifest / app icon / App Group: the App Store submission checks that source can catch
python3 scripts/check-app-store-invariants.py

# Local view of what needs handling on api.tollcat.app (wrangler login, Ink + bun)
bash scripts/ops
```

MeterKit declares `platforms: [.iOS(.v26), .macOS(.v26)]`. The package itself should
`swift build --package-path Packages/MeterKit` on a Mac host. Tests still go through
`xcodebuild test` above, run by the Xcode `MeterKitTests` target on the iOS simulator
(rasterization, photo library, and the keyboard accessory are still UIKit). The Mac
shell is accepted once the `TollCatMac` scheme builds.

When multiple agents run in parallel, each should pass its own
`-derivedDataPath .derived/dd-<module>`; fighting over the same DerivedData produces
spurious errors. `.derived/` is gitignored. Each DerivedData tree runs about 1 GB —
`rm -rf` your own once the task is done rather than leaving it on disk.
