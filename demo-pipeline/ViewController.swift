//
//  ViewController.swift
//  demo-pipeline
//
//  Created by Olivia Barnett on 10/18/17.
//  Copyright © 2017 Olivia Barnett. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager! = CLLocationManager()
    let synthesizer : AVSpeechSynthesizer = AVSpeechSynthesizer()
    let serverAddress = "https://703c2373.ngrok.io"
    var momentString = ""
    var isSendingRequest = false
    
    func convertToDictionary(text: String) -> [String: Any] {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return [String: Any]()
    }
    
    // Begins tracking location after view did load
    func locationManager(_:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        let long = userLocation.coordinate.longitude;
        let lat = userLocation.coordinate.latitude;
        var json = [String:Double]()
        json["longitude"] = long
        json["latitude"] = lat
        print(long)
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            // Send coordinates to the set up server
            // Does this stream??
            let endpoint = self.serverAddress + "/location"
            let endpointUrl = URL(string: endpoint)!
            var request = URLRequest(url: endpointUrl)
            request.httpMethod = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request)
            task.resume()
        } catch{
        }
        
        if (self.momentString == "" && !self.isSendingRequest) {
            self.isSendingRequest = true
            do {
                let endpoint = self.serverAddress + "/moments/1"
                let endpointUrl = URL(string: endpoint)!
                var request = URLRequest(url: endpointUrl)
                request.httpMethod = "GET"
                let task = URLSession.shared.dataTask(with: request) {
                    (data: Data?, response: URLResponse?, error: Error?) in
                    self.isSendingRequest = false
                    if(error != nil) {
                        print("Error: \(error)")
                    } else
                    {
                        
                        let outputStr = String(data: data!, encoding: String.Encoding.utf8) as String!
                        print(outputStr!)
                        self.momentString = outputStr!
                        let momentDict = self.convertToDictionary(text: self.momentString)
                        let utterance : AVSpeechUtterance = AVSpeechUtterance(string: String(describing: momentDict["prompt"]!))
                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        self.synthesizer.speak(utterance)
                        
                    }
                }
                task.resume()
            } catch{
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

