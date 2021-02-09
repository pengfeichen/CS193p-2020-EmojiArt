//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/3/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var emojiSelection = Set<EmojiArt.Emoji>()

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
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))

                    

                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emojiSelection.contains(matching: emoji) ? emoji.fontSize * steadyStateZoomScale * gestureZoomScale : emoji.fontSize * zoomScale)
                            .background(emojiSelection.contains(matching: emoji) ? Color.orange : nil)
                            .position(position(for: emoji, in: geometry.size))
                            // Add TapGesture listener
                            // Add LongPressGesture listener
                            // Compose two gestures
                            .gesture(singleTapToSelect(emoji).exclusively(before: longPressGesture(emoji)))
                            // Add DragGesture listner.
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
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)

                    return drop(providers: providers, at: location)
                }
            }

            Button("New") {
                document.newEmojiArt()
            }
            .padding()
        }

    }
    
    
    // TapGesture handler
    private func singleTapToSelect(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                emojiSelection.toggleMatching(emoji)
            }
    }



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
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    // Scale the emojis if there is a selection, or scale the entire document is there is not selection.
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
    

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    // Record offset by DragGesture.
    private var dragOffset: CGSize {
        gestureDragOffset * zoomScale
    }
    
    // Add Gesture state to update view during a DrageGesture. @GestureState will always return to the startValue set here after the event.
    @GestureState private var gestureDragOffset: CGSize = .zero

    
    // Extra Credits: Allow dragging unselected emoji separately.
    @State private var selectedEmoji: EmojiArt.Emoji?
    
    private func dragEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureDragOffset) { latestDragGestureValue, gestureDragOffset, transaction in
                gestureDragOffset = latestDragGestureValue.translation / zoomScale
            }
            .onChanged { _ in
                selectedEmoji = emoji
            }
            .onEnded { finalDragGestureValue in
                let offSet = finalDragGestureValue.translation / zoomScale
                
                if emojiSelection.contains(matching: emoji) {
                    for emoji in emojiSelection {
                        document.moveEmoji(emoji, by: offSet)
                    }
                } else {
                    document.moveEmoji(emoji, by: offSet)
                }
                
                selectedEmoji = nil
            }
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
        }
        .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
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

    // Update position of each emoji accordingly.
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint  {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        // Check if there is a selectedEmoji
        if let selectedEmoji = selectedEmoji {
            if emojiSelection.contains(matching: selectedEmoji), emojiSelection.contains(matching: emoji){
                location = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
            } else if emoji == selectedEmoji {
                location = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
            }
        }

        return location

    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self)  { string in
                document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
    private let defaultEmojiSize: CGFloat =  40

}

