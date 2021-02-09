//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Pengfei Chen on 2/6/21.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
            }
            
        }
        
    }
}

