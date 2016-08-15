//
//  LocationPhotosViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/23/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
// OUTLETS
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
// CONSTANTS
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
// VARIABLES
    var pin: Pin!
    var stack: CoreDataStack!
    var context: NSManagedObjectContext!
    var thereAreSavedImages: Bool!
    var fetchedResultsController: NSFetchedResultsController!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    

    
    
// OVERRIDES
    override func viewDidLoad() {
        print("in viewDidLoad()")
        
        super.viewDidLoad()
        
        // assign the context
        stack = appDelegate.stack
        context = stack.context
        
        // initialize the context
        fetchedResultsController = {
            let fetchRequest = NSFetchRequest(entityName: "Image")
            fetchRequest.predicate = NSPredicate(format: "pin = %@", self.pin)
            fetchRequest.sortDescriptors = []
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            
            return fetchedResultsController
        }()
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController!.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
    }

    
    // Save the context when going back to the MapViewController
    override func viewWillDisappear(animated: Bool) {
        do {
            try stack?.saveContext()
            print("Context saved")
        } catch {
            print("Error while saving")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        print("in viewWillAppear")
        
        // Reset the URLList
        FlickrClient.sharedInstance().URLList.removeAll()

        // Extract the pin's latitude and longitude and make them a double
        let latitude = Double(pin.latitude!)
        let longitude = Double(pin.longitude!)
        
        // Set the map region
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(center, span)
        
        map.userInteractionEnabled = false
        
        map.setRegion(region, animated: false)
        
        // Add an annotation to the map
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        // If there are saved images, load them
        if fetchedResultsController.fetchedObjects!.count == 0 {
            print("No saved images. Loading from Flickr")
            FlickrClient.sharedInstance().isPlaceholder = true
            getImagesFromFlickr(latitude, longitude: longitude)
        // Otherwise load the images from Core Data
        } else {
            print("Saved images. Loading from Core Data")
            FlickrClient.sharedInstance().isPlaceholder = false
        }
    }
    
    func configureCell(cell: LocationImageViewCell, indexPath: NSIndexPath) {
        print("in configureCell")
        
        let image = fetchedResultsController!.objectAtIndexPath(indexPath) as! Image
        
        cell.activityView.activityIndicatorViewStyle = .WhiteLarge
        cell.activityView.startAnimating()
        cell.activityView.hidesWhenStopped =  true
        
        cell.imageViewCell.image = UIImage(data: image.image!)
        
        if image.isPlaceholderImage == false {
            cell.activityView.stopAnimating()
        }
        
        // If the cell is "selected" it's image is grayed out
        /*
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageViewCell.alpha = 0.05
        } else {
            cell.imageViewCell.alpha = 1.0
        }
 */
    }
    
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        print("New Collection button pressed")
        
        if newCollection.title == "New Collection" {
            newCollection.enabled = false
            if selectedIndexes.isEmpty {
                deleteAllImages()
            }
            getImagesFromFlickr(Double(pin.latitude!), longitude: Double(pin.longitude!))
            //FlickrClient.sharedInstance().requestImagesFromFlickr(pin: pin, latitude: Double(pin.latitude!), longitude: Double(pin.longitude!), imageObject: images)
            
        }
    }
    
    func getImagesFromFlickr(latitude: Double, longitude: Double) {
        let location = ["lat": latitude, "lon": longitude]
        FlickrClient.sharedInstance().getImageURLList(location) { success, error in
            if success {
                print("Succes loading the URL list")
                let images = self.createPlaceholders()
                FlickrClient.sharedInstance().requestImagesFromFlickr(pin: self.pin, latitude: latitude, longitude: longitude, imageObject: images) { success, error in
                    if success {
                        print("Image downloaded")
                        do {
                            try self.stack?.saveContext()
                            print("Context saved")
                        } catch {
                            print("Error while saving")
                        }
                    } else {
                        print("Problem loading images")
                    }
                }
            } else {
                print("error")
            }
        }
    }
    
    func deleteAllImages() {
        for image in fetchedResultsController.fetchedObjects as! [Image] {
            context.deleteObject(image)
        }
    }
// HELPER FUNCTIONS
    
    
    func createPlaceholders() -> [Image] {
        FlickrClient.sharedInstance().isPlaceholder = true
        let placeholder = UIImage(named: "placeholder")
        let placeholderData = UIImageJPEGRepresentation(placeholder!, 1.0)
        var images = [Image]()
        for url in FlickrClient.sharedInstance().URLList {
            images.append(Image(image: placeholderData!, pin: pin, isPlaceholderImage: true, context: context!))
            print(images.count)
        }
        return images
    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        print("in viewDidLayoutSubviews()")
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3
        
        let width = floor(self.collectionView.frame.size.width/3 - 2)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("in collectionView(_:numberOfItemsInSection)")
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Create the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! LocationImageViewCell
        
        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func performUIUpdatesOnMain(updates: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            updates()
        }
    }

}

// MARK:  - Fetches
extension LocationPhotosViewController {
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK:  - Delegate

extension LocationPhotosViewController {
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
            //default:
            //break
        }
    }
    
    
    
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}
