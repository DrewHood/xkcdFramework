//
//  ComicManagerDelegate.swift
//  xkcd
//
//  Created by Drew Hood on 9/13/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation
import UIKit

public protocol ComicManagerDelegate {
    
    // Adding and removing comics
    func comicManager(manager: ComicManager, addedComic comic: Comic)
    func comicManager(manager: ComicManager, removedComic comic: Comic)
    func comicManager(manager: ComicManager, updatedComic comic: Comic)
    
}
