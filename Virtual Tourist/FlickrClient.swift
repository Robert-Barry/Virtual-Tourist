//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension FlickrClient {
    
    func getImages(location: [String:Double], completionHandlerForRequest: (success: Bool, errorString: String?) -> Void) {
        
        getRandomPageNumber(location) { success, data, errorString in

            let numberOfPages = self.getNumberOfPages(data)
            
            // Pick a random page
            let pageLimit = min(numberOfPages, 4000 / Int(FlickrClient.Contstants.FlickrParameterValues.per_page)!)
            let randomPage = String(Int(arc4random_uniform(UInt32(pageLimit))) + 1)
            
            self.getListOfImageURLs(location, randomPage: randomPage) { (success, imageList, errorString) in
                
                if success {
                    
                    self.URLList = self.getListOfURLs(imageList)
                    print("Request complete")
                    completionHandlerForRequest(success: true, errorString: nil)
                    
                } else {
                    completionHandlerForRequest(success: false, errorString: "Could not retrieve the image URLs")
                }
            }
        }
        
        
    }
    
    func requestImagesFromFlickr(pin pin: Pin, latitude latitude: Double, longitude: Double) {
        print("Request from Flickr")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = appDelegate.stack
        let context = stack?.context
        
        let location = ["lat": Double(latitude), "lon": Double(longitude)]
        getImages(location) { success, error in
        if success {
            print("Succes loading the URL list")
            for url in self.URLList {
                self.taskForGETImage(url) { imageData, error in
                    if let image = imageData {
                        _ = Image(image: image, pin: pin, context: context!)
                    }
                        print("Image saved.")
                    }
                }
                
            } else {
                print("error")
            }
        }
        
    }
    
    func getRandomPageNumber(location: [String:Double], completeionHandlerForPageNumber: (success: Bool, data: AnyObject, errorString: String?) -> Void) {
        
        // Getting a random page number from Flickr
        let parameters = getParameters(location)
        
        taskForGETMethod(parameters) { results, error in
            completeionHandlerForPageNumber(success: true, data: results, errorString: nil)
        }
    }
    
    func getListOfImageURLs(location: [String:Double], randomPage: String, completionHandlerForImageList: (success: Bool, imageList: AnyObject, errorString: String?) -> Void) {
        
        var parameters = getParameters(location)
        parameters["page"] = randomPage
        
        taskForGETMethod(parameters) { results, error in
            completionHandlerForImageList(success: true, imageList: results, errorString: nil)
        }
    }
    
    private func getParameters(location: [String:Double]) -> [String: String] {
        return [
            FlickrClient.Contstants.FlickrParameterKeys.method: FlickrClient.Contstants.FlickrParameterValues.method,
            FlickrClient.Contstants.FlickrParameterKeys.api_key: FlickrClient.Contstants.FlickrParameterValues.api_key,
            FlickrClient.Contstants.FlickrParameterKeys.lat: String(location["lat"]!),
            FlickrClient.Contstants.FlickrParameterKeys.lon: String(location["lon"]!),
            FlickrClient.Contstants.FlickrParameterKeys.extras: FlickrClient.Contstants.FlickrParameterValues.extras,
            FlickrClient.Contstants.FlickrParameterKeys.format: FlickrClient.Contstants.FlickrParameterValues.format,
            FlickrClient.Contstants.FlickrParameterKeys.nojsoncallback: FlickrClient.Contstants.FlickrParameterValues.nojsoncallback,
            FlickrClient.Contstants.FlickrParameterKeys.bbox: bboxString(location["lat"]!, lon: location["lon"]!),
            FlickrClient.Contstants.FlickrParameterKeys.per_page:FlickrClient.Contstants.FlickrParameterValues.per_page
        ]
    }
    
    private func bboxString(lat: Double, lon: Double) -> String {
        let latitude = lat
        let longitude = lon
        
        let minimumLon = max(longitude - FlickrClient.Contstants.searchBboxHalfWidth, FlickrClient.Contstants.searchLonRange.0)
        let minimumLat = max(latitude - FlickrClient.Contstants.searchBboxHalfHeight, FlickrClient.Contstants.searchLatRange.0)
        let maximumLon = min(longitude + FlickrClient.Contstants.searchBboxHalfWidth, FlickrClient.Contstants.searchLonRange.1)
        let maximumLat = min(latitude + FlickrClient.Contstants.searchBboxHalfHeight, FlickrClient.Contstants.searchLatRange.1)

        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func getListOfURLs(data: AnyObject) -> [NSURL] {
        
        var URLList = [NSURL]()
        
        if let imageItems = data as? [String: AnyObject] {
            if let FlickrPhotos = imageItems["photos"] as? [String: AnyObject] {
                if let imageData = FlickrPhotos["photo"] as? [[String: AnyObject]] {
                    for image in imageData {
                        if let imageUrl = image["url_m"] {
                            let urlString = String(imageUrl)
                            URLList.append(NSURL(string: urlString)!)
                        }
                    }
                }
            } else {
                print("There are no photos to display")
            }

        } else {
            print("Cannot convert JSON: \(data)")
        }

        return URLList
    }
    
    private func getNumberOfPages(json: AnyObject) -> Int {
        
        if let photos = json["photos"] as? [String: AnyObject] {
            if let pages = photos["pages"] {
                return Int(pages as! NSNumber)
            }
        }
        return 0
    }
    
    // Create a singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}