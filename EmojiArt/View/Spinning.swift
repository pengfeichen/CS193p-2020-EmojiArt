//
//  Spinning.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/10/21.
//

import SwiftUI

struct Spinning : ViewModifier {
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isVisible ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear { isVisible = true }
    }
}

extension View {
    func spinning() -> some View {
        self.modifier(Spinning())
    }
}
