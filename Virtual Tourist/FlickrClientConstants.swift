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
        
        static let searchBboxHalfWidth = 0.25
        static let searchBboxHalfHeight = 0.25
        static let searchLatRange = (-90.0, 90.0)
        static let searchLonRange = (-180.0, 180.0)
        
        // MARK: Flickr Parameter Keys
        struct FlickrParameterKeys {
            static let method = "method"
            static let api_key = "api_key"
            static let lat = "lat"
            static let lon = "lon"
            static let extras = "extras"
            static let format = "format"
            static let nojsoncallback = "nojsoncallback"
            static let bbox = "bbox"
            static let per_page = "per_page"
        }
        
        // MARK: Flickr Parameter Values
        struct FlickrParameterValues {
            static let api_key = "120c0e377f74dec2a67de59766bc79ca"
            static let method = "flickr.photos.search"
            static let extras = "url_m"
            static let format = "json"
            static let nojsoncallback = "1"
            static let per_page = "21"
            
        }
    }
}