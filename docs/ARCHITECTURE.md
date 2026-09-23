# Architecture

This document explains how `WidgetFoundation` fits between the Daashi host app and the individual widget packages (Currency, Amplitude, Github, App Rating, Alphavantage, …), and the internal layering each widget package follows.

## 1. The three layers

```
┌─────────────────────────────────────────────────────────────┐
│ Host app (Daashi)                                             │
│  - Owns the dashboard grid, persistence, and widget catalog  │
│  - Only depends on WidgetFoundation's protocols               │
└───────────────────────────┬───────────────────────────────────┘
                            │ conforms to
┌───────────────────────────▼───────────────────────────────────┐
│ WidgetFoundation (this package)                               │
│  - Widget, WidgetPackInfo, WidgetShape, WidgetSize             │
│  - WidgetConfigPayload, WidgetPackDescriptor                  │
│  - WidgetEventHandlerProtocol, View.toWidget(...)              │
└───────────────────────────▲───────────────────────────────────┘
                            │ implemented by
┌───────────────────────────┴───────────────────────────────────┐
│ Widget packages (daashi-currency-widget, daashi-github-package,│
│ daashi-amplitude-package, daashi-appRating-widget,             │
│ daashi-alphavantage-package, …)                                │
│  - One `<X>WidgetPackDescriptor` per package                   │
│  - One or more widgets, each with its own Data/Domain/UI       │
└─────────────────────────────────────────────────────────────────┘
```

`WidgetFoundation` never references a concrete widget. It only defines the **contract** — the host app and every widget package compile independently and are wired together only through these protocols.

## 2. How the host app uses a widget package

The host app (Daashi) never imports a widget package's internal types (`Store`, `Interactor`, `View`, …) — only its `WidgetPackDescriptor`.

1. **Registration** — each widget package is added to a static catalog:

   ```swift
   static let widgetCatalog: [(name: String, type: any WidgetPackDescriptor.Type, version: String)] = [
       ("Currency Widget", CurrencyWidgetPackDescriptor.self, "v1.0.0"),
       ("Alphavantage.co Widget", AlphavantageWidgetPackDescriptor.self, "v1.0.0"),
       // ...
   ]
   ```

2. **Gallery listing** — for each entry, the host reads `type.packInfo` (name/description/icon) to populate the "add a widget" catalog UI, and `type.widgets` to list the individual widgets inside that pack.

3. **Persistence** — a dashboard stores, per placed component: its `type` (pack name), `identifier` (widget identifier, e.g. `daashi.alphavantage.stock-price`), and a serialized JSON config blob.

4. **Rendering a saved dashboard**, for each persisted component:
   - Look up the matching `WidgetPackDescriptor` by pack name.
   - Call `widget.configType(for: component.identifier)` to get the concrete `WidgetConfigPayload` type.
   - Decode the persisted JSON into that concrete type.
   - Call `widget.makeView(for:config:)` to get `(AnyView, WidgetEventHandlerProtocol)`.
   - Mount the view in the grid, keep the event handler around, and call `onLoad()` when the dashboard becomes active and `onUnload()` when it's torn down.

5. **Adding/editing a widget** — the host calls `widget.makeConfigurator(for:config:onSave:)` to present the widget's own SwiftUI settings screen; `onSave` receives the new `WidgetConfigPayload` to persist.

This is why every widget package must expose:
- A `WidgetConfigPayload`-conforming config struct that is `Codable` (safe to persist as JSON) and has a stable, unique `componentIdentifier`.
- A `WidgetPackDescriptor` implementation that can construct a view + event handler from that config alone (no other host state is available).

## 3. Internal layering of a single widget

Every existing widget package (Currency's `ExchangeRateElement`, Github's `PullRequestCounter`, Amplitude's `MonthlyActiveUser`, App Rating's `AppStoreRating`/`PlayStoreRating`, Alphavantage's `StockPrice`) follows the same three-folder split under `Sources/<Feature>/`:

```
Sources/<Feature>/
├── Data/       # Network/parsing layer
│   ├── <Feature>Store.swift        # performs the actual HTTP request / HTML scraping
│   └── <Feature>DTO.swift          # Decodable wire format, if JSON
├── Domain/     # Business logic, framework-agnostic
│   ├── <Feature>.swift             # plain domain model returned to the UI layer
│   ├── <Feature>Interactor.swift        # orchestrates the store, decoupled from network details
│   ├── <Feature>InteractorProtocol.swift
│   └── <Feature>StoreProtocol.swift     # lets the Interactor depend on an abstraction, not the concrete Store
└── UI/         # SwiftUI + presentation
    ├── <Feature>Config.swift            # Codable WidgetConfigPayload (persisted)
    ├── <Feature>ConfigView.swift / <Feature>ConfiguratorView.swift  # settings screen
    ├── <Feature>View.swift              # the actual widget content
    ├── <Feature>ViewModel.swift         # @Published state consumed by the View
    ├── <Feature>ViewDelegate.swift      # optional user-interaction callback (e.g. refresh tap)
    └── <Feature>EventHandler.swift      # WidgetEventHandlerProtocol: owns the refresh loop,
                                          # bridges Interactor output -> ViewModel
```

### Data flow for a single refresh

```
EventHandler.onLoad()
  -> startFifteenMinuteLoop() (or similar named loop, actual cadence = config.refreshInterval)
    -> performAsyncTask()
      -> Interactor.get<Something>()
        -> Store.get<Something>()          // network call / HTML parse
        <- domain model (e.g. StockPrice, ExchangeRates, PlayStoreRating)
      <- domain model
    -> EventHandler.setViewModel(_:)       // maps domain model -> formatted Strings on the ViewModel
  -> View re-renders (via @ObservedObject / @Published)
```

- The **Store** is the only layer allowed to know about `URLSession`, JSON decoding, or (for App Rating) HTML scraping via SwiftSoup.
- The **Interactor** never talks to the network directly; it only depends on a `*StoreProtocol`, which makes it trivially testable/mockable.
- The **EventHandler** is the only layer that touches `WidgetFoundation` types (`WidgetEventHandlerProtocol`, the `WidgetConfigPayload` config) and owns the periodic refresh `Task`.
- The **ViewModel** holds only display-ready `String`/formatted values — all parsing/formatting decisions happen in the EventHandler (see `formattedReviewCount` in App Rating's event handlers for an example of shared formatting logic).

## 4. Package manifest conventions

Every widget package's `Package.swift` follows the same shape:

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "<Name>Widget",                       // e.g. AlphavantageWidget
    platforms: [.iOS("16.0")],
    products: [
        .library(name: "<Name>Widget", targets: ["<Name>Widget"])
    ],
    dependencies: [
        .package(url: "https://github.com/hartakji/daashi-widget-foundation", from: "1.0.0")
        // + any additional dependency, e.g. SwiftSoup for HTML scraping
    ],
    targets: [
        .target(
            name: "<Name>Widget",
            dependencies: [
                .product(name: "WidgetFoundation", package: "daashi-widget-foundation")
                // + matching products for extra dependencies
            ],
            path: "Sources"
        )
    ]
)
```

⚠️ Always pin dependencies with `from:`/`.upToNextMajor(from:)`/`exact:`, **never** `branch:` — a stable-versioned package (`from: "1.0.0"`) cannot depend on a `branch:`-pinned (unstable) dependency; SPM will fail to resolve with an "unstable-version package" error.

See [`CREATING_A_WIDGET_PACKAGE.md`](./CREATING_A_WIDGET_PACKAGE.md) for a step-by-step guide (including file templates) to scaffold a brand-new widget package or add a widget to an existing one.
