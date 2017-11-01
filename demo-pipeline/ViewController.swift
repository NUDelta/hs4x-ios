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
    let demoId = "2"
    var locationManager: CLLocationManager! = CLLocationManager()
    let synthesizer : AVSpeechSynthesizer = AVSpeechSynthesizer()
    let serverAddress = "http://127.0.0.1:5000"
    var momentString = ""
    var momentPlayed = false
    var lastLocationPostedAt : Double = Date().timeIntervalSinceReferenceDate
    @IBOutlet weak var momentTextLabel: UILabel!
    
    
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
        if Date().timeIntervalSinceReferenceDate - self.lastLocationPostedAt > 2 {
            self.lastLocationPostedAt = Date().timeIntervalSinceReferenceDate
            print("long: \(long), lat: \(long)")
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
            
            if (self.demoId == "2" || self.momentString == "") {

                let endpoint = self.serverAddress + "/moments/" + self.demoId
                let endpointUrl = URL(string: endpoint)!
                var request = URLRequest(url: endpointUrl)
                request.httpMethod = "GET"
                let task = URLSession.shared.dataTask(with: request) {
                    (data: Data?, response: URLResponse?, error: Error?) in
                    if(error != nil) {
                        print("Error: \(error)")
                    } else
                    {
                        
                        let outputStr = String(data: data!, encoding: String.Encoding.utf8) as String!
                        let momentDict = self.convertToDictionary(text: outputStr!)
                        if (momentDict["prompt"] != nil) {
                            self.momentString = String(describing: momentDict["prompt"]!)
                            self.momentPlayed = false
                        }
                    }
                }
                task.resume()
            }
            if (self.momentString != "") {
                self.momentTextLabel.text = self.momentString
                if !self.momentPlayed {
                    let utterance : AVSpeechUtterance = AVSpeechUtterance(string: self.momentString)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    self.synthesizer.speak(utterance)
                    self.momentPlayed = true
                }
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
        
        let endpoint = self.serverAddress + "/register/" + self.demoId
        let endpointUrl = URL(string: endpoint)!
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request)
        task.resume()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

