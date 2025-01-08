//
//  AlbumModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/23/24.
//

import SwiftUI

struct Album {
    let id: String
    let name: String
    let artist: String
    let year: Int?
    let duration: Int?
    let created: String?
    let songCount: Int
    private(set) var image: UIImage?
    
    init(from source: AlbumSourceType) {
        switch source {
        case .subSonicAlbum(let subSonicAlbum):
            self.id = subSonicAlbum.id
            self.name = subSonicAlbum.name
            self.artist = subSonicAlbum.artist
            self.year = subSonicAlbum.year
            self.duration = subSonicAlbum.duration
            self.created = subSonicAlbum.created
            self.songCount = subSonicAlbum.songCount

        case .subSonicSearchAlbum(let subSonicSearchAlbum):
            self.id = subSonicSearchAlbum.id
            self.name = subSonicSearchAlbum.name
            self.artist = subSonicSearchAlbum.artist
            self.year = subSonicSearchAlbum.year
            self.duration = nil // Or handle differently if not available
            self.created = nil  // Or handle differently if not available
            self.songCount = subSonicSearchAlbum.songCount
        }
    }
    
    mutating func setImage(_ image: UIImage) {
        self.image = image
    }
    
    enum AlbumSourceType {
        case subSonicAlbum(SubSonicAlbum2)
        case subSonicSearchAlbum(SubSonicSearchAlbum2)
    }
}
