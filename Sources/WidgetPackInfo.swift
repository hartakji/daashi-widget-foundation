//
//  WidgetPackInfo.swift
//  WidgetFoundation
//
//  Created by Jean DAHER on 27/08/2026.
//

import SwiftUI

public struct WidgetPackInfo {
    
    public var name: String
    public var description: String
    public var image: Image
    
    public init(
        name: String,
        description: String,
        image: Image
    ) {
        self.name = name
        self.description = description
        self.image = image
    }
}
