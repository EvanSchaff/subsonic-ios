//
//  AllAlbumsModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 1/7/25.
//

import Foundation

class AllAlbumsModel: ObservableObject {
    @Published var albums: [Album] = []
    
    private let config = ConfigurationManager.shared
    private let subsonicClient: SubsonicClient
    
    init() {
        let credentials = config.getCredentials()
        self.subsonicClient = SubsonicClient(
            baseURL: credentials.baseURL,
            username: credentials.username,
            password: credentials.password
            
        )
        if config.hasValidCredentials() {
            loadAlbums()
        }
    }
    
    func loadAlbums() {
        guard config.hasValidCredentials() else {
            return
        }
        
        Task {
            do {
                let allAlbums = try await subsonicClient.getAlbums(size: 500)
                await MainActor.run {
                    self.albums = allAlbums
                }
            } catch {
                print("Failed to load albums: \(error.localizedDescription)")
                print("Error details: \(error)")
            }
        }
    }
    
    func loadAlbumArt(album: [Album]) {
        guard config.hasValidCredentials() else {
            return
        }
        Task {
            do {
                let albumArt = await subsonicClient.fetchAlbumArt(for: album)
                
                await MainActor.run {
                    for updatedAlbum in albumArt {
                        if let index = self.albums.firstIndex(where: { $0.id == updatedAlbum.id }) {
                            self.albums[index] = updatedAlbum
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    
}
