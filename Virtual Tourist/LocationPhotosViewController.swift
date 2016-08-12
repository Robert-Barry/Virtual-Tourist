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
        
        // set the layout of the collection view
        setFlowLayout()
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
        
        if fetchedResultsController.fetchedObjects!.count == 0 {
            FlickrClient.sharedInstance().requestImagesFromFlickr(pin: pin, latitude: latitude, longitude: longitude)
        }
    }
    
    func configureCell(cell: LocationImageViewCell, indexPath: NSIndexPath) {
        print("in configureCell")
        
        let image = fetchedResultsController!.objectAtIndexPath(indexPath) as! Image
        
        cell.imageViewCell.image = UIImage(data: image.image!)
        
        // If the cell is "selected" it's image is grayed out
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageViewCell.alpha = 0.05
        } else {
            cell.imageViewCell.alpha = 1.0
        }
    }
    
    
// HELPER FUNCTIONS
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("Cell")
        // Create the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! LocationImageViewCell
        
        cell.activityView.hidesWhenStopped = true
        cell.activityView.activityIndicatorViewStyle = .WhiteLarge
        cell.activityView.startAnimating()
        
        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func performUIUpdatesOnMain(updates: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            updates()
        }
    }
    
    func setFlowLayout() {
        print("Setting flow layout")
        let space: CGFloat = 1.0

        let dimension: CGFloat = (self.view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumLineSpacing = 3.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
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
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
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
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
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
