//
//  WidgetViewModifier.swift
//
//
//  Created by Jean DAHER on 06/08/2024.
//

import SwiftUI

public struct WidgetViewModifier: ViewModifier {
    
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    internal let size: WidgetSize
    internal let shape: WidgetShape
    internal let color: Color
    
    init(size: WidgetSize, shape: WidgetShape, color: Color) {
        self.size = size
        self.shape = shape
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        if idiom == .pad {
            content
                // .padding(5)
                // .scaleEffect(1)
                .frame(width: frameSize.width, height: frameSize.height)
                .background(color)
                .cornerRadius(20)
        } else {
            content
                // .padding(5)
                // .scaleEffect(0.66)
                .frame(width: frameSize.width, height: frameSize.height)
                .background(color)
                .cornerRadius(15)
        }
    }
    
    private var frameSize: CGSize {
        let carreSize: CGFloat = idiom == .pad ? 150 : 110

        switch (size, shape) {
        case (.small, .square):      return CGSize(width: 1*carreSize, height: 1*carreSize)
        case (.small, .vRectangle):  return CGSize(width: 1*carreSize, height: 2*carreSize)
        case (.small, .hRectangle):  return CGSize(width: 2*carreSize, height: 1*carreSize)

        case (.medium, .square):     return CGSize(width: 2*carreSize, height: 2*carreSize)
        case (.medium, .vRectangle): return CGSize(width: 2*carreSize, height: 3*carreSize)
        case (.medium, .hRectangle): return CGSize(width: 3*carreSize, height: 3*carreSize)

        case (.large, .square):      return CGSize(width: 3*carreSize, height: 3*carreSize)
        case (.large, .vRectangle):  return CGSize(width: 3*carreSize, height: 5*carreSize)
        case (.large, .hRectangle):  return CGSize(width: 4*carreSize, height: 3*carreSize)
        }
    }
}

public extension View {
    func toWidget(size: WidgetSize = .small, shape: WidgetShape = .square, color: Color = .gray) -> some View {
        modifier(WidgetViewModifier(size: size, shape: shape, color: color))
    }
}
