//
//  LocationTracker+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/15/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension LocationTracker {

    @NSManaged var centerLatitude: NSNumber?
    @NSManaged var centerLongitude: NSNumber?
    @NSManaged var latitudeDelta: NSNumber?
    @NSManaged var longitudeDelta: NSNumber?

}
