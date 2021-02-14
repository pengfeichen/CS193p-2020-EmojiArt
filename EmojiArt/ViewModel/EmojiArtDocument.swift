//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/3/21.
//

import SwiftUI
// AnyCancellable is part of Combine
import Combine

class EmojiArtDocument: ObservableObject {
    
    static let palette: String = "🍎🍍🍅🍆🥒🥬🥦🧄🫑🧀🥨"
    
    @Published private var emojiArt: EmojiArt
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    private var autosaveCancellable: AnyCancellable?
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        autosaveCancellable = $emojiArt.sink { emojiArt in
            print("\(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.setValue(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
        fetchBackgroundImageData()
    }
    
    @Published private (set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // MARK: - Intents
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func deleteEmoji(_ emoji: EmojiArt.Emoji) {
        emojiArt.deleteEmoji(emoji)
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }

    }
    
    func newEmojiArt() {
        emojiArt = EmojiArt()
        fetchBackgroundImageData()
    }
    private var fetchImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            // cancel the previous subscriber
            fetchImageCancellable?.cancel()
            // URLSession.shared to do simple download, which returns a publisher for the contents of the url.
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) }
                // publish on main que, returns a publisher
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                //assign is a subscriber and only works when you have NEVER as the error, returns a AnyCancellable
                .assign(to: \.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
