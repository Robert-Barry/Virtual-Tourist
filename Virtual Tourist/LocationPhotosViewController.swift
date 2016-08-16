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

class LocationPhotosViewController: UIViewController {
    
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
    
    var latitude: Double!
    var longitude: Double!
  
    
    
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
        
        updateBottomButton()
    }

    override func viewWillDisappear(animated: Bool) {
        // Save the context when going back to the MapViewController
        save()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        print("in viewWillAppear")
        
        // Change the navigation controller back button text
        navigationController?.navigationBar.topItem?.title = "OK"
        
        // Reset the URLList
        FlickrClient.sharedInstance().URLList.removeAll()

        // Extract the pin's latitude and longitude and make them a double
        latitude = Double(pin.latitude!)
        longitude = Double(pin.longitude!)
        
        // Set the map region
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(center, span)
        
        // Do not allow users to change the map
        map.userInteractionEnabled = false
        // set the map
        map.setRegion(region, animated: false)
        
        // Add an annotation to the map
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        // If there are saved images, load them
        if fetchedResultsController.fetchedObjects!.count == 0 {
            print("No saved images. Loading from Flickr")
            getImagesFromFlickr(latitude, longitude: longitude)
        // Otherwise load the images from Core Data
        } else {
            print("Saved images. Loading from Core Data")
        }
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
    

    
// ACTIONS
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        print("New Collection button pressed")
        
        if selectedIndexes.isEmpty {
            // delete all the images and reload new ones from Flickr
            deleteAllImages()
            print("Loading new images from Flickr")
            getImagesFromFlickr(latitude, longitude: longitude)
        } else {
            // Just delete selected images
            deleteSelectedImages()
        }
    }
    
    
    
// HELPER FUNCTIONS
    func configureCell(cell: LocationImageViewCell, indexPath: NSIndexPath) {
        print("in configureCell")
        
        // Grab the Image object from the fetchedResultsController
        let image = fetchedResultsController!.objectAtIndexPath(indexPath) as! Image
        
        // Add an activity indicator and start it
        cell.activityView.activityIndicatorViewStyle = .WhiteLarge
        cell.activityView.startAnimating()
        cell.activityView.hidesWhenStopped =  true
        
        // Set the image of the cell's image view
        cell.imageViewCell.image = UIImage(data: image.image!)
        
        // If the image that is loaded is NOT a placeholder image
        if image.isPlaceholderImage == false {
            // Stop and hide the activiity view
            cell.activityView.stopAnimating()
        }
        
        // If the cell is "selected" it's image is grayed out
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageViewCell.alpha = 0.4
        } else {
            cell.imageViewCell.alpha = 1.0
        }
        
    }
    
    // Helper function to shorten how the context is saved
    func save() {
        do {
            try stack?.saveContext()
            print("Context saved")
        } catch {
            print("Error while saving")
        }
    }
    
    // Delete only the Image objects in the selectedIndexes array from Core Data
    func deleteSelectedImages() {
        var imagesToDelete = [Image]()
        
        // Loop through each selectedIndex and add the Image object to a new array
        for indexPath in selectedIndexes {
            imagesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Image)
        }
        
        // Delete the images
        for image in imagesToDelete {
            context.deleteObject(image)
        }
        
        // empty the re-initialize the selectedIndexes array to contain no indexes
        selectedIndexes = [NSIndexPath]()
        
        updateBottomButton()
    }
    
    // Load images from Flickr
    func getImagesFromFlickr(latitude: Double, longitude: Double) {
        print("Getting images from Flickr...")
        
        // Use the latitude and longitude of the recieved pin
        let location = ["lat": latitude, "lon": longitude]
        
        FlickrClient.sharedInstance().getImageURLList(location) { success, error in
            if success {
                print("Succes loading the URL list")
                
                // If the Flickr request returns no image URLs, show and alert
                if FlickrClient.sharedInstance().URLList.isEmpty {
                    self.performUIUpdatesOnMain {
                        // Create the alert
                        let alert = self.noImagesToDownloadAlert()
                        // Present the alert
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                
                // Create an array of Image objects with placeholders as the image property
                let images = self.createPlaceholders()
                
                // Use the returned list of URLs to replace the placeholder images
                FlickrClient.sharedInstance().requestImagesFromFlickr(pin: self.pin, latitude: latitude, longitude: longitude, imageObject: images) { success, error in
                    if success {
                        print("Image downloaded")
                        // Save the context when the image downloads
                        self.save()
                    } else {
                        print("Problem loading images")
                    }
                }
            } else {
                print("error")
            }
        }
    }
    
    // Delete all the images in the context
    func deleteAllImages() {
        for image in fetchedResultsController.fetchedObjects as! [Image] {
            context.deleteObject(image)
        }
    }
    
    // Create an alert when no image URLs are downloaded from Flickr
    func noImagesToDownloadAlert() -> UIAlertController {
        let alert = UIAlertController(title: "No Images!", message: "There were no images found at this location!", preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: { action in
            // When the user touches the "OK" button, go back to MapViewController
            self.navigationController?.popToRootViewControllerAnimated(true)
        })
        alert.addAction(alertAction)
        return alert
    }
    
    // Make an array of Image objects with placeholders in the image property
    func createPlaceholders() -> [Image] {
        let placeholder = UIImage(named: "placeholder")
        let placeholderData = UIImageJPEGRepresentation(placeholder!, 1.0)
        var images = [Image]()
        
        // Loop through the list of URLs returned from Flickr
        for _ in FlickrClient.sharedInstance().URLList {
            images.append(Image(image: placeholderData!, pin: pin, isPlaceholderImage: true, context: context!))
        }
        return images
    }
    
    // Change the text of the bottom button depending on whether images are selected
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            newCollection.title = "Remove Selected Images"
        } else {
            newCollection.title = "New Collection"
        }
    }
    
    // GCD
    func performUIUpdatesOnMain(updates: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            updates()
        }
    }
}

    
    
// MARK:  - Data Source
extension LocationPhotosViewController: UICollectionViewDataSource {
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
    
    

}



// MARK:  - Delegate

extension LocationPhotosViewController: UICollectionViewDelegate {
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("in collectionView(_:didSelectItemAtIndexPath)")
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! LocationImageViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, indexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
}



// MARK: - Fetched Results Controller Delegate

// The following code is mostly from Udacity's Color Collection app
extension LocationPhotosViewController:  NSFetchedResultsControllerDelegate {
    
    // Whenever changes are made to Core Data the following three methods are invoked.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }

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
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
            //default:
            //break
        }
    }
    
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
