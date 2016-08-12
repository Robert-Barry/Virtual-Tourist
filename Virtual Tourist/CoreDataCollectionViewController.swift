//
//  CoreDataCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Robert Barry on 8/11/16.
//  Copyright © 2016 Robert Barry. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class CoreDataCollectionViewController: UICollectionViewController {

    var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
    init(fetchedResultsController fc : NSFetchedResultsController, layout: UICollectionViewFlowLayout) {
        fetchedResultsController = fc
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UICollectionViewDataSource





    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}


// MARK:  - Collection Data Source
extension CoreDataCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let fc = fetchedResultsController{
            return fc.sections![section].numberOfObjects;
        }else{
            return 0
        }
    }
}



// MARK:  - Fetches
extension CoreDataCollectionViewController {
    
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
extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
}


