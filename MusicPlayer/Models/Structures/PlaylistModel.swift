//
//  PlaylistModel.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/25/24.
//

import Foundation

struct Playlist {
    let name: String
    var songs: [Song]
    var currentIndex: Int = 0
    
    var currentSong: Song? {
        guard currentIndex >= 0 && currentIndex < songs.count else { return nil }
        return songs[currentIndex]
    }
}
