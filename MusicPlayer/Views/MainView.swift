//
//  MainView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI
import UIKit

struct MainView: View {
    @StateObject private var musicViewModel = MusicViewModel()
    @State private var isScrolling = false
    @State private var showAlbumView = false
    let albumImages = Array(repeating: "test_album", count: 10)
    
    let songs = [
        (title: "Song 1", artist: "Artist 1"),
        (title: "Song 2", artist: "Artist 2"),
        (title: "Song 3", artist: "Artist 3")
    ]
    
    var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Recently Added Section
                    sectionWithHorizontalScroll(
                        title: "Recently Added",
                        items: musicViewModel.recentAlbums
                    )
                    
//                    // Recently Played Section
//                    sectionWithVerticalList(
//                        title: "Recently Played",
//                        songs: songs
//                    )
                    
                    // Frequently Played Section
                    sectionWithHorizontalScroll(
                        title: "Frequently Played",
                        items: musicViewModel.frequentAlbums
                    )
                    
                    // Random Album Section
                    sectionWithHorizontalScroll(
                        title: "Random Album",
                        items: musicViewModel.randomAlbums
                    )
                    Spacer()
                        .frame(height: 80) // Adjust the height as needed
                }
                .padding(.vertical)
            }
            .modifier(KeyboardAdaptive())
            .refreshable {
                musicViewModel.loadAlbums()
            }
    }
    
    private func sectionWithHorizontalScroll(title: String, items: [Album]) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items, id: \.id) { album in
                        NavigationLink(destination: AlbumView(album: album)) {
                            VStack(alignment: .leading, spacing: 8) {
                                if let albumArt = album.image {
                                    Image(uiImage: albumArt)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                } else {
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                }
                                
                                Text(album.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text(album.artist)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(width: 120)
                        }
                        .buttonStyle(NoHighlightButtonStyle())
                        .simultaneousGesture(
                            TapGesture(count: 1)
                                .onEnded { _ in
                                    // Handle tap if needed
                                }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func sectionWithVerticalList(title: String, songs: [(title: String, artist: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: title)
            
            VStack(spacing: 16) {
                ForEach(songs, id: \.title) { song in
                    songRow(song: song)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.horizontal)
    }
    
    private func songRow(song: (title: String, artist: String)) -> some View {
        HStack(spacing: 16) {
            Image("test_album")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Add play action
        }
    }
    struct NoHighlightButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
    struct KeyboardAdaptive: ViewModifier {
        @State private var keyboardHeight: CGFloat = 0

        func body(content: Content) -> some View {
            content
                .padding(.bottom, keyboardHeight)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                        keyboardHeight = keyboardFrame.height
                    }
                    
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        keyboardHeight = 0
                    }
                }
        }
    }
}
