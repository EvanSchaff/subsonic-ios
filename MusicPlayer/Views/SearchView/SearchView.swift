//
//  SearchView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var albumsView = AllAlbumsModel()
    
    var body: some View {
        VStack(spacing: 16) {
            staticSearchBar()
            albumScrollView(items: albumsView.albums)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func staticSearchBar() -> some View {
        NavigationLink(destination: SearchSection()) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Search...")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
    }
    
    private func albumScrollView(items: [Album]) -> some View {
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items, id: \.id) { album in
                    VStack {
                        if let albumArt = album.image {
                            Image(uiImage: albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        } else {
                            ProgressView()
                                .frame(width: 120, height: 120)
                        }
                    }
                    .onAppear {
                        if album.image == nil {
                            albumsView.loadAlbumArt(album: [album])
                        }
                    }
                }
                
            }
            
        }
    }
    
}



