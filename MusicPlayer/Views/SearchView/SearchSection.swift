//
//  SearchSection.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 1/7/25.
//

import SwiftUI

struct SearchSection: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @ObservedObject var player = PlayerViewModel.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            header()
            ScrollView(showsIndicators: false) {
                if !searchViewModel.albums.isEmpty {
                    sectionWithHorizontalScroll(title: "Albums", items: searchViewModel.albums)
                }
                if !searchViewModel.songs.isEmpty {
                    sectionWithVerticalList(title: "Songs", items: searchViewModel.songs)
                }
                Spacer()
                    .padding(.bottom, 100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: EmptyView())
        .onAppear() {
            isSearchFocused = true
        }
    }
    
    private func header() -> some View {
        return HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            Spacer()
            searchBar()
            
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private func searchBar() -> some View {
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search...", text: $searchText)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .padding(.vertical, 10)
                .focused($isSearchFocused)
                .onChange(of: searchText) { _, newValue in
                    searchViewModel.search(query: newValue)
                }
            
            if searchViewModel.isSearching {
                ProgressView()
                    .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
    }
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.horizontal)
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
                                    Image("test_album")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
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
                                }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func handleSongSelection(song: Song, index: Int) {
         // Guard against multiple selections while loading
         guard !player.isLoading else { return }
         
         let playlist = Playlist(
             name: "Search Songs",
             songs: searchViewModel.songs,
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
    
    private func sectionWithVerticalList(title: String, items: [Song]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: title)
            VStack(spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, song in
                    songRow(song: song, index: index)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func songRow(song: Song, index: Int) -> some View {
        HStack(spacing: 16) {
            Image("test_album")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.headline)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if player.isLoading && player.currentSong?.id == song.id {
                ProgressView()
            } else {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleSongSelection(song: song, index: index)
        }
        .disabled(player.isLoading)
    }
    
    struct NoHighlightButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}
