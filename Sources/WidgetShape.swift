//
//  WidgetShape.swift
//  
//
//  Created by Jean DAHER on 22/08/2024.
//

import Foundation

public enum WidgetShape {
    case square
    case vRectangle
    case hRectangle
}

public extension Array where Element == WidgetShape {
    public static var allValues: Self {
        [.square, .vRectangle, .hRectangle]
    }
}
