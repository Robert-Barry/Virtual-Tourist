//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 5/25/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    var num: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        map.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("region changed \(num)")
        num = num + 1
    }
}

