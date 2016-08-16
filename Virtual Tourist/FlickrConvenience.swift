//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension FlickrClient {
    
    // Get a list of URLs to a random page of images on Flickr
    func getImageURLList(location: [String:Double], completionHandlerForRequest: (success: Bool, errorString: String?) -> Void) {
        // Make a request for images from Flickr
        getPages(location) { success, data, errorString in
            // Get the number of pages returned
            let numberOfPages = self.getNumberOfPages(data)
            
            // Pick a random page
            let pageLimit = min(numberOfPages, 4000 / Int(FlickrClient.Contstants.FlickrParameterValues.per_page)!)
            let randomPage = String(Int(arc4random_uniform(UInt32(pageLimit))) + 1)
            
            // Get a list of URLs to images
            self.getListOfImageURLs(location, randomPage: randomPage) { (success, imageList, errorString) in
                
                if success {
                    // Add the URLs to the URLList property
                    self.URLList = self.getListOfURLs(imageList)
                    print("Request complete")
                    
                    completionHandlerForRequest(success: true, errorString: nil)
                    
                } else {
                    completionHandlerForRequest(success: false, errorString: "Could not retrieve the image URLs")
                }
            }
        }
    }
 
    // Request the images using the URLList property
    func requestImagesFromFlickr(pin pin: Pin, latitude: Double, longitude: Double, imageObject: [Image], completionHandlerForRequest: (success: Bool, errorString: String?) -> Void) {
        var i = 0 // track the index of the URLList
        // Get an image for each URL in the URLList
        for url in self.URLList {
            self.taskForGETImage(url) { imageData, error in
                if let image = imageData {
                    // assign an Image object to the array of Image objects
                    imageObject[i].image = image
                    // this image is not a placeholder
                    imageObject[i].isPlaceholderImage = false
                    i = i + 1
                    completionHandlerForRequest(success: true, errorString: nil)
                } else {
                    completionHandlerForRequest(success: false, errorString: "There was an error loading an image")
                }
            }
        }
    }
    
    // Make the first request to Flickr for the basic information
    func getPages(location: [String:Double], completeionHandlerForPageNumber: (success: Bool, data: AnyObject, errorString: String?) -> Void) {
        
        // Getting a random page number from Flickr
        let parameters = getParameters(location)
        
        taskForGETMethod(parameters) { results, error in
            completeionHandlerForPageNumber(success: true, data: results, errorString: nil)
        }
    }
    
    // Get a list of Image URLs
    func getListOfImageURLs(location: [String:Double], randomPage: String, completionHandlerForImageList: (success: Bool, imageList: AnyObject, errorString: String?) -> Void) {
        
        var parameters = getParameters(location)
        parameters["page"] = randomPage
        
        taskForGETMethod(parameters) { results, error in
            completionHandlerForImageList(success: true, imageList: results, errorString: nil)
        }
    }
    
    // Create the parameters used in the URL of the request to Flickr
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
    
    // Create a bounding box
    private func bboxString(lat: Double, lon: Double) -> String {
        let latitude = lat
        let longitude = lon
        
        let minimumLon = max(longitude - FlickrClient.Contstants.searchBboxHalfWidth, FlickrClient.Contstants.searchLonRange.0)
        let minimumLat = max(latitude - FlickrClient.Contstants.searchBboxHalfHeight, FlickrClient.Contstants.searchLatRange.0)
        let maximumLon = min(longitude + FlickrClient.Contstants.searchBboxHalfWidth, FlickrClient.Contstants.searchLonRange.1)
        let maximumLat = min(latitude + FlickrClient.Contstants.searchBboxHalfHeight, FlickrClient.Contstants.searchLatRange.1)

        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // Assign the URLs to a URLList
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
    
    // Get the number of pages available from FLickr
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