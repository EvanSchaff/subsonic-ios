//
//  SubSonicService.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/19/24.
//

import Foundation
import CryptoKit
import UIKit
import SwiftUI

class SubsonicClient {
    let baseURL: String
    private let username: String
    private let password: String
    private let apiVersion = "1.16.1"
    private let clientName = "MyMusicApp"
    
    init(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
    }
    
    func getAuthQueryString() -> String {
        let authParams = getAuthParams()
        let queryString = authParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return queryString
    }
    
    private func getAuthParams() -> [String: String] {
        let salt = String(Int.random(in: 0..<1000000))
        let token = (password + salt).md5
        
        return [
            "u": username,
            "t": token,
            "s": salt,
            "v": apiVersion,
            "c": clientName,
            "f": "json"
        ]
    }
    
    private func buildURL(path: String, additionalParams: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: baseURL + "/rest/" + path)
        let authParams = getAuthParams()
        
        let queryItems = (authParams.merging(additionalParams) { current, _ in current })
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    func getAlbums(type: AlbumListType = .alphabeticalByName, size: Int? = nil) async throws -> [Album] {
        var params = ["type": type.rawValue]
        if let size = size {
            params["size"] = String(size)
        }
        
        guard let url = buildURL(path: "getAlbumList2", additionalParams: params) else {
            throw SubsonicError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode([String: SubSonicAlbumResponse].self, from: data)
            
            if let albumListResponse = response["subsonic-response"]?.albumList2.album {
                let albumList = albumListResponse.map { Album(from: .subSonicAlbum($0)) }
                return albumList
            } else {
                return []
            }
        } catch {
            throw SubsonicError.fetchingDataFailed
        }
    }
    
    func fetchAlbumArt(for albums: [Album]) async -> [Album] {
        var updatedAlbums = albums
        
        for (index, album) in albums.enumerated() {
            if let cachedImage = ImageCache.shared.object(forKey: album.id as NSString) {
                updatedAlbums[index].setImage(cachedImage)
            }
        }
        
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, album) in albums.enumerated() {
                if ImageCache.shared.object(forKey: album.id as NSString) == nil {
                    group.addTask {
                        guard let url = self.buildURL(path: "getCoverArt", additionalParams: [
                            "id": album.id,
                            "width": "120",
                            "height": "120"
                        ]) else {
                            return (index, nil)
                        }
                        
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                ImageCache.shared.setObject(image, forKey: album.id as NSString)
                                return (index, image)
                            }
                        } catch {
                            // Handle errors
                        }
                        
                        return (index, nil)
                    }
                }
            }
            
            for await (index, image) in group {
                if let image = image {
                    updatedAlbums[index].setImage(image)
                }
            }
        }
        
        return updatedAlbums
        
    }
    
    func fetchAlbumArtById(for albumId: String) async -> Image? {
        if let cachedImage = ImageCache.shared.object(forKey: albumId as NSString) {
            return Image(uiImage: cachedImage)
        }
        
        guard let url = self.buildURL(path: "getCoverArt", additionalParams: [
            "id": albumId,
            "width": "120",
            "height": "120"
        ]) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                ImageCache.shared.setObject(image, forKey: albumId as NSString)
                return Image(uiImage: image)
            }
        } catch {
            // Handle errors
        }
        
        return nil
    }
    
    func getSongs(from album: Album) async throws -> [Song] {
        guard let url = buildURL(path: "getAlbum", additionalParams: ["id": album.id]) else {
            throw SubsonicError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode([String: SubSonicSongResponse].self, from: data)
            if let songListResponse = response["subsonic-response"]?.album.song {
                let songs = songListResponse.map { Song(from: .subSonicSong($0)) }
                return songs
            } else {
                return []
            }
        } catch {
            throw SubsonicError.fetchingDataFailed
        }
    }
    
    func getStreamURL(for song: Song) -> URL? {
        return buildURL(path: "stream", additionalParams: ["id": song.id, "format": "mp3"])
    }
    
    func search(query: String) async throws -> ([Album], [Song]) {
        guard let url = buildURL(path: "search3", additionalParams: [
            "query" : query,
            "artistCount": "0",
            "albumCount": "10",
            "songCount": "10"
        ]) else {
            throw SubsonicError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode([String: SubSonicSearchResponse].self, from: data)
            
            if let searchResult = response["subsonic-response"]?.searchResult3 {
                let albums = (searchResult.album ?? []).map { Album(from: .subSonicSearchAlbum($0)) }
                let songs = (searchResult.song ?? []).map { Song(from: .subSonicSearchSong($0)) }
                return (albums, songs)
            } else {
                return ([], [])
            }
        } catch {
            throw SubsonicError.fetchingDataFailed
        }
    }
}


struct ErrorResponse: Codable {
    let code: Int
    let message: String
}

enum AlbumListType: String {
    case random
    case newest
    case frequent
    case recent
    case starred
    case alphabeticalByName
    case alphabeticalByArtist
}

enum SubsonicError: Error {
    case invalidURL
    case fetchingDataFailed
    case decodingFailed
    case noData
    case invalidAlbumID
}

extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}
