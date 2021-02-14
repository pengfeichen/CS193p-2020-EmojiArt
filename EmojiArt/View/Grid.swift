//
//  Grid.swift
//  Memorize
//
//  Created by Pengfei Chen on 1/10/21.
//

import SwiftUI

extension Grid where Item: Identifiable, ID == Item.ID {
    init(_ items: [Item], viewForItem: @escaping (Item) -> ItemView) {
        self.init(items, id: \Item.id, viewForItem: viewForItem)
    }
}

struct Grid<Item, ID, ItemView>: View where ItemView: View, ID: Hashable {
    
    var items: [Item]
    private var id: KeyPath<Item, ID>
    var viewForItem: (Item) -> ItemView
    
    init(_ items: [Item], id: KeyPath<Item, ID>, viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.id = id
        self.viewForItem = viewForItem
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            let layout = GridLayout(itemCount: items.count, in:geometry.size)
            ForEach(items, id: id) { item in
                let index = items.firstIndex(where: { item[keyPath: id] == $0[keyPath: id] })
                    viewForItem(item)
                    .frame(width: layout.itemSize.width, height: layout.itemSize.height)
                    .position(layout.location(ofItemAt: index!))
            }
        }

    }
}



