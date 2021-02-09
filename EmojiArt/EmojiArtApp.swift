//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/3/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
