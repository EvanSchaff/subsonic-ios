//
//  SearchViewModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/29/24.
//

import Foundation

class SearchViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var songs: [Song] = []
    @Published var isSearching = false
    
    
    private let config = ConfigurationManager.shared
    private let subsonicClient: SubsonicClient
    private var searchTask: Task<Void, Never>?
    
    init() {
        // Initialize SubsonicClient with constants
        let credentials = config.getCredentials()
        self.subsonicClient = SubsonicClient(
            baseURL: credentials.baseURL,
            username: credentials.username,
            password: credentials.password
        )
    }
    
    func search(query: String) {
            guard config.hasValidCredentials() else {
                print("No valid credentials available")
                return
            }
            
            searchTask?.cancel()
            
            guard query.count >= 2 else {
                albums = []
                songs = []
                return
            }
            
            searchTask = Task { @MainActor in
                isSearching = true
                
                // Delay for 500ms
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                guard !Task.isCancelled else {
                    isSearching = false
                    return
                }
                
                do {
                    let results = try await subsonicClient.search(query: query)
                    let updatedAlbums = await subsonicClient.fetchAlbumArt(for: results.0)
                    self.albums = updatedAlbums
                    self.songs = results.1
                } catch {
                    print("Search error: \(error)")
                }
                
                isSearching = false
            }
        }
    }

