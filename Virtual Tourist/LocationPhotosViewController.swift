//
//  LocationPhotosViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 6/23/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import MapKit

class LocationPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var images: [UIImage]!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "87dd9e70930748bb40e780e47c10a40f"
    let SAFE_SEARCH = "1"
    let EXTRAS = "url_m"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    var latitude: Double?
    var longitude: Double?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let center = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(center, span)
        
        map.setRegion(region, animated: false)
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
        let location = ["lat": 40.4406, "lon": 79.9959]
        
        setFlowLayout()
        
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
        
        let space: CGFloat = 3.0
        let dimension: CGFloat!
        
        if view.frame.size.width > view.frame.size.height {
            dimension = self.view.frame.size.height / 3.0
        } else {
            dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        }
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
