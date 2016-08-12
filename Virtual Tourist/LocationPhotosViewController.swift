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
    @IBOutlet weak var collectionView: CoreDataCollectionViewController!
    
// CONSTANTS
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
// VARIABLES
    var images: [UIImage]!
    var pin: Pin!
    var stack: CoreDataStack!
    var context: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController!
    var thereAreSavedImages: Bool!
    
    
// OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // assign the context
        stack = appDelegate.stack
        context = stack.context
        images = [UIImage]()
        
        // set the layout of the collection view
        setFlowLayout()
    }

    
    // Save the context when going back to the MapViewController
    override func viewWillDisappear(animated: Bool) {
        print("IMAGES on view disappearing: \(images.count)")
        do {
            try stack?.saveContext()
            print("Context saved")
        } catch {
            print("Error while saving")
        }
        images.removeAll()
    }
    
    override func viewWillAppear(animated: Bool) {
        images.removeAll()
        FlickrClient.sharedInstance().URLList.removeAll()
        print("iamges on view appearing: \(FlickrClient.sharedInstance().URLList.count)")
        print("URLLIST on view appearing: \(FlickrClient.sharedInstance().URLList.count)")
        // Extract the pin's latitude and longitude and make them a double
        let latitude = Double(pin.latitude!)
        let longitude = Double(pin.longitude!)
        
        // Set the map region
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(center, span)
        
        map.setRegion(region, animated: false)
        
        // Add an annotation to the map
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        // Initialize the fetched results controller
        initializeFetchedResultsController()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching...")
        }
        
        if fetchedResultsController.fetchedObjects!.count == 0 {
            requestImagesFromFlickr(latitude: latitude, longitude: longitude)
            self.thereAreSavedImages = false
        } else {
            let imageObjects = fetchedResultsController.fetchedObjects as! [Image]
            print("Fetched: \(imageObjects.count)")
            for image in imageObjects {
                images.append(UIImage(data: image.image!)!)
            }
            self.thereAreSavedImages = true
        }
    }
    
    
    
// HELPER FUNCTIONS
    func initializeFetchedResultsController() {
        let request = NSFetchRequest(entityName: "Image")
        request.predicate = NSPredicate(format: "pin = %@", self.pin)
        let idSort = NSSortDescriptor(key: "id", ascending: true)
        request.sortDescriptors = [idSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
    }
    
    func requestImagesFromFlickr(latitude latitude: Double, longitude: Double) {
        print("Request from Flickr")
        let location = ["lat": Double(pin.latitude!), "lon": Double(pin.longitude!)]
        FlickrClient.sharedInstance().getImages(location) { success, error in
            if success {
                self.performUIUpdatesOnMain {
                    print("SUCCESS")
                    self.collectionView.reloadData()
                }
                
            } else {
                print("error")
            }
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if thereAreSavedImages == true {
            print("Images count: \(images.count)")
            return images.count
        }
        print("URLList count: \(FlickrClient.sharedInstance().URLList.count)")
        return FlickrClient.sharedInstance().URLList.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! LocationImageViewCell
        if cell.imageViewCell.image != nil {
            cell.imageViewCell.image = nil
        }
        
        cell.activityView.hidesWhenStopped = true
        cell.activityView.activityIndicatorViewStyle = .WhiteLarge
        cell.activityView.startAnimating()
        
        if thereAreSavedImages == false {
            FlickrClient.sharedInstance().taskForGETImage(FlickrClient.sharedInstance().URLList[indexPath.row]) { imageData, error in
                
                if let image = imageData {
                    let _ = Image(image: image, pin: self.pin, id: indexPath.row, context: self.context)
                    self.images.append(UIImage(data: image)!)
                    self.performUIUpdatesOnMain {
                        cell.imageViewCell.image = self.images.last
                        cell.activityView.stopAnimating()
                    }
                }
            }
        } else {
            cell.imageViewCell.image = self.images[indexPath.row]
            cell.activityView.stopAnimating()
        }

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
