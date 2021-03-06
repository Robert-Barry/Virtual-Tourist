//
//  Image.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 8/15/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation
import CoreData


class Image: NSManagedObject {

    convenience init(image: NSData, pin: Pin, isPlaceholderImage: Bool, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context) {
                self.init(entity: entity, insertIntoManagedObjectContext: context)
                self.image = image
                self.pin = pin
                self.isPlaceholderImage = isPlaceholderImage
        } else {
            fatalError("Unable to find entity named Image")
        }
    }
    
    var isPlaceholderImage: Bool {
        get {
            return Bool(isPlaceholder!)
        }
        set {
            isPlaceholder = NSNumber(bool: newValue)
        }
    }
}
