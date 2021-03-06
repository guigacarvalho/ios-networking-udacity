//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 1/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - Globals

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "063c04acddf53186989318e3194c08f7"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    
    @IBAction func searchPhotosByPhraseButtonTouchUp(sender: AnyObject) {
        /* 1 - Hardcode the arguments */
        let methodArguments: [String: String!] = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": phraseTextField.text,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        /* 2 - Call the Flickr API with these arguments */
        getImageFromFlickrBySearch(methodArguments)
    }
    
    @IBAction func searchPhotosByLatLonButtonTouchUp(sender: AnyObject) {
        print("Will implement this function in a later step...")
    }
    
    // MARK: Flickr API
    
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        
        /* 3 - Get the shared NSURLSession to faciliate network activity */
        let session = NSURLSession.sharedSession()
        
        /* 4 - Create the NSURLRequest using properly escaped URL */
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 5 - Create NSURLSessionDataTask and completion handler */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    print("No photos found, please try again?")
                    self.photoTitleLabel.text = "There was an error with your request.\n Are you offline?"
                    self.photoImageView.image = nil
                })
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* Determine the number of photos */
            /* GUARD: Is "total" key in photosDictionary */
            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find keys 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotos > 0 {
                
                /* GUARD: Is "photo" key in photosDictionary */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photo' in \(photosDictionary)")
                    return
                }
                
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                
                /* Prepare the UI updates */
                let photoTitle = photoDictionary["title"] as? String
                guard let imageURLString = photoDictionary["url_m"] as? String else {
                    print("No url_m key.. Fcking API..")
                    return
                }
                
                let imageURL = NSURL(string: imageURLString)
                
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.photoTitleLabel.text = photoTitle
                        self.photoImageView.image = UIImage(data: imageData)
                    })
                } else {
                    print("Image does not exist at \(imageURL)")
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    print("No photos found, please try again?")
                    self.photoTitleLabel.text = "No photos found"
                    self.photoImageView.image = nil
                    
                    
                })
            }
        }
        
        task.resume()
    }
    
    // MARK: Escape HTML Parameters
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}
