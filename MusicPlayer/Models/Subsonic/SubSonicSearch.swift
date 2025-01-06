//
//  SubSonicSearch.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/30/24.
//


struct SubSonicSearchResult3: Codable {
    let album: [SubSonicSearchAlbum2]?
    let song: [SubSonicSearchSong]?
}

struct SubSonicSearchResponse: Codable {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let searchResult3: SubSonicSearchResult3
    
    private enum CodingKeys: String, CodingKey {
        case status, version, type, serverVersion, openSubsonic = "openSubsonic"
        case searchResult3
    }
}

// Album model matching the JSON structure
struct SubSonicSearchAlbum2: Codable {
    let id: String
    let name: String
    let artist: String
    let artistId: String
    let coverArt: String
    let songCount: Int
    let duration: Int
    let playCount: Int?
    let created: String
    let year: Int
    let genre: String?
    let played: String?
    let userRating: Int
    let genres: [Genre]
    let isCompilation: Bool
    let sortName: String
    
    struct Genre: Codable {
        let name: String
    }
}

// Song model matching the JSON structure
struct SubSonicSearchSong: Codable {
    let id: String
    let parent: String
    let isDir: Bool
    let title: String
    let album: String
    let artist: String
    let track: Int
    let year: Int
    let genre: String?
    let coverArt: String
    let size: Int
    let contentType: String
    let suffix: String
    let duration: Int
    let bitRate: Int
    let path: String
    let playCount: Int?
    let discNumber: Int
    let created: String
    let albumId: String
    let artistId: String
    let type: String
    let isVideo: Bool
    let played: String?
    let genres: [Genre]
    
    struct Genre: Codable {
        let name: String
    }
}
