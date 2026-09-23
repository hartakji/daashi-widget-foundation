# Creating a Widget Package

This guide is written for an AI agent (or a developer) tasked with creating a **new** Daashi widget package, or adding a **new widget** to an existing one. It assumes you've read [`ARCHITECTURE.md`](./ARCHITECTURE.md) first.

Read this whole document before writing any code — steps 6 and 7 (naming/config rules, and known pitfalls) prevent the most common mistakes.

## 0. Gather requirements

Before scaffolding anything, make sure you know:
- **Package name** (e.g. "Alphavantage Widget" → Swift package/library name `AlphavantageWidget`).
- **Data source**: a JSON REST API (preferred) or an HTML page to scrape (last resort — see pitfalls below).
- **Widget(s)**: one feature folder per widget (e.g. `StockPrice`), each with its own identifier, config, and display.
- Any credentials the widget needs (API key/token, IDs, etc.) — these become fields on the widget's `Config` struct.

## 1. Scaffold the package

```
daashi-<name>-package/
├── Package.swift
├── README.md
└── Sources/
    ├── <Name>WidgetPackDescriptor.swift
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   ├── ic_widgetPack_<abbr>.imageset/      # pack-level icon
    │   └── ic_<widget>.imageset/                # per-widget icon
    └── <Widget>/
        ├── Data/
        ├── Domain/
        └── UI/
```

### `Package.swift` template

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "<Name>Widget",
    platforms: [.iOS("16.0")],
    products: [
        .library(name: "<Name>Widget", targets: ["<Name>Widget"])
    ],
    dependencies: [
        .package(url: "https://github.com/hartakji/daashi-widget-foundation", from: "1.0.0")
        // add e.g. .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.13.9") only if scraping HTML
    ],
    targets: [
        .target(
            name: "<Name>Widget",
            dependencies: [
                .product(name: "WidgetFoundation", package: "daashi-widget-foundation")
                // .product(name: "SwiftSoup", package: "SwiftSoup")
            ],
            path: "Sources"
        )
    ]
)
```

Asset `Contents.json` boilerplate (top-level `Assets.xcassets/Contents.json`):

```json
{ "info": { "author": "xcode", "version": 1 } }
```

Per-imageset `Contents.json` (adjust `filename`):

```json
{
  "images": [{ "filename": "<icon>.png", "idiom": "universal" }],
  "info": { "author": "xcode", "version": 1 }
}
```

## 2. Write the Domain layer (`Sources/<Widget>/Domain/`)

- `<Widget>.swift` — plain struct returned by the interactor (e.g. `struct StockPrice { let value: Double }`).
- `<Widget>StoreProtocol.swift` — one async throwing function the Data layer must implement.
- `<Widget>InteractorProtocol.swift` — same signature, exposed to the UI layer.
- `<Widget>Interactor.swift` — a thin class holding a `<Widget>StoreProtocol` and forwarding calls to it. Never talks to the network directly.

```swift
class <Widget>Interactor {
    private let store: <Widget>StoreProtocol
    init(store: <Widget>StoreProtocol) { self.store = store }
}

extension <Widget>Interactor: <Widget>InteractorProtocol {
    func get<Widget>(...) async throws -> <Widget> {
        try await store.get<Widget>(...)
    }
}
```

## 3. Write the Data layer (`Sources/<Widget>/Data/`)

- `<Widget>DTO.swift` — `Decodable` struct mirroring the API's JSON shape (only if the source is JSON).
- `<Widget>Store.swift` — builds the `URLRequest`, calls `URLSession.shared.data(for:)`, decodes/parses the response, maps it to the Domain model, and throws a local `Error` enum (`invalidUrl`, `invalidResponse`, …) on failure.

```swift
struct <Widget>Store {
    enum Error: Swift.Error { case invalidUrl, invalidResponse }
    private let token: String
    init(token: String) { self.token = token }
}

extension <Widget>Store: <Widget>StoreProtocol {
    func get<Widget>(...) async throws -> <Widget> {
        guard let url = URL(string: "https://api.example.com/...&apikey=\(token)") else {
            throw Error.invalidUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        let dto = try JSONDecoder().decode(<Widget>DTO.self, from: data)
        // map dto -> domain model, throwing .invalidResponse on missing/invalid fields
    }
}
```

## 4. Write the UI layer (`Sources/<Widget>/UI/`)

- **`<Widget>Config.swift`** — the persisted, `Codable` configuration:

  ```swift
  import WidgetFoundation

  public struct <Widget>Config: WidgetConfigPayload {
      public static let componentIdentifier = "daashi.<package>.<widget-kebab-case>"
      var apiToken: String      // or token/appId/repository, whatever the API needs
      var refreshInterval: Float
      // + any widget-specific field (e.g. stockCode, repository, appId)
  }
  ```

  ⚠️ `componentIdentifier` must be **globally unique** across every widget in every package — follow the `daashi.<package>.<widget>` convention (see existing examples: `daashi.currency.exchange-rate`, `daashi.github.pull-request-counter`, `daashi.amplitude.monthly-active-user`, `daashi.appRating.appStore-counter`, `daashi.alphavantage.stock-price`).

- **`<Widget>ViewModel.swift`** — `@MainActor class ... : ObservableObject` with `@Published` **display-ready `String` properties only** (formatting happens in the EventHandler, not here).

- **`<Widget>ViewDelegate.swift`** — optional protocol for user interactions from the View back to the EventHandler (e.g. tap-to-refresh). Can be an empty protocol if unused.

- **`<Widget>View.swift`** — the SwiftUI content. Keep it dumb: it only reads the ViewModel and calls the delegate. End the file with a `#Preview` using `.toWidget()` from `WidgetFoundation`.

- **`<Widget>ConfigView.swift`** (or `<Widget>ConfiguratorView.swift`) — a SwiftUI `Form` to edit the `Config`, with an `onSave` callback. Include a refresh-interval `Slider` (`15...180`, step `15`) unless the widget has no polling.

- **`<Widget>EventHandler.swift`** — the only file that imports `WidgetFoundation` in the UI layer:

  ```swift
  @MainActor
  class <Widget>EventHandler {
      var viewModel: <Widget>ViewModel
      var interactor: <Widget>InteractorProtocol
      var config: <Widget>Config

      required init(config: <Widget>Config, viewModel: <Widget>ViewModel, interactor: <Widget>InteractorProtocol) {
          self.config = config; self.viewModel = viewModel; self.interactor = interactor
      }

      @MainActor
      func setViewModel(_ model: <Widget>) { /* map domain model -> formatted viewModel strings */ }

      @MainActor
      func performAsyncTask() async {
          Task { [weak self] in
              guard let self else { return }
              do {
                  let model = try await interactor.get<Widget>(...)
                  setViewModel(model)
              } catch { print("Error: \(error)") }
          }
      }

      func startFifteenMinuteLoop() {
          Task {
              await performAsyncTask()
              while !Task.isCancelled {
                  try? await Task.sleep(for: .seconds(60 * Double(config.refreshInterval)))
                  guard !Task.isCancelled else { break }
                  await performAsyncTask()
              }
          }
      }
  }

  extension <Widget>EventHandler: <Widget>ViewDelegate { /* handle user actions, or leave empty */ }

  extension <Widget>EventHandler: WidgetEventHandlerProtocol {
      func onLoad() { startFifteenMinuteLoop() }
      func onUnload() { }
  }
  ```

## 5. Write the Pack Descriptor (`Sources/<Name>WidgetPackDescriptor.swift`)

One descriptor per package, listing every widget it provides:

```swift
import WidgetFoundation
import SwiftUI

public struct <Name>WidgetPackDescriptor: WidgetPackDescriptor {

    public static var packInfo: WidgetPackInfo {
        WidgetPackInfo(
            name: "<Display Name>",
            description: "<one-line description of what this pack does>",
            image: Image("ic_widgetPack_<abbr>", bundle: .module)
        )
    }

    public static var widgets: [WidgetFoundation.Widget] {
        [
            Widget(
                identifier: <Widget>Config.componentIdentifier,
                name: "<Widget display name>",
                description: "<one-line description>",
                image: Image("ic_<widget>", bundle: .module),
                availableFormFactor: [.square],
                availableSize: [.small]
            )
            // + one Widget entry per widget in this pack
        ]
    }

    public static func configType(for identifier: String) -> WidgetFoundation.WidgetConfigPayload.Type {
        switch identifier {
        case <Widget>Config.componentIdentifier: return <Widget>Config.self
        default: break
        }
        fatalError("Unable to find config for \(identifier)")
    }

    @MainActor
    public static func makeView<T>(for identifier: String, config: T) -> (AnyView, any WidgetEventHandlerProtocol) where T: WidgetConfigPayload {
        switch identifier {
        case <Widget>Config.componentIdentifier:
            if let config = config as? <Widget>Config {
                let viewModel = <Widget>ViewModel()
                let eventHandler = <Widget>EventHandler(
                    config: config,
                    viewModel: viewModel,
                    interactor: <Widget>Interactor(store: <Widget>Store(token: config.apiToken))
                )
                let view = <Widget>View(viewModel: viewModel, delegate: eventHandler)
                return (AnyView(view), eventHandler)
            }
        default: break
        }
        fatalError("Unable to make view for identifier: \(identifier)")
    }

    @MainActor
    public static func makeConfigurator(for identifier: String, config: (any WidgetConfigPayload)?, onSave: @escaping (any WidgetConfigPayload) -> Void) -> AnyView {
        switch identifier {
        case <Widget>Config.componentIdentifier:
            if let config = config as? <Widget>Config? {
                return AnyView(<Widget>ConfigView(previousConfig: config, onSave: onSave))
            }
        default: break
        }
        fatalError("Unable to make configurator view for identifier: \(identifier)")
    }
}
```

## 6. Naming & config conventions (cheat sheet)

| Item | Convention | Example |
|---|---|---|
| Package/library name | `<Name>Widget` (PascalCase, no spaces) | `AlphavantageWidget` |
| Feature folder | `Sources/<Widget>/{Data,Domain,UI}` | `Sources/StockPrice/...` |
| `componentIdentifier` | `daashi.<package>.<widget-kebab-case>` | `daashi.alphavantage.stock-price` |
| Config type | `<Widget>Config: WidgetConfigPayload` (`Codable`) | `StockPriceConfig` |
| Refresh interval field | `var refreshInterval: Float`, range `15...180`, step `15` | — |
| Error enum | `enum Error: Swift.Error { case invalidUrl, invalidResponse }` on the Store | — |

## 7. Register the package in the host app

Once the package builds, add it to Daashi's catalog (not part of the widget package itself):

1. Add the SPM dependency to the host app / its aggregating package.
2. `import <Name>Widget` in `HomeViewViewBuilder+Catalog.swift`.
3. Append an entry to `widgetCatalog`:
   ```swift
   ("<Display Name>", <Name>WidgetPackDescriptor.self, "v1.0.0")
   ```

## 8. Known pitfalls (learned the hard way)

- **SPM dependency pinning**: always use `from: "x.y.z"` (or `exact:`), never `branch: "x.y.z"`. A `branch:`-pinned dependency is "unstable" to SPM's resolver and breaks resolution once *your* package is required at a stable version range.
- **Locale-unaware number parsing**: `NumberFormatter()` defaults to `.none` style and the device locale. If a scraped/parsed string uses a comma decimal separator (e.g. `"4,8"`) or non-breaking spaces as thousands separators (`"23\u{00A0}300"`), set `numberFormatter.numberStyle = .decimal`, `decimalSeparator = ","`, and `groupingSeparator = "\u{00A0}"` explicitly — don't rely on the default locale.
- **HTML scraping selectors**: prefer selectors on stable attributes (`data-testid`, `aria-label`) over CSS classes, especially for frameworks that hash class names per build (e.g. Svelte-based pages use classes like `svelte-1r39353` that change across deployments). Always re-verify selectors against a fresh HTML snapshot before shipping.
- **`Element.ownText()` (SwiftSoup)**: only returns text nodes that are *direct* children of the element — if the value you need lives in a nested `<span>`, select that child element first, then call `.ownText()` on it.
- **"k" / thousands abbreviations**: when a scraped count includes a `"k"` suffix (e.g. `"13 k notes"`, `"23,3 k avis"`), parse the numeric part as a `Double` (it may have a fractional part) and multiply by 1000, rounding — don't truncate to `Int` before multiplying, or `"23,3 k"` becomes `23000` instead of `23300`.
- **Config persistence**: `WidgetConfigPayload` structs are serialized to JSON and stored per dashboard component — keep them small and flat, and never add non-`Codable` fields.
