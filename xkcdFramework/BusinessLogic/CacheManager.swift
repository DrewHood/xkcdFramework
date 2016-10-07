//
//  CacheManager.swift
//  xkcd
//
//  Created by Drew Hood on 9/17/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation
import UIKit

class CacheManager {
    
    // Singleton
    static let sharedManager = CacheManager()
    private init() {
        self.cacheManager = NSCache<NSString, UIImage>()
        self.cacheManager.name = CACHE_NAME
        self.cacheManager.totalCostLimit = 4 * (10^7) // <-- 40 Megabytes
        self.cacheManager.evictsObjectsWithDiscardedContent = true
    }
    
    private let CACHE_NAME = "IMAGE_CACHE"
    private let cacheManager: NSCache<NSString, UIImage>
    
    func cacheImage(image: UIImage, forComic comic: Comic) {
        let key = String(comic.id) // for now, we'll just use the safeTitle
        let cost = UIImagePNGRepresentation(image)!.count
        
        self.cacheManager.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func imageFromCache(forComic comic: Comic) -> UIImage? {
        if let img = self.cacheManager.object(forKey: String(comic.id) as NSString) {
            return img
        }
        
        return nil
    }
}
