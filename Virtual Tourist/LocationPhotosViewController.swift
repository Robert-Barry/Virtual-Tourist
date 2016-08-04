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
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "87dd9e70930748bb40e780e47c10a40f"
    let SAFE_SEARCH = "1"
    let EXTRAS = "url_m"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var images: [UIImage]!
    var pin: Pin!
    var latitude: Double?
    var longitude: Double?
    var stack: CoreDataStack!
    var context: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        stack = appDelegate.stack
        context = stack.context
        
        setFlowLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        
        pin = Pin(latitude: latitude!, longitude: longitude!, context: context)
        
        let center = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(center, span)
        
        map.setRegion(region, animated: false)
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        let location = ["lat": latitude!, "lon": longitude!]
        
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
        print(FlickrClient.sharedInstance().URLList.count)
        return FlickrClient.sharedInstance().URLList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! LocationImageViewCell
        
        let data = NSData(contentsOfURL: FlickrClient.sharedInstance().URLList[indexPath.row])
        cell.imageViewCell.image = UIImage(data: data!)
        
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
