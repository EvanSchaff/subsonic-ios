//
//  AlbumViewModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/22/24.
//

import Foundation


class AlbumViewModel: ObservableObject {
    let album: Album
    @Published var songs: [Song] = []
    
    private let config = ConfigurationManager.shared
    private let subsonicClient: SubsonicClient
    
    init(album: Album) {
        self.album = album
        let credentials = config.getCredentials()
        self.subsonicClient = SubsonicClient(
            baseURL: credentials.baseURL,
            username: credentials.username,
            password: credentials.password
        )
    }
    
    func loadSongs() {
        guard config.hasValidCredentials() else {
            return
        }
        Task {
            do {
                let songs = try await subsonicClient.getSongs(from: album)
                
                await MainActor.run {
                    self.songs = songs
                }
            } catch {
                await MainActor.run {
                    print("Error loading songs: \(error)")
                    self.songs = []
                }
            }
        }
    }
}
