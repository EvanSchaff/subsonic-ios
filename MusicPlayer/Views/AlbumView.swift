//
//  AlbumView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/20/24.
//

import SwiftUI

struct AlbumView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AlbumViewModel
    
    
    init(album: Album) {
        self.album = album
        _viewModel = StateObject(wrappedValue: AlbumViewModel(album: album))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Buttons
            HStack {
                // Back Button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
                
                // Ellipsis
                Button(action: {
                    // Action
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Content
            ZStack {
                VStack(spacing: 10) {
                    // Album Info
                    HStack {
                        if let albumArt = album.image {
                            Image(uiImage: albumArt)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        } else {
                            Image("test_album")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                        VStack(alignment: .leading) {
                            Text(album.name)
                                .font(.headline)
                            Text(album.artist)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    Spacer()
                }
                
                // Song List
                ScrollView {
                    VStack {
                        Color.clear.frame(height: 130)
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                                SongRow(song: song,
                                       index: index,
                                       album: album,
                                        songs: viewModel.songs)
                            }
                        }
                    }
                    Spacer()
                        .frame(height: 100)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: EmptyView())
            .onAppear {
                viewModel.loadSongs()
            }
        }
    }
    
    struct SongRow: View {
        let song: Song
        let index: Int
        let album: Album
        let songs: [Song]
        @ObservedObject private var player = PlayerViewModel.shared
        
        var body: some View {
            Button(action: {
                handleSongSelection()
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(song.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if player.isLoading && player.currentSong?.id == song.id {
                        ProgressView()
                    } else {
                        Text(formatDuration(song.duration))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(player.isLoading)
        }
        
        private func handleSongSelection() {
            let player = PlayerViewModel.shared
            

            guard !player.isLoading else { return }
            
            let playlist = Playlist(
                name: album.name,
                songs: songs,
                currentIndex: index
            )
            
            player.loadPlaylist(playlist: playlist)
            
            Task {
                do {
                    try await player.playCurrentSong(song: song)
                    await MainActor.run {
                        player.showPlayer = true
                    }
                } catch {
                    print("Failed to play song: \(error)")
                }
            }
        }

        private func formatDuration(_ seconds: Int) -> String {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}
