//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/10/21.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @State private var showPaletteEditor = false
    var body: some View {
        HStack {
            Stepper(
                onIncrement: {
                    chosenPalette = document.palette(after: chosenPalette)
                },
                onDecrement: {
                    chosenPalette = document.palette(before: chosenPalette)
                },
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[chosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    showPaletteEditor = true
                }
                // sheet / popover both works here
                .popover(isPresented: $showPaletteEditor){
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                }
            
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
}


struct PaletteEditor: View {
    @Binding var chosenPalette: String
    @EnvironmentObject var document: EmojiArtDocument
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    @State private var emojisToRemove: String = ""
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button("Done") {
                        isShowing  = false
                    }
                    .padding()
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Palette Name", text: $paletteName) { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    }
                    TextField("Add Emoji", text: $emojisToAdd) { began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd , toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    }
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0)}, id: \.self ) { emoji in
                        Text(emoji).font(Font.system(size: fontSize))
                            .onTapGesture {
                                chosenPalette = document.removeEmoji(emoji, fromPalette: chosenPalette)
                            }
                    }
                    .frame(height: height)
                    
                }

                
            }
        }
        .onAppear{ paletteName = document.paletteNames[chosenPalette] ?? "" }
    }
    // MARK - Drawing constants
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
