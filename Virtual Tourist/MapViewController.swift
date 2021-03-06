//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 5/25/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//
// Allows a user to drop pins on a map and click on the pin to see
// randomly chosen images from the area. Map location and pins are
// saved in Core Data.

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
    var arePinsEditable = false // Flag for didSelectAnnotationView
    var label: UILabel!
    var map: MKMapView!
    var selectedAnnotation: MKAnnotation?
    var selectedPin: Pin!
    var animatePins: Bool = true
    var viewLoadedOnce = true // Did the MapView load 1 time?
    var pins = [Pin]()
    
    
    
// OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the map using code
        map = MKMapView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        map.delegate = self
        view.addSubview(map)
        
        // Make a label that instructs user to delete pins
        label = createLabelToDeletePins()
        view.addSubview(label)
        
        // The following code is from Stack Overflow URL:
        //http://stackoverflow.com/questions/29241691/how-do-i-use-uilongpressgesturerecognizer-with-a-uicollectionviewcell-in-swift
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        map.addGestureRecognizer(lpgr)
        
        // initialize the Core Data Stack
        stack = appDelegate.stack
        context = stack.context

        // Create fetch request to get the user's last saved map location data
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
                print("User's previous map location found")
                isMapData = true // The user has used the app
                locationTracker = LocationTracker(centerLatitude: fetchedLocation[0].centerLatitude as! Double, centerLongitude: fetchedLocation[0].centerLongitude as! Double, latitudeDelta: fetchedLocation[0].latitudeDelta as! Double, longitudeDelta: fetchedLocation[0].longitudeDelta as! Double, context: stack.context)
            }
        } catch {
            fatalError("Failed to get previous location: \(error)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // chage the navigation controller title
        navigationController?.navigationBar.topItem?.title = "Virtual Tourist"
        
        // set the label to hidden
        label.center.y = view.frame.height + (68 / 2)
        
        // Remove all the pins from the map to reset pins
        print("Removing all pins")
        pins.removeAll()
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        // Create fetch request to get the user's previously chosen pin locations
        let pinFetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            // fetch the pins from Core Data
            let fetchedPins = try context.executeFetchRequest(pinFetchRequest) as! [Pin]
            
            // If no array is returned, move along
            if fetchedPins.count == 0 {
                print("No saved pins")
                editButton.enabled = false
            } else {
                // otherwise retrieve the saved pins
                pins = fetchedPins
                print("Saved pins found")
                
                // add the saved pins to the map
                for pin in pins {
                    addPinToMap(CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!)))
                    animatePins = false
                }
            }
        } catch {
            fatalError("Failed to check for saved pin locations: \(error)")
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        // Updates the map AFTER iOS does when the view first loads
        // Required to override iOS.
        if let mapData = isMapData {
            // Only set the map location when there is saved data AND
            // the view is loaded for the first time
            if mapData == true && viewLoadedOnce == true {
                setMapLocation()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // The view was loaded before
        viewLoadedOnce = false
        
        // Send pin data to the next view controller
        let controller = segue.destinationViewController as! LocationPhotosViewController
        
        controller.pin = selectedPin
        
        // save the location of the map
        do {
            try stack?.saveContext()
            print("Context saved")
        } catch {
            print("Error while saving")
        }
        
    }
    
    
    
// ACTIONS
    @IBAction func editMap(sender: AnyObject) {
        if pins.count > 0 && editButton.title == "Edit" {
            editButton.title = "Done"
            arePinsEditable = true
            
            // show the label that instructs the user to click a pin
            UIView.animateWithDuration(0.15, animations: {
                self.label.center.y = self.view.frame.height - (68 / 2)
                self.map.center.y -= 68
            })
        } else if editButton.title == "Done" {
            editButton.title = "Edit"
            arePinsEditable = false
            
            if pins.isEmpty {
                editButton.enabled = false
            }
            
            // hide the label that instructs the user to click a pin
            UIView.animateWithDuration(0.15, animations: {
                self.label.center.y = self.view.frame.height + (68 / 2)
                self.map.center.y += 68
            })
        }
    }
    

    
// HELPER FUNCTIONS
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
    
    // Creates the label that instructs the user how to delet pins
    func createLabelToDeletePins() -> UILabel {
        label = UILabel(frame: CGRectMake(0, 0, view.frame.width, 68))
        label.center = CGPointMake(view.frame.width - (view.frame.width / 2), view.frame.height - (68 / 2))
        label.backgroundColor = UIColor.blueColor()
        label.textColor = UIColor.whiteColor()
        label.text = "Tap Pins to Delete"
        label.textAlignment = NSTextAlignment.Center
        return label
    }
    
    // helper function to set the visible map for the user
    func setMapLocation() {
        
        // Use the location tracker to set the map location
        let center = CLLocationCoordinate2D(latitude: locationTracker.centerLatitude as! CLLocationDegrees, longitude: locationTracker.centerLongitude as! CLLocationDegrees)
        
        // Zoom level
        let span = MKCoordinateSpanMake(locationTracker.latitudeDelta as! Double, locationTracker.longitudeDelta as! Double)
        
        let region = MKCoordinateRegionMake(center, span)
        map.setRegion(region, animated: false )
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if arePinsEditable == false {
            
            animatePins = true // animate the new pin being added
            
            if recognizer.state == .Began {
                print("Long press began")
            }
            
            if recognizer.state == .Ended {
                editButton.enabled = true
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
    
    // adds a pin to the map
    func addPinToMap(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        map.addAnnotation(annotation)
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
        // Find the selected pin in the pins array
        print("Pin selected")
        for pin in pins {
            if view.annotation?.coordinate.latitude == pin.latitude && view.annotation?.coordinate.longitude == pin.longitude {
                // Delete the pins if the user chooses to do so
                if arePinsEditable {
                    print("Deleting pins")
                    pins.removeAtIndex(pins.indexOf(pin)!)
                    context.deleteObject(pin)
                    mapView.removeAnnotation(view.annotation!)
                } else {
                    print("Seque to LocationPhotosViewController")
                    selectedAnnotation = view.annotation
                    selectedPin = pin
                    performSegueWithIdentifier("locationPhotos", sender: self)
                }
            }
        }
    }

    // Create the annotation view
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
            view.animatesDrop = animatePins // only animate when adding a new pin
            return view
    }
}



