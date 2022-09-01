//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Zhibek Rahymbekkyzy on 02.08.2022.
//

import SwiftUI

// view models are always class

class EmojiArtDocument: ObservableObject {
    
    // ony can be set
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchImageDataBackgroundIfNecessary()
            }
        }
    }
    
    init () {
        emojiArt = EmojiArtModel()
        emojiArt.addEmoji("🐹", at: (-200, 200), size: 80)
        emojiArt.addEmoji("🦄", at: (50, 100), size: 40)
    }
    
    var emojis: [EmojiArtModel.Emoji] {emojiArt.emojis}
    var background: EmojiArtModel.Background {emojiArt.background}
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus: BackgroundImageFetchStatus = .idle
    
    enum BackgroundImageFetchStatus {
        case idle
        case fetching
    }
    
    private func fetchImageDataBackgroundIfNecessary() {
        backgroundImage = nil
        
        switch emojiArt.background {
        case .url(let url):
            // fetch the url -> it is important to never block your UI
            backgroundImageFetchStatus = .fetching
            
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = try? Data(contentsOf: url) // try this, if it fails return nil
                
                // closures are reference types like classes therefore it lives in the memory somewhere
                DispatchQueue.main.async { [weak self] in
                    
                    // check if the world wants the same as they wanted 5 minutes ago
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self?.backgroundImageFetchStatus = .idle
                        if imageData != nil {
                            // self is ViewModel and it stays in heap even when someone closes the app
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func removeEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.removeEmoji(emoji)
    }
    
    func editEmojiCoordinate(of emoji: EmojiArtModel.Emoji, for offset: (x: Int, y: Int)){
        emojiArt.editEmojiCoordinate(of: emoji, for: offset)
    }
    
    func editEmojiSize(of emoji: EmojiArtModel.Emoji, for scale: Int) {
        emojiArt.editEmojiSize(of: emoji, for: scale)
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
    
}
