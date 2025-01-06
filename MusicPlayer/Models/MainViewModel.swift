//
//  MusicViewModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/20/24.
//
import Foundation

class MusicViewModel: ObservableObject {
    @Published var recentAlbums: [Album] = []
    @Published var frequentAlbums: [Album] = []
    @Published var randomAlbums: [Album] = []
    
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
                    let recentlyFetchedAlbums = try await subsonicClient.getAlbums(type: .newest, size: 10)
                    let recentlyUpdatedAlbums = await subsonicClient.fetchAlbumArt(for: recentlyFetchedAlbums)
                    
                    await MainActor.run {
                        self.recentAlbums = recentlyUpdatedAlbums
                    }
                
                    let frequentFetchedAlbums = try await subsonicClient.getAlbums(type: .frequent, size: 10)
                    let frequentlyUpdatedAlbums = await subsonicClient.fetchAlbumArt(for: frequentFetchedAlbums)
                    
                    await MainActor.run {
                        self.frequentAlbums = frequentlyUpdatedAlbums
                    }
                    
                    let randomFetchedAlbums = try await subsonicClient.getAlbums(type: .random, size: 10)
                    let randomUpdatedAlbums = await subsonicClient.fetchAlbumArt(for: randomFetchedAlbums)
                    
                    await MainActor.run {
                        self.randomAlbums = randomUpdatedAlbums
                    }
                    
                } catch {
                    print("Failed to load albums: \(error.localizedDescription)")
                    print("Error details: \(error)")
                }
            }
        }
    

    func loadSongs() {
//        Task {
//            do {
//                //let recentlyFetchedSongs = try await subsonicClient.getRecentlyPlayedSongs()
//            } catch {
//                print("Failed to load songs: \(error.localizedDescription)")
//                print("Error details: \(error)")
//            }
//        }
    }
}
