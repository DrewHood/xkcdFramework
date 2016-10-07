//
//  CacheManagerImageDelegate.swift
//  xkcd
//
//  Created by Drew Hood on 9/17/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation
import UIKit

protocol ComicManagerImageDelegate {
    func comicManager(manager: ComicManager, retrievedImage image: UIImage, forComic comic: Comic)
    func comicManager(manager: ComicManager, encounteredImageRetrievalError error: Error)
}
