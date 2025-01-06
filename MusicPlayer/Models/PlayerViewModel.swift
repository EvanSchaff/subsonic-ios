//
//  PlayerViewModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/22/24.
//

import SwiftUI
import Foundation
import AVFoundation
import CoreMedia
import MediaPlayer


class PlayerViewModel: ObservableObject {
    
    static let shared = PlayerViewModel()
    @Published var showPlayer: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var name: String?
    @Published var songs: [Song]?
    @Published var currentIndex: Int = 0
    @Published var currentPlaylist: Playlist?
    @Published var currentSong: Song?
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .none
    @Published var currentTime: Double = 0
    @Published var albumArt: Image?
    private var timeObserver: Any?
    private var shuffledIndices: [Int] = []
    private var currentPlayer: AVPlayer?
    private let subsonicClient: SubsonicClient
    private var currentSongHasRangeSupport: Bool = false
    private var streamingDiagnostics: [String: String] = [:]
    private var loadingTask: Task<Void, Error>?
    private var isChangingTrack: Bool = false
    private var albumArtUIImage: UIImage?
    private var preloadedPlayers: [Int: AVPlayer] = [:]
    private let maxPreloadedPlayers = 2
    private let config = ConfigurationManager.shared
    
    enum RepeatMode {
        case none
        case single
        case all
    }
    
    
    init() {
        let credentials = config.getCredentials()
        self.subsonicClient = SubsonicClient(
            baseURL: credentials.baseURL,
            username: credentials.username,
            password: credentials.password
        )
        setupTimeObserver()
        setupRemoteCommandCenter()
        configureAudioSession()
    }
    
    private func preloadUpcomingTracks() {
        guard let playlist = currentPlaylist else { return }
        
        // Clear old preloaded players
        preloadedPlayers.forEach { $1.replaceCurrentItem(with: nil) }
        preloadedPlayers.removeAll()
        
        // Calculate the next few indices to preload
        var indicesToPreload: [Int] = []
        for offset in 1...maxPreloadedPlayers {
            if shuffleEnabled {
                let currentShuffleIndex = shuffledIndices.firstIndex(of: playlist.currentIndex) ?? -1
                let nextIndex = currentShuffleIndex + offset
                if nextIndex < shuffledIndices.count {
                    indicesToPreload.append(shuffledIndices[nextIndex])
                }
            } else {
                let nextIndex = playlist.currentIndex + offset
                if nextIndex < playlist.songs.count {
                    indicesToPreload.append(nextIndex)
                }
            }
        }
        
        for index in indicesToPreload {
            let song = playlist.songs[index]
            if let streamURL = subsonicClient.getStreamURL(for: song) {
                let playerItem = AVPlayerItem(url: streamURL)
                let player = AVPlayer(playerItem: playerItem)
                preloadedPlayers[index] = player
            }
        }
    }
    
    
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        if let currentSong = currentSong {
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentSong.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = currentSong.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentSong.album
            
            if let albumArtUIImage = albumArtUIImage {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumArtUIImage.size) { size in
                    return albumArtUIImage
                }
            }
            
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentPlayer?.currentItem?.duration.seconds ?? 0
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func imageToUIImage(_ image: Image) -> UIImage? {
        let controller = UIHostingController(rootView: image)
        
        controller.view.frame = CGRect(x: 0, y: 0, width: 1300, height: 1200)
        
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    private func setupRemoteCommandCenter() {
          let commandCenter = MPRemoteCommandCenter.shared()
          
          commandCenter.playCommand.addTarget { [weak self] _ in
              self?.resume()
              return .success
          }
          
          commandCenter.pauseCommand.addTarget { [weak self] _ in
              self?.pause()
              return .success
          }
          
          commandCenter.nextTrackCommand.addTarget { [weak self] _ in
              self?.nextTrack()
              return .success
          }
          
          commandCenter.previousTrackCommand.addTarget { [weak self] _ in
              self?.prevTrack()
              return .success
          }
      }
    
    private func updateAlbumArt() async {
        guard let currentSong = currentSong else {
            await MainActor.run {
                albumArt = nil
                albumArtUIImage = nil
            }
            return
        }
        
        let fetchedAlbumArt = await subsonicClient.fetchAlbumArtById(for: currentSong.albumId)
        
        await MainActor.run {
            albumArt = fetchedAlbumArt
            if let unwrappedAlbumArt = fetchedAlbumArt {
                albumArtUIImage = imageToUIImage(unwrappedAlbumArt) // Convert to UIImage if possible
            } else {
                albumArtUIImage = nil
            }
        }
    }

    private func setupTimeObserver() {
        // Remove any existing time observer if the player is not nil
        if let observer = timeObserver, let player = currentPlayer {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Create a new time observer
        if let player = currentPlayer {
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 1, preferredTimescale: 600), // Update every second
                queue: .main
            ) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time.seconds
                
                // Log the current time
                print("Current Time: \(self.currentTime) seconds")
                
                self.updateNowPlayingInfo() // Update now playing info with current time
                self.checkForSongCompletion()
            }
        }
    }

    
    func loadPlaylist(playlist: Playlist) {
        currentPlaylist = playlist
        currentIndex = playlist.currentIndex
        currentSong = playlist.currentSong
        objectWillChange.send()
    }
    
    func playCurrentSong(song: Song) async throws {
        await MainActor.run {
            currentPlayer?.pause()
            isPlaying = false
            isLoading = true
        }
        
        // Check if we have a preloaded player for this index
        if let playlist = currentPlaylist,
           let preloadedPlayer = preloadedPlayers[playlist.currentIndex] {
            await MainActor.run {
                currentPlayer = preloadedPlayer
                preloadedPlayers.removeValue(forKey: playlist.currentIndex)
                setupTimeObserver()
                currentPlayer?.play()
                isPlaying = true
                isLoading = false
                objectWillChange.send()
                updateNowPlayingInfo()
            }
            
            // Start preloading next tracks
            preloadUpcomingTracks()
            return
        }

        guard let streamURL = subsonicClient.getStreamURL(for: song) else {
            throw SubsonicError.invalidURL
        }

        // Indicate loading has started
        await MainActor.run {
            isLoading = true
        }

        // Check the stream capabilities before creating the player item
        do {
            let (capabilities, diagnostics) = try await checkStreamCapabilities(url: streamURL)
            await MainActor.run {
                currentSongHasRangeSupport = capabilities.supportsRanges
                streamingDiagnostics = diagnostics
            }
        } catch {
            // Handle capability check errors silently or add appropriate error handling here
        }

        let playerItem = AVPlayerItem(url: streamURL)

        await updateAlbumArt()

        await MainActor.run {
            if currentPlayer == nil {
                currentPlayer = AVPlayer(playerItem: playerItem)
                setupTimeObserver()
            } else {
                currentPlayer?.replaceCurrentItem(with: playerItem)
            }

            currentPlayer?.play()
            isPlaying = true
            isLoading = false // Indicate loading has finished
            objectWillChange.send()
            updateNowPlayingInfo() // Update lock screen info
        }
    }

    private struct StreamCapabilities {
        var supportsRanges: Bool
        var contentLength: String?
        var contentType: String?
    }

    private func checkStreamCapabilities(url: URL) async throws -> (StreamCapabilities, [String: String]) {
        var request = URLRequest(url: url)
        // Request a byte range to check support
        request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        var diagnostics: [String: String] = [:]
        
        guard let httpResponse = response as? HTTPURLResponse else {
            diagnostics["error"] = "Not an HTTP response"
            return (StreamCapabilities(supportsRanges: false), diagnostics)
        }
        
        // Collect diagnostic information
        diagnostics["status_code"] = String(httpResponse.statusCode)
        diagnostics["headers"] = httpResponse.allHeaderFields.description
        
        let supportsRanges = httpResponse.allHeaderFields["Accept-Ranges"] as? String == "bytes"
        let contentLength = httpResponse.allHeaderFields["Content-Length"] as? String
        let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
        
        diagnostics["supports_ranges"] = String(supportsRanges)
        diagnostics["content_length"] = contentLength ?? "unknown"
        diagnostics["content_type"] = contentType ?? "unknown"
        
        // If the server supports ranges, it should respond with 206 Partial Content
        if httpResponse.statusCode == 206 {
            diagnostics["range_response"] = "Server correctly responded to range request"
        } else {
            diagnostics["range_response"] = "Server did not properly handle range request"
        }
        
        return (StreamCapabilities(
            supportsRanges: supportsRanges,
            contentLength: contentLength,
            contentType: contentType
        ), diagnostics)
    }



    
    func togglePause() {
        if isPlaying == true {
            pause()
        } else {
            resume()
        }
    }
    
    func pause() {
        currentPlayer?.pause()
        isPlaying = false
    }
    
    func resume() {
        currentPlayer?.play()
        isPlaying = true
    }
    

    func seek(to timeInSeconds: Double) {
        guard let player = currentPlayer else { return }
        
        // Continue with seek operation...
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 600)
        player.seek(to: time) { [weak self] finished in
            if finished {
                self?.currentTime = timeInSeconds
            }
        }
    }

    func nextTrack() {
        guard !isChangingTrack else { return }
        
        isChangingTrack = true  // Set the flag
        
        guard let playlist = currentPlaylist else {
            isChangingTrack = false
            return
        }
        
        // Pause the current player before changing tracks
        currentPlayer?.pause()

        // Calculate the next index
        let nextIndex: Int
        if shuffleEnabled {
            nextIndex = getNextShuffledIndex()
        } else {
            let proposedIndex = playlist.currentIndex + 1
            nextIndex = proposedIndex >= playlist.songs.count
                ? (repeatMode == .all ? 0 : playlist.songs.count - 1)
                : proposedIndex
        }
        
        // Only proceed if we have a valid index
        guard nextIndex < playlist.songs.count else {
            isChangingTrack = false
            return
        }
        
        // Update the current index and song atomically
        currentPlaylist?.currentIndex = nextIndex
        currentSong = playlist.songs[nextIndex]
        currentTime = 0
        
        // Ensure we stop any previous observers properly before creating a new one
        timeObserver = nil

        // Play the new song
        Task {
            do {
                try await playCurrentSong(song: playlist.songs[nextIndex])
                preloadUpcomingTracks()  // Preload after changing tracks
            } catch {
                // Handle error silently
            }
            isChangingTrack = false
        }
    }

    func prevTrack() {
        guard let playlist = currentPlaylist else { return }
        
        // Pause the current player before changing tracks
        currentPlayer?.pause()
        
        if currentTime > 3 {
            seek(to: 0)
            currentPlayer?.play()
            return
        }
        
        if shuffleEnabled {
            currentPlaylist?.currentIndex = getPreviousShuffledIndex()
        } else {
            let prevIndex = playlist.currentIndex - 1
            currentPlaylist?.currentIndex = prevIndex < 0
                ? (repeatMode == .all ? playlist.songs.count - 1 : 0)
                : prevIndex
        }
        
        // Play the previous song
        if let playlist = currentPlaylist {
            currentSong = playlist.songs[playlist.currentIndex]
            Task {
                try await playCurrentSong(song: playlist.songs[playlist.currentIndex])
            }
        }
    }

    func toggleShuffle() {
        shuffleEnabled.toggle()
        if shuffleEnabled {
            generateShuffledIndices()
            // Make sure to update the current song to match the new shuffled order
            if let playlist = currentPlaylist {
                currentSong = playlist.songs[playlist.currentIndex]
            }
        }
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .single
        case .single:
            repeatMode = .all
        case .all:
            repeatMode = .none
        }
    }
    
    private func generateShuffledIndices() {
        guard let playlist = currentPlaylist else { return }

        shuffledIndices = Array(0..<playlist.songs.count)
        shuffledIndices.shuffle()
        
        if let currentIndex = shuffledIndices.firstIndex(of: playlist.currentIndex) {
            shuffledIndices.swapAt(0, currentIndex)
        }
        
        currentPlaylist?.currentIndex = shuffledIndices[0]
    }
    
    private func getNextShuffledIndex() -> Int {
        guard let playlist = currentPlaylist else { return 0 }
        let currentShuffleIndex = shuffledIndices.firstIndex(of: playlist.currentIndex) ?? -1
        let nextIndex = currentShuffleIndex + 1
        
        if nextIndex >= shuffledIndices.count {
            return repeatMode == .all ? shuffledIndices[0] : playlist.currentIndex
        }
        return shuffledIndices[nextIndex]
    }
    
    private func getPreviousShuffledIndex() -> Int {
        guard let playlist = currentPlaylist else { return 0 }
        let currentShuffleIndex = shuffledIndices.firstIndex(of: playlist.currentIndex) ?? -1
        let previousIndex = currentShuffleIndex - 1
        
        if previousIndex < 0 {
            return repeatMode == .all ? shuffledIndices.last ?? playlist.currentIndex : playlist.currentIndex
        }
        return shuffledIndices[previousIndex]
    }
    
    private func checkForSongCompletion() {
        // Don't check for completion if we're already changing tracks
        guard !isChangingTrack else { return }
        
        guard let player = currentPlayer else { return }
        
        guard let duration = player.currentItem?.duration.seconds, !duration.isNaN else { return }
        
        let currentTime = player.currentTime().seconds
        
        // Check if the song has completed (allowing for a small buffer of 0.5 seconds)
        if currentTime >= duration - 0.5 {
            switch repeatMode {
            case .none, .all:
                nextTrack()
            case .single:
                seek(to: 0)
                resume()
            }
        }
    }

}
