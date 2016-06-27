//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/27/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Contstants {
        
        static let host = "api.flickr.com"
        static let path = "/services/rest/"
        static let https = "https"
        
        // MARK: Flickr Parameter Keys
        struct FlickrParameterKeys {
            static let method = "method"
            static let api_key = "api_key"
            static let lat = "lat"
            static let lon = "lon"
            static let extras = "extras"
            static let format = "format"
            static let nojsoncallback = "nojsoncallback"
        }
        
        // MARK: Flickr Parameter Values
        struct FlickrParameterValues {
            static let api_key = "XXX"
            static let method = "flickr.photos.search"
            static let extras = "url_m"
            static let format = "json"
            static let nojsoncallback = "1"
        }
    }
}