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

    func getFlickrPhotoAlbum(pin: Pin, page:UInt32, completionHandler: (photosArray:[[String:AnyObject]]?, maxPages:Int?, error: String?) -> Void) {
        
        let longitude = -pin.longitude
        var random:Int
        if page > 100{
             random = Int( arc4random_uniform(100))
        }else{
            random =  Int(arc4random_uniform(page-1))

        }
        let methodParameters: [String: AnyObject] = [
            "method":           "flickr.photos.search",
            "api_key":          "8bd47512e75c46ff25915f98448956a8",
            "format":           "json",
            "lat":              pin.latitude,
            "lon":              pin.longitude,
            "accuracy":          6,
            "nojsoncallback":   1,
            "safe_search":      1,
            "extras":            "url_m",
            "per_page":         20,
            "page":             random
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
                completionHandler(photosArray: nil, maxPages: 0, error: error)
                return
            }
            
            if error == nil{
                let parsedResult: AnyObject!
                
                // there was data returned
                
                if let data = data{
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
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
                    
                    guard let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] else{
                        print("error parsing photoArray")
                        return
                    }
                    
                    if photosDictionary.count == 0{
                        completionHandler(photosArray: nil, maxPages:0, error: "No Photos Found")
                    } else{
                        completionHandler(photosArray: photosArray, maxPages:pages, error: nil)
                    }

                }
            }
        }
        task.resume()
    }
    
    func downloadImage(imagePath:String, completionHandler: (success: Bool, imageData:NSData, errorString: String?) -> Void){
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(URL: imgURL!)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {data, response, error in
            
            if error != nil {
                completionHandler(success: false, imageData:data!, errorString: "Could not download image \(imagePath)")
            } else {
                completionHandler(success: true, imageData: data!, errorString: nil)
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