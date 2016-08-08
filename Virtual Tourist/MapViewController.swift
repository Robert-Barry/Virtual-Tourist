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
    @IBOutlet weak var editButton: UIBarButtonItem!
    
// CONSTANTS
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
// VARIABLES
    var stack: CoreDataStack!
    var context: NSManagedObjectContext!
    var locationTracker: LocationTracker!
    var isMapData: Bool? // Has the user used the app before?
    var arePinsEditable = false
    var label: UILabel!
    var map: MKMapView!
    var selectedAnnotation: MKAnnotation?
    var animatePins: Bool = true
    
    var pins = [Pin]()
    
    
    
// OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the map using code
        map = MKMapView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        map.delegate = self
        view.addSubview(map)
        
        
        // Create a button to delete pins
        label = UILabel(frame: CGRectMake(0, 0, view.frame.width, 68))
        label.center = CGPointMake(view.frame.width - (view.frame.width / 2), view.frame.height - (68 / 2))
        label.backgroundColor = UIColor.blueColor()
        label.textColor = UIColor.whiteColor()
        label.text = "Tap Pins to Delete"
        label.textAlignment = NSTextAlignment.Center
        view.addSubview(label)
        
        // The following code is from Stack Overflow URL:
        //http://stackoverflow.com/questions/29241691/how-do-i-use-uilongpressgesturerecognizer-with-a-uicollectionviewcell-in-swift
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        //lpgr.delegate = self
        map.addGestureRecognizer(lpgr)
        
        // Core Data Stack
        stack = appDelegate.stack
        context = stack.context
        
        
        let pinFetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Create fetch request to get the users last location data
        let fetchRequest = NSFetchRequest(entityName: "LocationTracker")
        
        do {
            // fetch location from Core Data
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
            fatalError("Failed to get previous location: \(error)")
        }
        
        do {
            // fetch the pins from Core Data
            let fetchedPins = try context.executeFetchRequest(pinFetchRequest) as! [Pin]
            
            // If no array is returned, move along
            if fetchedPins.count == 0 {
                print("No saved pins")
            } else {

                pins = fetchedPins
                print("Saved pins found")
                
                animatePins = false
                
                for pin in pins {
                    addPinToMap(CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!)))
                }
                
                animatePins = true
            }
        } catch {
            fatalError("Failed to check for saved pin locations: \(error)")
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        label.center.y = view.frame.height + (68 / 2)
        
        print("Map annotations count: \(map.annotations.count)")

    }
    
    override func viewDidAppear(animated: Bool) {
        // Updates the map AFTER iOS does when the view first loads 
        if let mapData = isMapData {
            if mapData {
                setMapLocation()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Send latitude and longitude data to the next view controller
        let controller = segue.destinationViewController as! LocationPhotosViewController
        
        controller.latitude = selectedAnnotation?.coordinate.latitude
        controller.longitude = selectedAnnotation?.coordinate.longitude
        
        do {
            try stack?.saveContext()
            print("Context saved")
        } catch {
            print("Error while saving")
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
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if arePinsEditable == false {
        
            if recognizer.state == .Began {
                print("Long press began")
            }
        
            if recognizer.state == .Ended {
                let touchPoint = recognizer.locationInView(map)
                
                // Coordinates chosen by user
                let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
                
                // Append a new pin to the array
                pins.append(Pin(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude, context: context))
                
                // Create the annotation
                addPinToMap(newCoordinates)
            }
        }
    }
    
    
    func addPinToMap(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        map.addAnnotation(annotation)
    }

    @IBAction func editMap(sender: AnyObject) {
        print("Can edit pins")
        if editButton.title == "Edit" {
            editButton.title = "Done"
            arePinsEditable = true
            UIView.animateWithDuration(0.15, animations: {
                self.label.center.y = self.view.frame.height - (68 / 2)
                self.map.center.y -= 68
            })
        } else {
            editButton.title = "Edit"
            arePinsEditable = false
            UIView.animateWithDuration(0.15, animations: {
                self.label.center.y = self.view.frame.height + (68 / 2)
                self.map.center.y += 68
            })
        }
    }
    
    
// DELEGATE MKMapViewDelegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Track the map's location when the user changes the map
        if mapViewRegionDidChangeFromUserInteraction() {
            print("User changed region")
            locationTracker.trackLocation(map.region.center.latitude, map.region.center.longitude, map.region.span.latitudeDelta, map.region.span.longitudeDelta)
        }

    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Delete the pins if the user chooses to do so
        if arePinsEditable {
            print("Edit pins")
            for pin in pins {
                if view.annotation?.coordinate.latitude == pin.latitude && view.annotation?.coordinate.longitude == pin.longitude {
                    pins.removeAtIndex(pins.indexOf(pin)!)
                    context.deleteObject(pin)
                    mapView.removeAnnotation(view.annotation!)
                   
                }
            }
        } else {
            selectedAnnotation = view.annotation
            performSegueWithIdentifier("locationPhotos", sender: self)
        }
        print("Number of pins: \(pins.count)")
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            return view
    }
}



