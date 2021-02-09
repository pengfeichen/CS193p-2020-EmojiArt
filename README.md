# Course Stanford CS193p 2020 - Solutions for Assignment 4 Emoji Art
> 
> Projects are written in **Swift 5.1** and **Xcode Version 12.4**
>

## Emoji Art 
#### Required Tasks

1. Download the version of EmojiArt from Lecture 8. Do not break anything that is
working there as part of your solution to this assignment. 
>[Click here to download starting code.](https://web.stanford.edu/class/cs193p/Spring2020/EmojiArtL8.zip)

2. Support the selection of one or more of the emojis which have been dragged into
your EmojiArt document (i.e. you’re selecting the emojis in the document, not the ones
in the palette at the top). You can show which emojis are selected in any way you’d
like. The selection is not persistent (in other words, restarting your app will not
preserve the selection).
>1. The *selection* is a UI thing, so it should be handled in the *View*.
>2. The *selection* is not persistent, so it should be declared a `@State` variable.
>3. Show selected emojis by changing the background color to orange.
```swift
// View - EmojiArtDocumentView.swift
@State private var emojiSelection = Set<EmojiArt.Emoji>()

Text(emoji.text)
.background(emojiSelection.contains(matching: emoji) ? Color.orange : nil)
```
3. Tapping on an unselected emoji should select it. 
4. Tapping on a selected emoji should unselect it. 
> 1. To selected and unselect an emoji, we need to add `gesture()` view modifier for each emoji, and a gesture function `singleTapToSelect(_ emoji:)` to return a `TapGesture` to handle the action.
>2. `singleTapToSelect(_ emoji:)` will call function after a `TapGesture` to toggle the selection of the emoji. We create this function through adding an extension to `Set` called `toggleMatching(_ item:)`
```swift
// View - EmojiArtDocumentView.swift

// Add TapGesture listener
Text(emoji.text)
  .gesture(singleTapToSelect(emoji))

// TapGesture handler
private func singleTapToSelect(_ emoji: EmojiArt.Emoji) -> some Gesture {
    TapGesture(count: 1)
        .onEnded {
            emojiSelection.toggleMatching(emoji)
        }
}

//Extension - EmojiArtExentions.swift

// Extension to Set
extension Set where Element: Identifiable {
    mutating func toggleMatching(_ item: Element) {
        if let index = self.firstIndex(matching: item) {
            self.remove(at: index)
        } else {
            self.insert(item)
        }
    }
}
```
5. Single-tapping on the background of your EmojiArt (i.e. single-tapping anywhere
except on an emoji) should deselect all emoji. 
> 1. Add `onTapGesture` to `ZStack` to remove all emojis in the `Set`.
```swift
// View - EmojiArtDocumentView.swift
ZStack {
  //Code
}
.onTapGesture() { emojiSelection.removeAll() }
```
6. Dragging a selected emoji should move the entire selection to follow the user’s finger. 
>1. To drag a selected emoji, we need to add `gesture()` view modifier for each emoji, and a gesture function `dragEmojiGesture(_ emoji:)` to return a `DragGesture` to handle the action. 
```swift
// View - EmojiArtDocumentView.swift

// Add DragGesture listner.
Text(emoji.text)
  .gesture(dragEmojiGesture(emoji))

// Record offset by DragGesture.
private var dragOffset: CGSize {
    gestureDragOffset * zoomScale
}
// Add Gesture state to update view during a DrageGesture. @GestureState will always return to the startValue set here after the event.
@GestureState private var gestureDragOffset: CGSize = .zero

// DragGesture handler.
private func dragEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
  DragGesture()
      .updating($gestureDragOffset) { latestDragGestureValue, gestureDragOffset, transaction in
          gestureDragOffset = latestDragGestureValue.translation / zoomScale
      }
      .onEnded { finalDragGestureValue in
          let offSet = finalDragGestureValue.translation / zoomScale

          if emojiSelection.contains(matching: emoji) {
              for emoji in emojiSelection {
                  document.moveEmoji(emoji, by: offSet)
              }
          } 
      }
}
```
