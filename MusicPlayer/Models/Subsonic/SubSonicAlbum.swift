//
//  Album.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/20/24.
//

import UIKit
import Foundation

struct SubSonicAlbum2: Codable {
    let id: String
    let title: String?
    let name: String
    let album: String
    let artist: String
    let coverArt: String
    let year: Int?
    let duration: Int
    let created: String
    let songCount: Int
    let genres: [String]
}

struct SubSonicAlbumList2: Codable {
    let album: [SubSonicAlbum2]
}

struct SubSonicAlbumResponse: Codable {
    let status: String
    let version: String
    let type: String
    let serverVersion: String
    let openSubsonic: Bool
    let albumList2: SubSonicAlbumList2
}

