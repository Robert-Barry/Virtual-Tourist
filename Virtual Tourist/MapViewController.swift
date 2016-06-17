//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 5/25/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

// OUTLETS
    @IBOutlet weak var map: MKMapView!
    
// CONSTANTS
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
// VARIABLES
    var stack: CoreDataStack!
    var locationTracker: LocationTracker!
    var isMapData: Bool? // Has the user used the app before?
    
    
    
// OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.delegate = self
        
        // Core Data Stack
        stack = appDelegate.stack
        
        // Create fetch request to get the users last location data
        let fetchRequest = NSFetchRequest(entityName: "LocationTracker")
        
        do {
            // fetch Core Data
            let fetchedLocation = try stack.context.executeFetchRequest(fetchRequest) as! [LocationTracker]
            
            // If no array is returned, then the user has never used the app
            if fetchedLocation.count == 0 {
                print("No Data")
                isMapData = false // The user has never used the app
                locationTracker = LocationTracker(centerLatitude: map.region.center.latitude, centerLongitude: map.region.center.longitude, latitudeDelta: map.region.span.latitudeDelta, longitudeDelta: map.region.span.longitudeDelta, context: stack.context)
            } else {
                isMapData = true // The user has used the app
                locationTracker = LocationTracker(centerLatitude: fetchedLocation[0].centerLatitude as! Double, centerLongitude: fetchedLocation[0].centerLongitude as! Double, latitudeDelta: fetchedLocation[0].latitudeDelta as! Double, longitudeDelta: fetchedLocation[0].longitudeDelta as! Double, context: stack.context)
                
                // Once the Core Data information has been fetched, delete it
                for item in fetchedLocation {
                    stack.context.deleteObject(item)
                }
            }
        } catch {
            fatalError("Failed to previous location: \(error)")
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        // Updates the map AFTER iOS does when the view first loads 
        if let mapData = isMapData {
            if mapData {
                setMapLocation()
            }
        }
    }
    
    // The function mapViewRegionDidChangeFromUserInteraction() comes from this Stack Overflow URL:
    // http://stackoverflow.com/questions/33131213/regiondidchange-called-several-times-on-app-load-swift
    // It tests if the map was changed by the user or by iOS
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.map.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    // helper function to set the visible map for the user
    func setMapLocation() {
        
        let center = CLLocationCoordinate2D(latitude: locationTracker.centerLatitude as! CLLocationDegrees, longitude: locationTracker.centerLongitude as! CLLocationDegrees)
        
        // Zoom level
        let span = MKCoordinateSpanMake(locationTracker.latitudeDelta as! Double, locationTracker.longitudeDelta as! Double)

        let region = MKCoordinateRegionMake(center, span)
        map.setRegion(region, animated: false )
    }
    
    @IBAction func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        //print("Long press")
        var touchPoint = recognizer.locationInView(map)
        var newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        map.addAnnotation(annotation)
        if recognizer.state == .Ended {
            return
        }
        print(annotation)
    }

    
    
// DELEGATE MKMapViewDelegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        if mapViewRegionDidChangeFromUserInteraction() {
            print("User changed region")
            locationTracker.trackLocation(map.region.center.latitude, map.region.center.longitude, map.region.span.latitudeDelta, map.region.span.longitudeDelta)
        }

    }

}

