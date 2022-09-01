//
//  ContentView.swift
//  EmojiArt
//
//  Created by Zhibek Rahymbekkyzy on 01.08.2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []
    
    let defaultEmojiSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay {
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                }
                .gesture(doubleTabToZoom(in: geometry.size).exclusively(before: singleTapToDeselect()))// precedence to first
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .border(selectedEmojis.contains(emoji) ? Color.blue : Color.clear)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(positionFor(for: emoji, in: geometry))
                            .gesture(selectGesture(emoji).exclusively(before: longPressGesture(on: emoji)))
                    }
//                    .gesture(emojisPanGesture())
                }
            }
            .clipped() // don't draw outside of your space
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture())) // don't put more than one gesture
        }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }
        
        // Image draws a view, whereas UIImage is actual image
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(EmojiArtModel.Background.imageData(data))
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji),
                                      at: convertToEmojiCoordinates(location, in: geometry),
                                      size: defaultEmojiSize / zoomScale)
                }
            }
        }
        
        return found
    }
    
    //MARK: - Converting
    
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(x: (location.x - panOffset.width - center.x)/zoomScale,
                               y: (location.y - panOffset.height - center.y)/zoomScale)
        
        return (Int(location.x), Int(location.y))
    }
    
    private func positionFor(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        // when you pass tuple, ypu don't have to specify the arguments
        convertFromEmojiCoordinates((emoji.x , emoji.y), in: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint{
        let center = geometry.frame(in: .local).center
        
        return CGPoint (
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width ,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    // MARK: - Dragging
    // Dragging around - panning around
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
        // underbar if you don't use it
            .updating($gesturePanOffset, body: { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            })
            .onEnded { finalDragGestureValue in
                // what if we zoomed and dragged, so i am not dragging as much the document
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    
    @State private var emojiSteadyStatePanOffSet: CGSize = CGSize.zero
    @GestureState private var emojiGesturePanOffset: CGSize = CGSize.zero
    
    private var emojiPanoffSet : CGSize {
        (emojiSteadyStatePanOffSet + emojiGesturePanOffset) * zoomScale
    }

    private func emojisPanGesture() -> some Gesture {
        DragGesture()
            .updating($emojiGesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                emojiSteadyStatePanOffSet = emojiSteadyStatePanOffSet + (finalDragGestureValue.translation / zoomScale)
                for emoji in selectedEmojis {
                    document.editEmojiCoordinate(of: document.emojis[emoji], for: (Int(emojiPanoffSet.width), Int(emojiPanoffSet.height)))
                }
            }
    }
    
    // MARK: - Zooming
    
    @State private var steadyZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        //  non-discrete gesture
        MagnificationGesture()
            .updating($gestureZoomScale, body: { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            })
            .onEnded { gestureScaleAtEnd in
                steadyZoomScale *= gestureScaleAtEnd
                for emoji in selectedEmojis {
                    document.editEmojiSize(of: emoji, for: Int(zoomScale))
                }
            }
    }
    
    private func doubleTabToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func singleTapToDeselect() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation {
                    selectedEmojis = []
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyZoomScale = min(hZoom, vZoom)
        }
    }
    
    //MARK: - LongPressing
    
    private func longPressGesture(on emoji: EmojiArtModel.Emoji) -> some Gesture {
        LongPressGesture()
            .onEnded { _ in
                document.removeEmoji(emoji)
            }
    }
    
    private func selectGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                if selectedEmojis.contains(emoji) {
                    selectedEmojis.remove(emoji)
                } else {
                    selectedEmojis.insert(emoji)
                }
            }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testemojis)
            .font(.system(size: defaultEmojiSize))
    }
    
    
    
    let testemojis = "😈🤡💩👁🐣"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                // strings are not identifiable
                ForEach(emojis.map { String($0)}, id: \.self) { emoji in
                    Text(emoji)
                    // async, does it in background
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
