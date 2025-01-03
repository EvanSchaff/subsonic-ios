//
//  SongModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/23/24.
//

import SwiftUI

struct Song {
    let id: String
    let name: String
    let artist: String
    let duration: Int
    let albumId: String
    let album: String
    private(set) var image: UIImage?
    
    init(from source: SongSourceType) {
        switch source {
        case .subSonicSong(let subSonicSong):
            self.id = subSonicSong.id
            self.name = subSonicSong.title
            self.artist = subSonicSong.artist
            self.duration = subSonicSong.duration
            self.albumId = subSonicSong.albumId
            self.album = subSonicSong.album
        case .subSonicSearchSong(let subSonicSearchSong):
            self.id = subSonicSearchSong.id
            self.name = subSonicSearchSong.title
            self.artist = subSonicSearchSong.artist
            self.duration = subSonicSearchSong.duration
            self.albumId = subSonicSearchSong.albumId
            self.album = subSonicSearchSong.album
        }
    }
    mutating func setImage(_ image: UIImage) {
        self.image = image
    }
}



enum SongSourceType {
    case subSonicSong(SubSonicSong)
    case subSonicSearchSong(SubSonicSearchSong)
}

