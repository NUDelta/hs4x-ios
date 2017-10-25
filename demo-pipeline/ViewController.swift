//
//  ViewController.swift
//  demo-pipeline
//
//  Created by Olivia Barnett on 10/18/17.
//  Copyright © 2017 Olivia Barnett. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager! = CLLocationManager()
    
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
            let endpoint = "https://f6703fce.ngrok.io/location"
            let endpointUrl = URL(string: endpoint)!
            var request = URLRequest(url: endpointUrl)
            request.httpMethod = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request)
            task.resume()
        }catch{
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

