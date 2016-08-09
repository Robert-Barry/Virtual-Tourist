//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 8/2/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.images = Set<Image>()
        } else {
            fatalError("Unable to find entity named Pin")
        }
    }
    
    func convertToImageArray() -> [UIImage] {
        var imageArray = [UIImage]()
        
        for imageData in self.images! {
            imageArray.append(UIImage(data: imageData.image)!)
        }
        
        return imageArray
    }
}
