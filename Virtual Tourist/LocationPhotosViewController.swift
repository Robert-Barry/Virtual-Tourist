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

class LocationPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
// OUTLETS
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
// CONSTANTS
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
// VARIABLES
    var images: [UIImage]!
    var pin: Pin!
    var stack: CoreDataStack!
    var context: NSManagedObjectContext!

    
    
// OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // assign the context
        stack = appDelegate.stack
        context = stack.context
        
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
        
        let location = ["lat": latitude, "lon": longitude]
        
        // Check if images alread exist. If so, use the pre-existing images.
        // Otherwise, load from Flickr.
        if pin.images?.count == 0 {
            print("No previous images. Loading from Flickr")
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
        } else {
            //images = pin.convertToImageArray()
        }
    
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(FlickrClient.sharedInstance().URLList.count)
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
        
        FlickrClient.sharedInstance().taskForGETImage(FlickrClient.sharedInstance().URLList[indexPath.row]) { imageData, error in
            
            if let image = imageData {
                let _ = Image(image: image, pin: self.pin, context: self.context)
                self.performUIUpdatesOnMain {
                    cell.imageViewCell.image = UIImage(data: image)
                    cell.activityView.stopAnimating()
                }
            }
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
