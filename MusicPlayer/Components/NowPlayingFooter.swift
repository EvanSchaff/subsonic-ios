//
//  NowPlayingFooter.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/18/24.
//
import SwiftUI

struct NowPlayingFooter: View {
    let albumArt: Image
    let songTitle: String
    let artistName: String
    @Binding var isPlayerViewVisible: Bool
    @State private var dragOffset: CGFloat = 0
    @ObservedObject private var player = PlayerViewModel.shared  // Add this line
    
    
    
    var body: some View {
        HStack(spacing: 10) {
            albumArt
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .shadow(radius: 2)
            
            VStack(alignment: .leading) {
                Text(songTitle)
                    .foregroundColor(.primary)
                Text(artistName)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .shadow(radius: 5)
        .offset(y: dragOffset)
        .onTapGesture {
            withAnimation {
                isPlayerViewVisible.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = max(value.translation.height, -200)
                        
                        if dragOffset <= -150 {
                            withAnimation {
                                isPlayerViewVisible = true
                                dragOffset = 0
                            }
                        }
                    }
                }
                .onEnded { value in
                    withAnimation(.easeOut) {
                        if !isPlayerViewVisible {
                            dragOffset = 0
                        }
                    }
                }
        )
        .fullScreenCover(isPresented: $isPlayerViewVisible) {
            PlayerView()
        }
        .onChange(of: player.showPlayer) { _, newValue in
            if newValue {
                isPlayerViewVisible = true
                player.showPlayer = false
            }
        }
    }
}
