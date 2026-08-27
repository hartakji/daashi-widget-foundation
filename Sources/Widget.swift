//
//  Widget.swift
//  WidgetFoundation
//
//  Created by Jean DAHER on 27/08/2026.
//

import SwiftUI

public struct Widget {
    
    public var identifier: String
    public var name: String
    public var description: String
    public var image: Image
    public var availableFormFactor: [WidgetShape]
    public var availableSize: [WidgetSize]
    
    public init(
        identifier: String,
        name: String,
        description: String,
        image: Image,
        availableFormFactor: [WidgetShape],
        availableSize: [WidgetSize]
    ) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.image = image
        self.availableFormFactor = availableFormFactor
        self.availableSize = availableSize
    }
}
