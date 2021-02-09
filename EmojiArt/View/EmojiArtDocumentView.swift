//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/3/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map { String($0)}, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack {

                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))

                    

                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emojiSelection.contains(matching: emoji) ? emoji.fontSize * steadyStateZoomScale * gestureZoomScale : emoji.fontSize * zoomScale)
                            .background(emojiSelection.contains(matching: emoji) ? Color.orange : nil)
                            .position(position(for: emoji, in: geometry.size))
                            .gesture(singleTapToSelect(emoji).exclusively(before: longPressGesture(emoji)))
                            .gesture(dragEmojiGesture(emoji))
                        
                    }

                }
                .clipped()
                .onTapGesture() { emojiSelection.removeAll() }
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)

                    return self.drop(providers: providers, at: location)
                }
            }

            Button("New") {
                document.newEmojiArt()
            }
            .padding()
        }

    }
    
    @State private var emojiSelection = Set<EmojiArt.Emoji>()
    
    private func singleTapToSelect(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                print("single tapped")
                emojiSelection.toggleMatching(emoji)
            }
    }

    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0

    private var zoomScale: CGFloat {
        emojiSelection.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale

    }
    
    private func longPressGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        LongPressGesture(minimumDuration: 1)
            .onEnded { finished in
                print("long press ended: \(finished)")
                document.deleteEmoji(emoji)
            }
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                if emojiSelection.isEmpty {
                    steadyStateZoomScale *= finalGestureScale
                } else {
                    for emoji in emojiSelection {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
            }
    }

    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    @GestureState private var gestureDragOffset: CGSize = .zero

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var dragOffset: CGSize {
        gestureDragOffset * zoomScale
    }
    
    private func dragEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureDragOffset) { latestDragGestureValue, gestureDragOffset, transaction in
                gestureDragOffset = latestDragGestureValue.translation / zoomScale
                
            }
            .onEnded { finalDragGestureValue in
                let offSet = finalDragGestureValue.translation / zoomScale
                
                for emoji in emojiSelection {
                    document.moveEmoji(emoji, by: offSet)
                }
            }
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0 , image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom,vZoom)
        }
    }


    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint  {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if emojiSelection.contains(matching: emoji) {
            location = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
        }

        return location

    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self)  { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    private let defaultEmojiSize: CGFloat =  40

}

