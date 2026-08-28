//
//  WidgetPackDescriptor.swift
//  WidgetFoundation
//
//  Created by Jean DAHER on 27/08/2026.
//

import SwiftUI

public protocol WidgetConfigPayload: Codable {
    static var componentIdentifier: String { get }
}

public protocol WidgetPackDescriptor {

    static var packInfo: WidgetPackInfo { get }

    static var widgets: [Widget] { get }
    
    static func configType(
        for identifier: String
    ) -> WidgetConfigPayload.Type
    
    @MainActor
    static func makeView<T: WidgetConfigPayload>(
        for identifier: String,
        config: T
    ) -> (AnyView, WidgetEventHandlerProtocol)
    
    @MainActor
    static func makeConfigurator(
        for identifier: String,
        config: (any WidgetConfigPayload)?,
        onSave: @escaping (any WidgetConfigPayload) -> Void
    ) -> AnyView
}

public extension WidgetPackDescriptor {
    @MainActor
    public static func makeConfigurator(
        for identifier: String,
        onSave: @escaping (any WidgetConfigPayload) -> Void
    ) -> AnyView {
        self.makeConfigurator(for: identifier, config: nil, onSave: onSave)
    }
}
