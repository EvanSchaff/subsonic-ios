//
//  SongListResponse.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/20/24.
//

import Foundation

struct SubSonicSong: Codable {
    let id: String
    let parent: String
    let isDir: Bool
    let title: String
    let album: String
    let artist: String
    let track: Int
    let year: Int?  // Made optional
    let genre: String?  // Made optional
    let coverArt: String
    let size: Int
    let contentType: String
    let suffix: String
    let duration: Int
    let bitRate: Int
    let path: String
    let playCount: Int?
    let created: String
    let albumId: String
    let artistId: String
    let type: String
    let isVideo: Bool
    let played: String?
    let bpm: Int?  // Made optional
    let comment: String?  // Made optional
    let sortName: String?  // Made optional
    let mediaType: String
    let musicBrainzId: String?  // Made optional
    let genres: [SubSonicGenre]?  // Made optional
    let replayGain: SubSonicReplayGain?
    let channelCount: Int?  // Made optional
    let samplingRate: Int?  // Made optional
    let discNumber: Int?
}

struct SubSonicReplayGain: Codable {
    let trackPeak: Double
    let albumPeak: Double
}

struct SubSonicGenre: Codable {
    let name: String
}

struct SubSonicSongResponse: Codable {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let album: SubSonicSongAlbum
}

struct SubSonicSongAlbum: Codable {
    let id: String
    let name: String
    let artist: String
    let artistId: String
    let coverArt: String
    let songCount: Int
    let duration: Int?  // Made optional
    let playCount: Int?
    let created: String
    let year: Int?  // Made optional
    let genre: String?  // Made optional
    let played: String?
    let userRating: Int?  // Made optional
    let genres: [SubSonicGenre]?  // Made optional
    let musicBrainzId: String?  // Made optional
    let isCompilation: Bool?  // Made optional
    let sortName: String?  // Made optional
    let discTitles: [DiscTitle]?  // Made optional
    let originalReleaseDate: [String: String]?
    let releaseDate: [String: String]?
    let song: [SubSonicSong]
}

struct DiscTitle: Codable {
    let disc: Int
    let title: String
}
