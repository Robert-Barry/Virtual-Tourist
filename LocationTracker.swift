//
//  LocationTracker.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/15/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//
// Location Tracker tracks a user's map location as they search on the map in the map view.
// It uses Core Data to persist the location.

import Foundation
import CoreData


class LocationTracker: NSManagedObject {

    
    convenience init(centerLatitude: Double, centerLongitude: Double, latitudeDelta: Double, longitudeDelta: Double, context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entityForName("LocationTracker", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.centerLatitude = centerLatitude
            self.centerLongitude = centerLongitude
            self.latitudeDelta = latitudeDelta
            self.longitudeDelta = longitudeDelta
        } else {
            fatalError("Unable to find entity named LocationTracker!")
        }
    }
    
    func trackLocation(centerLatitude: Double, _ centerLongitude: Double, _ latitudeDelta: Double, _ longitudeDelta: Double) {
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }

}
