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
        saveImageToDisk(image, forKey: key)
    }
    
    func object(forKey key: NSString) -> UIImage? {
        return cache.object(forKey: key)
    }
    
    private func saveImageToDisk(_ image: UIImage, forKey key: NSString) {
        guard let data = image.pngData() else { return }
        let fileURL = filePath(forKey: key)
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to save image to drive")
        }
    }
    
    private func loadImageFromDisk(forKey key: NSString) -> UIImage? {
        let fileURL = filePath(forKey: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil}
        return UIImage(data: data)
    }
    
    private func filePath(forKey key: NSString) -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(key as String)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        clearDiskCache()
    }
    
    private func clearDiskCache() {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear disk cache")
        }
    }
    
}
