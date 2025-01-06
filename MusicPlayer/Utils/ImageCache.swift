//
//  ImageCache.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/23/24.
//
import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 50
    }
    
    func setObject(_ image: UIImage, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }
    
    func object(forKey key: NSString) -> UIImage? {
        return cache.object(forKey: key)
    }
}
