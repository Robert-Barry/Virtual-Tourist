//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 7/6/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // variables
    var URLList = [NSURL]()
    
    // shared session
    var session = NSURLSession.sharedSession()
    
    // MARK: Reusable Get function
    func taskForGETMethod(parameters: [String: AnyObject], completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        print("Task for GET method called")
        
        // Build the request
        let request = buildRequest(parameters: parameters)
        
        // Build the task
        let task = buildTask(request: request, completionHandler: completionHandlerForGET)
        
        task.resume()
        
        return task
        
    }
    
    // MARK: Helper functions
    
    func buildRequest(parameters parameters: [String:AnyObject]) -> NSMutableURLRequest {
        
        print("Building the request...")
        
        // Create a request
        var request: NSMutableURLRequest

        request = NSMutableURLRequest(URL: URLFromParameters(FlickrClient.Contstants.https, apiHost: FlickrClient.Contstants.host, apiPath: FlickrClient.Contstants.path, parameters: parameters, withPathExtension: ""))
        
        return request
        
    }
    
    func buildTask(request request: NSMutableURLRequest, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        print("Building the task...")
        
        // Create a task
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
            }
            
            // Guard statements to check check that the data is valid
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successfull 2xx response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx: \((response as? NSHTTPURLResponse)?.statusCode))")
                return
            }
            
            // GUARD: Was the data returned
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            // Convert the data to json
            self.convertDataWithCompletionHandler(data: data, completionHandlerForConvertData: completionHandler)
        }
        
        return task
        
    }
    
    // Creates a URL for use in a request
    func URLFromParameters(apiScheme: String, apiHost: String, apiPath: String, parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = apiScheme
        components.host = apiHost
        components.path = apiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        print("Converting data to json...")
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
}