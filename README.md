# WidgetFoundation

A Swift Package that defines the shared contract for building widgets in the Daashi widget app.

`WidgetFoundation` contains no concrete widgets itself — it only describes what a widget **is** and what a widget **pack** must provide. Concrete widget packages (e.g. [`daashi-currency-widget`](https://github.com/hartakji/daashi-currency-widget)) depend on this package and conform to its protocols to plug their widgets into the host app.

## Requirements

- iOS 16.0+
- Swift 5.9+

## Installation

Add the package as a Swift Package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/hartakji/daashi-widget-foundation", from: "1.0.0")
]
```

> Pin a version (`from:`, `.upToNextMajor(from:)`, `exact:`, etc.) rather than tracking a branch, so breaking changes surface as resolvable dependency errors instead of being silently masked.

## Core Concepts

### `Widget`
Describes a single widget: its `identifier`, `name`, `description`, `image`, and the form factors (`availableFormFactor`) and sizes (`availableSize`) it supports.

### `WidgetShape` / `WidgetSize`
Enumerate the supported layouts (`square`, `vRectangle`, `hRectangle`) and sizes (`small`, `medium`, `large`) a widget can be displayed in.

### `WidgetPackInfo`
Metadata for a widget pack as a whole: `name`, `description`, and `image`, used to present the pack in the host app's widget gallery.

### `WidgetConfigPayload`
A `Codable` protocol that every widget's configuration model must conform to, identified by a `componentIdentifier`.

### `WidgetPackDescriptor`
The main protocol a widget package implements to expose its widgets to the host app:

- `packInfo`: the pack's display metadata.
- `widgets`: the list of `Widget`s the pack provides.
- `configType(for:)`: maps a widget identifier to its `WidgetConfigPayload` type.
- `makeView(for:config:)`: builds the widget's SwiftUI view and its `WidgetEventHandlerProtocol` for a given configuration.
- `makeConfigurator(for:config:onSave:)`: builds the SwiftUI configuration/settings view for a widget.

### `WidgetEventHandlerProtocol`
Lifecycle hooks (`onLoad`, `onUnload`, `onDelete`) a widget's event handler can implement; all have empty default implementations.

### `WidgetViewModifier` / `View.toWidget(size:shape:color:)`
A SwiftUI view modifier that frames and styles a view according to a given `WidgetSize` and `WidgetShape`, adapting to iPad vs. other idioms.

## Usage

A widget package implements `WidgetPackDescriptor` to describe its pack and widgets, and the host app uses that descriptor to list available widgets, render them (`makeView`), and configure them (`makeConfigurator`) without depending on any widget-specific implementation.

```swift
import WidgetFoundation

struct MyWidgetPackDescriptor: WidgetPackDescriptor {
    static var packInfo: WidgetPackInfo {
        WidgetPackInfo(name: "My Widgets", description: "...", image: Image("icon"))
    }

    static var widgets: [Widget] {
        [Widget(identifier: "my.widget", name: "My Widget", description: "...",
                image: Image("widget-icon"), availableFormFactor: [.square], availableSize: [.small])]
    }

    static func configType(for identifier: String) -> WidgetConfigPayload.Type { /* ... */ }

    static func makeView<T: WidgetConfigPayload>(for identifier: String, config: T) -> (AnyView, WidgetEventHandlerProtocol) { /* ... */ }

    static func makeConfigurator(for identifier: String, config: (any WidgetConfigPayload)?, onSave: @escaping (any WidgetConfigPayload) -> Void) -> AnyView { /* ... */ }
}
```

## License

This project has no license file yet. All rights reserved unless stated otherwise.
