//
//  ComicManager.swift
//  xkcd
//
//  Created by Drew Hood on 9/13/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import CoreData
import SwiftyJSON

public class ComicManager {
    
    // Errors
    enum ComicManagerError: Error {
        case imageDataMarshalling
        case networking(underlyingError: Error)
        case unknown
    }
    
    // Data
    private let moc: NSManagedObjectContext
    private let cacheManager: CacheManager
    
    // Defaults
    private let defaultSortDescriptor = NSSortDescriptor(key: "id", ascending: false)
    
    // Flags
    private var isUpdating: Bool = false
    
    // Singleton
    static let sharedManager = ComicManager()
    private init() {
        //let appDel = UIApplication.shared.delegate as! AppDelegate
        self.moc = NSManagedObjectContext()
        
        self.cacheManager = CacheManager.sharedManager
    }
    
    // MARK: - Delegation
    var delegate: ComicManagerDelegate?
    var imageDelegate: ComicManagerImageDelegate?
    
    private func delegateAdded(comic: Comic) {
        // Inform our delegate.
        self.delegate?.comicManager(manager: self, addedComic: comic)
    }
    
    private func delegateImageRetrieved(image: UIImage, comic: Comic) {
        self.imageDelegate?.comicManager(manager: self, retrievedImage: image, forComic: comic)
    }
    
    private func delegateImageError(error: Error) {
        self.imageDelegate?.comicManager(manager: self, encounteredImageRetrievalError: error)
    }
    
    // MARK: - Comic Retrieval
    public func retrieveNewComics() {
        if self.isUpdating { return }
        
        /*
            - Find latest comic
            - Retrieve comics back to the highest ID
            - Scan ID numbers for missing comics
        */
        
        func saveNewComic(dictionary: [String:Any]) {
            
            let newComic = Comic.newComic(inContext: self.moc).seed(withDictionary: dictionary)
            
            do {
                try newComic.managedObjectContext?.save()
                
                // Notify delegate
                self.delegateAdded(comic: newComic)
            } catch {
                print("Error saving new comic!")
            }
        }
        
        func downloadComic(withId id: Int32) {
            
            let urlStr = "https://xkcd.com/\(id)/info.0.json"
            
            Alamofire.request(urlStr).responseString { response in
                switch response.result {
                case .success(let string):
                    if let responseData = try? string.decodeUtf8().data(using: .utf8) {
                        let json = JSON(data: responseData!)
                        saveNewComic(dictionary: json.dictionaryObject!)
                    }
                    break
                case .failure(let error):
                    print("Error retrieving new comic:")
                    debugPrint(error)
                    break
                }
            }
        }
        
        self.isUpdating = true
        
        let urlStr = "https://xkcd.com/info.0.json"
        
        Alamofire.request(urlStr).responseJSON { response in
            switch response.result {
            case .success(let JSON):
                let responseDict = JSON as! [String:AnyObject]
                
                // Do we need to save this one?
                let newId: Int32 = (responseDict["num"] as! NSNumber).int32Value
                if let _ = self.getComic(withId: Int32(newId)) {
                    // Nothing
                } else {
                    saveNewComic(dictionary: responseDict)
                }
                
                
                // What is the newest comic we have?
                let newestId = self.getLatestComicId()
                
                for id in 1...newestId {
                    if id == 404 { // TODO: Provide for comic 404
                        continue
                    }
                    
                    if let _ = self.getComic(withId: Int32(id)) {
                        // TODO: This brute force can be wayyy more efficient.
                        continue
                    }
                    
                    downloadComic(withId: Int32(id))
                }
                
                break
            case .failure(let error):
                print("Error retrieving new comic:")
                debugPrint(error)
                break
            }
        }
        
        self.isUpdating = false
        
    }
    
    private func getLatestComicId() -> Int32 {
        // What is the newest comic we have?
        let fetchRequest: NSFetchRequest<Comic> = Comic.fetchRequest()
        fetchRequest.sortDescriptors = [self.defaultSortDescriptor]
        fetchRequest.fetchLimit = 1
        
        do {
            let comics: [Comic] = try self.moc.fetch(fetchRequest)
            if comics.count > 0 {
                return comics[0].id
            }
        } catch {
            print("Error with fetch!")
        }
        
        return 0
    }
    
    public func getComics(favorites: Bool = false) -> [Comic]? {
        // Perform Core Data lookup
        let fetchRequest: NSFetchRequest<Comic> = Comic.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if favorites {
            let predicate = NSPredicate(format: "favorite == 1")
            fetchRequest.predicate = predicate
        }
        
        do {
            let comics: [Comic] = try self.moc.fetch(fetchRequest)
            return comics
        } catch {
            print("Error with fetch!")
        }
        
        return nil
    }
    
    public func getComics(withPredicate predicate: NSPredicate) -> [Comic]? {
        let fetchRequest: NSFetchRequest<Comic> = Comic.fetchRequest()
        fetchRequest.sortDescriptors = [self.defaultSortDescriptor]
        fetchRequest.predicate = predicate
        
        do {
            let comics: [Comic] = try self.moc.fetch(fetchRequest)
            return comics
        } catch {
            print("Error with fetch!")
        }
        
        return nil
    }
    
    public func getComic(withId id: Int32) -> Comic? {
        // Perform Core Data lookup
        let fetchRequest: NSFetchRequest<Comic> = Comic.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "id == \(id)")
        fetchRequest.predicate = predicate
        
        do {
            let comics: [Comic] = try self.moc.fetch(fetchRequest)
            if comics.count > 0 {
                return comics[0]
            }
        } catch {
            print("Error with fetch!")
        }
        
        return nil
    }
    
    // MARK: - Images
    public func retrieveImage(forComic comic: Comic) {
        // Download image
        // Save to file
        // Write URL to Comic object
        
        func handleImageData(imageData: Data) {
            // Create image from the data
            do {
                
                guard let image = UIImage(data: imageData) else { throw ComicManagerError.imageDataMarshalling }
                
                // Cache the image
                self.cacheManager.cacheImage(image: image, forComic: comic)
                
                // Delegate the result
                defer {
                    self.delegateImageRetrieved(image: image, comic: comic)
                }
                
            } catch ComicManagerError.imageDataMarshalling {
                defer {
                    self.delegateImageError(error: ComicManagerError.imageDataMarshalling)
                }
            } catch {
                defer {
                    self.delegateImageError(error: ComicManagerError.unknown)
                }
            }
        }
        
        // First, check to see if we have a cached version
        if let image = self.retrieveImageFromCache(forComic: comic) {
            
            defer {
                self.delegateImageRetrieved(image: image, comic: comic)
            }
            
            return
        }
        
        // If there's no cached copy, let's download it.
        let imgUrl = comic.remoteImageUrl! 
        let imgSafeUrl = imgUrl.replacingOccurrences(of: "http", with: "https")
        Alamofire.request(imgSafeUrl).responseData { response in
            switch response.result {
                case .success(let data):
                    handleImageData(imageData: data)
                break
                case .failure(let err):
                    defer {
                        self.delegateImageError(error: err)
                    }
                    debugPrint(err)
                break
            }
        }
    }
    
    public func retrieveImageFromCache(forComic comic: Comic) -> UIImage? {
        if let image = self.cacheManager.imageFromCache(forComic: comic) {
            return image
        }
        
        return nil
    }
    
    // MARK: - Comic Management
    public func favorite(comic: Comic) {
        comic.favorite = true
        
        do {
            try comic.managedObjectContext?.save()
        } catch {
            print("Failed to save favorite!")
        }
    }
    
    public func unfavorite(comic: Comic) {
        comic.favorite = false
        
        do {
            try comic.managedObjectContext?.save()
        } catch {
            print("Failed to save favorite!")
        }
    }
}
