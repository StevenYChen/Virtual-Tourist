//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/25/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class FlickrClient : NSObject {

    let APIBaseURL = "https://api.flickr.com/services/rest/"

    func getFlickrPhotoAlbumPages(pin: Pin, completionHandler: (pages:Int?, error: String?) -> Void) {
        
        let longitude = -pin.longitude
        
        let methodParameters: [String: AnyObject] = [
            "method":           "flickr.photos.search",
            "api_key":          "8bd47512e75c46ff25915f98448956a8",
            "format":           "json",
            "lat":              pin.latitude,
            "lon":              pin.longitude,
            "accuracy":          6,
            "nojsoncallback":   1,
            "safe_search":      1,
            "extras":            "url_m"
            //    "page":             pageRandom()
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = APIBaseURL + escapedParameters(methodParameters)
        print(urlString)
        
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, error in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
                print("URL at time of error: \(url)")
                completionHandler(pages: 0, error: error)
                return
            }
            
            if error == nil{
                let parsedResult: AnyObject!
                
                // there was data returned
                
                if let data = data{
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                        print(parsedResult)
                    } catch {
                        displayError("Could not parse the data as JSON: '\(data)'")
                        return
                    }
                    
                    guard let photosDictionary = parsedResult["photos"] as? [String: AnyObject] else {
                        print("photo dictionary not found")
                        return
                    }
                    
                    guard let pages = photosDictionary["pages"] as? Int else{
                        print("error parsing photoArray")
                        return
                    }
                    completionHandler(pages: pages, error: nil)
                }
            }
        }
        task.resume()
    }

    func getFlickrPhotoAlbum(pin: Pin, completionHandler: (photosArray:[[String:AnyObject]]?, error: String?) -> Void) {
        
        let longitude = -pin.longitude
        
        let methodParameters: [String: AnyObject] = [
            "method":           "flickr.photos.search",
            "api_key":          "8bd47512e75c46ff25915f98448956a8",
            "format":           "json",
            "lat":              pin.latitude,
            "lon":              pin.longitude,
            "accuracy":          6,
            "nojsoncallback":   1,
            "safe_search":      1,
            "extras":            "url_m"
        //    "page":             pageRandom()
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = APIBaseURL + escapedParameters(methodParameters)
        print(urlString)
        
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, error in

            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
                print("URL at time of error: \(url)")
                completionHandler(photosArray: nil, error: error)
                return
            }
            
            if error == nil{
                let parsedResult: AnyObject!
                
                // there was data returned
                
                if let data = data{
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                        print(parsedResult)
                    } catch {
                        displayError("Could not parse the data as JSON: '\(data)'")
                        return
                    }

                    guard let photosDictionary = parsedResult["photos"] as? [String: AnyObject] else {
                        print("photo dictionary not found")
                        return
                    }
                    
                    guard let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] else{
                        print("error parsing photoArray")
                        return
                    }
                    
                    if photosDictionary.count == 0{
                        completionHandler(photosArray: nil, error: "No Photos Found")
                    } else{
                        completionHandler(photosArray: photosArray, error: nil)
                    }
                }
            }
        }
        task.resume()
    }
    
    
    private func escapedParameters(parameters: [String: AnyObject]) -> String{ // input named parameter of type dictionary, returns type string
        
        if parameters.isEmpty{
            return " "
        }else{
            var keyValuePairs = [String]()
            
            for (key, value) in parameters{
                // make sure it's a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joinWithSeparator("&"))"
        }
    }
    
    // MARK: Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}