//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 5/25/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        map.delegate = self

        if let regionDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey("region") {
            print("ON LOAD: \(regionDictionary)")
            let center = CLLocationCoordinate2D(latitude: regionDictionary["centerLatitude"] as! CLLocationDegrees, longitude: regionDictionary["centerLongitude"] as! CLLocationDegrees)
            let span = MKCoordinateSpan(latitudeDelta: regionDictionary["latitudeDelta"] as! CLLocationDegrees, longitudeDelta: regionDictionary["longitudeDelta"] as! CLLocationDegrees)   
            let region = MKCoordinateRegion(center: center, span: span)
            map.setRegion(region, animated: true)
        } else {
            // set the user's location by the phone
            print("no location")
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let regionDictionary = ["centerLatitude": map.region.center.latitude, "centerLongitude": map.region.center.longitude, "latitudeDelta": map.region.span.latitudeDelta, "longitudeDelta": map.region.span.longitudeDelta]
        print("BEFORE SAVE: \(regionDictionary)")
        defaults.setValue(regionDictionary, forKey: "region")
        
    
    }

}

