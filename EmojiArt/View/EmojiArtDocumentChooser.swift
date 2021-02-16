//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/15/21.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document:document)
                                    .navigationTitle(store.name(for: document))
                    ){
                        EditableText(store.name(for:document), isEditing: editMode.isEditing) { name in
                            store.setName(name, for: document)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { document in
                        store.removeDocument(document)

                    }
                }
            }
            .navigationTitle(store.name)
            .navigationBarItems(
                leading: Button(action: {
                store.addDocument()
            },
            label: {Image(systemName: "plus").imageScale(.large)}),
                trailing: EditButton())
            // Only sets the environment on the View that you are calling environment on. The view needs to have an EditButton()
            .environment(\.editMode, $editMode)
            .onAppear {
                if store.documents.isEmpty {
                    store.addDocument()
                    store.addDocument(named: "New file")
                }
            }
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
