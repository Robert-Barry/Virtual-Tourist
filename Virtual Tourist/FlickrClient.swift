//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    func getImages(location: [String:Double], completionHandlerForRequest: (success: Bool, errorString: String?) -> Void) {
        
        getListOfImageURLs(location) { (success, imageList, errorString) in
            
            if success {
                
                self.URLList = self.getListOfURLs(imageList)
                print("Request complete")
                completionHandlerForRequest(success: true, errorString: nil)
                
            } else {
                completionHandlerForRequest(success: false, errorString: "Could not retrieve the image URLs")
            }
        }
    }
    
    func getListOfImageURLs(location: [String:Double], completionHandlerForImageList: (success: Bool, imageList: AnyObject, errorString: String?) -> Void) {
        
        let parameters = [
            FlickrClient.Contstants.FlickrParameterKeys.method: FlickrClient.Contstants.FlickrParameterValues.method,
            FlickrClient.Contstants.FlickrParameterKeys.api_key: FlickrClient.Contstants.FlickrParameterValues.api_key,
            FlickrClient.Contstants.FlickrParameterKeys.lat: String(location["lat"]!),
            FlickrClient.Contstants.FlickrParameterKeys.lon: String(location["lon"]!),
            FlickrClient.Contstants.FlickrParameterKeys.extras: FlickrClient.Contstants.FlickrParameterValues.extras,
            FlickrClient.Contstants.FlickrParameterKeys.format: FlickrClient.Contstants.FlickrParameterValues.format,
            FlickrClient.Contstants.FlickrParameterKeys.nojsoncallback: FlickrClient.Contstants.FlickrParameterValues.nojsoncallback,
            FlickrClient.Contstants.FlickrParameterKeys.bbox: bboxString(),
            FlickrClient.Contstants.FlickrParameterKeys.per_page:FlickrClient.Contstants.FlickrParameterValues.per_page
        ]
        
        taskForGETMethod(parameters) { results, error in
            completionHandlerForImageList(success: true, imageList: results, errorString: nil)
        }
    }
    
    private func bboxString() -> String {
        let latitude = 40.4406
        let longitude = -79.9959
        
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
    
    // Create a singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}