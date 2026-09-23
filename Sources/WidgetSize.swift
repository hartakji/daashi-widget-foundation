//
//  WidgetSize.swift
//
//
//  Created by Jean DAHER on 22/08/2024.
//

import Foundation

public enum WidgetSize {
    case small
    case medium
    case large
}

public extension Array where Element == WidgetSize {
    static var allValues: Self {
        [.small, .medium, .large]
    }
}
