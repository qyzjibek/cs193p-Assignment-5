//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Zhibek Rahymbekkyzy on 01.08.2022.
//

import Foundation
// CGFloat is not in Foundation

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        var id: Int
        
        // anyone in this file
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    init() {}
    
    private var uniqueEmojiId = 0
    
    mutating func removeEmoji(_ emoji: Emoji) {
        emojis.remove(emoji)
    }
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
    
    mutating func editEmojiCoordinate(of emoji: Emoji, for offset: (x: Int, y: Int)) {
        emojis[emoji].x += offset.x
        emojis[emoji].y += offset.y
    }
    
    mutating func editEmojiSize(of emoji: Emoji, for scale: Int) {
        emojis[emoji].size *= scale
        print(emojis[emoji].size)
    }
    
}
