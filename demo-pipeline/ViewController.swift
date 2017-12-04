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
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    //init variables
    var locationManager: CLLocationManager! = CLLocationManager()
    let synthesizer : AVSpeechSynthesizer = AVSpeechSynthesizer()
    let serverAddress = "https://hs4x.herokuapp.com"
    var momentString = ""
    var momentPlayed = false
    var lastLocationPostedAt : Double = Date().timeIntervalSinceReferenceDate
    @IBOutlet weak var momentTextLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    //used to convert http string response to json
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
    //called every time the location updates
    func locationManager(_:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        let long = userLocation.coordinate.longitude;
        let lat = userLocation.coordinate.latitude;
        
        //code to make map follow user
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005))
        mapView.setRegion(region, animated: false)

        var json = [String:Double]()
        json["longitude"] = long
        json["latitude"] = lat
        //dont post faster than once a second
        if Date().timeIntervalSinceReferenceDate - self.lastLocationPostedAt > 1 {
            self.lastLocationPostedAt = Date().timeIntervalSinceReferenceDate
            print("lat: \(lat), long: \(long)")
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
                let task = URLSession.shared.dataTask(with: request) {
                    //async callback - cant edit ui if not in main thread
                    (data: Data?, response: URLResponse?, error: Error?) in
                    if(error != nil) {
                        print("Error: \(error)")
                    } else
                    {
                        let outputStr = String(data: data!, encoding: String.Encoding.utf8) as String!
                        print(outputStr!)
                        let momentDict = self.convertToDictionary(text: outputStr!)
                        if (momentDict["prompt"] != nil) {
                            //set field
                            self.momentString = String(describing: momentDict["prompt"]!)
                            //print(self.momentString)
                            //play the text
                            let utterance : AVSpeechUtterance = AVSpeechUtterance(string: self.momentString)
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            self.synthesizer.speak(utterance)
                        }
                        else {
                            self.momentString = ""
                            // print(self.momentString)
                        }
                    }
                }
                task.resume()
            } catch{
            }
            
        }
        
        //since this is called regularly, it will update the ui one call after the field has been set
        if self.momentString != "" {
            self.momentTextLabel.text = self.momentString
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //location stuff:
        
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
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 1)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

