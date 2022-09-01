//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Zhibek Rahymbekkyzy on 01.08.2022.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
