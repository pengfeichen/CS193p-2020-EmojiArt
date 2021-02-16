//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/3/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var store = EmojiArtDocumentStore(named: "Emoji Art")
    var body: some Scene {
        return WindowGroup {
            //Lecture 10
            EmojiArtDocumentChooser().environmentObject(store)
//            EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
