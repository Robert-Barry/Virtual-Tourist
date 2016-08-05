//
//  Image+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 8/2/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import UIKit

extension Image {

    @NSManaged var image: NSData?
    @NSManaged var pin: Pin?

}
