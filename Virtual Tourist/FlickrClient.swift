//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func createNSURL() -> NSURL {
        let urlComponents = NSURLComponents()
        
        urlComponents.scheme = FlickrClient.Contstants.https
        urlComponents.host = FlickrClient.Contstants.host
        urlComponents.path = FlickrClient.Contstants.path
        
        urlComponents.queryItems = [
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.method, value: FlickrClient.Contstants.FlickrParameterValues.method),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.api_key, value: FlickrClient.Contstants.FlickrParameterValues.api_key),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.lat, value: "40.4406"),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.lon, value: "-79.9959"),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.extras, value: FlickrClient.Contstants.FlickrParameterValues.extras),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.format, value: FlickrClient.Contstants.FlickrParameterValues.format),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.nojsoncallback, value: FlickrClient.Contstants.FlickrParameterValues.nojsoncallback),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.bbox, value: bboxString()),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.per_page, value: FlickrClient.Contstants.FlickrParameterValues.per_page)
        ]
        
        return urlComponents.URL!
        
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
    
    func getRequest() {
        let url = createNSURL()
        let request = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            
            func displayError(error: String) {
                print(error)
                print("URL at time of error: \(url)")
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2XX!")
                return
            }
            
            // GUARD: Was there data returned?
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("Could not parse the data as json: \(data)")
                return
            }
            
            // GUARD: Did Flickr return an error (stat != ok)?
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            // GUARD: Are the "photos" and "photo" keys in our result?
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject], photoArray = photosDictionary["photo"] as? [[String:AnyObject]] else {
                displayError("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                return
            }
            
            var newPhotosArray: [String] = []
            
            for item in photoArray {
                newPhotosArray.append(item["url_m"] as! String)
            }
            
            print(newPhotosArray)
            self.locationImages = newPhotosArray
            
            print(self.locationImages)
            
        }
        task.resume()
    }
    
    func getImage(imageUrl: String) -> NSData {
        let url = NSURL(fileURLWithPath: imageUrl)
        let request = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            
            func displayError(error: String) {
                print(error)
                print("URL at time of error: \(url)")
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2XX!")
                return
            }
            
            // GUARD: Was there data returned?
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }

        }
        
        task.resume()
    }
    
    // Create a singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}