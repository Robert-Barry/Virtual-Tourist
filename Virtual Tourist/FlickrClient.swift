//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation

class FlickrClient {
    
    func createNSURL() -> NSURL {
        let urlComponents = NSURLComponents()
        
        urlComponents.scheme = FlickrClient.Contstants.https
        urlComponents.host = FlickrClient.Contstants.host
        urlComponents.path = FlickrClient.Contstants.path
        
        urlComponents.queryItems = [
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.method, value: FlickrClient.Contstants.FlickrParameterValues.method),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.api_key, value: FlickrClient.Contstants.FlickrParameterValues.api_key),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.lat, value: "40.4406"),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.lon, value: "79.9959"),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.extras, value: FlickrClient.Contstants.FlickrParameterValues.extras),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.format, value: FlickrClient.Contstants.FlickrParameterValues.format),
            NSURLQueryItem(name: FlickrClient.Contstants.FlickrParameterKeys.nojsoncallback, value: FlickrClient.Contstants.FlickrParameterValues.nojsoncallback)
        ]
        
        print(urlComponents.URL!)
        
        return urlComponents.URL!
        
    }
    
    func getRequest() {
        let request = NSURLRequest(URL: createNSURL())
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            
            if error == nil {
                let parsedResult: AnyObject!
                if let data = data {
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    } catch {
                        print("Could not parse the data as json: \(data)")
                        return
                    }
                    
                    if let photosDictionary = parsedResult["photos"] as? [String: AnyObject] {
                        print(photosDictionary)
                    }
                }
            }
        }
        task.resume()
    }
}