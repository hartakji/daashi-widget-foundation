//
//  WidgetEventHandlerProtocol.swift
//  WidgetFoundation
//
//  Created by Jean DAHER on 27/08/2026.
//

import Foundation

public protocol WidgetEventHandlerProtocol {
    func onLoad()
    func onUnload()
    func onDelete()
}

public extension WidgetEventHandlerProtocol {
    func onLoad() {}
    func onUnload() {}
    func onDelete() {}
}
