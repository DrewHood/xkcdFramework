//
//  Comic+Initialization.swift
//  xkcd
//
//  Created by Drew Hood on 9/14/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation
import CoreData

extension Comic {
    
    static private let COMIC_CLASS_NAME = "Comic"
    
    class func newComic(inContext context: NSManagedObjectContext) -> Comic {
        let newObj: Comic = NSEntityDescription.insertNewObject(forEntityName: COMIC_CLASS_NAME, into: context) as! Comic
        
        return newObj
        
    }
    
    func seed(withDictionary dict: [String:Any]) -> Comic {
        let nsnum = dict["num"] as! NSNumber
        
        self.id = nsnum.int32Value
        self.title = dict["title"] as? String
        self.safeTitle = dict["safe_title"] as? String
        self.alt = dict["alt"] as? String
        self.remoteImageUrl = dict["img"] as? String
        self.link = dict["link"] as? String
        self.news = dict["news"] as? String
        self.transcript = dict["transcript"] as? String
        
        return self
    }
    
}
