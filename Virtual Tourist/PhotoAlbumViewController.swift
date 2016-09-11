//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/24/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate{
    
    var pin:Pin?
    var photos:[Photo]?
    var loadFromDisk:Bool?
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        collectionViewLayOut()
        mapViewSetUp()
       print(pin?.latitude, pin?.longitude)
       let fetched = fetchedResultsController
        fetched.delegate = self
        try! fetched.performFetch()
        
        photos = fetched.fetchedObjects as? [Photo]
        if photos?.count != 0 {
            loadFromDisk = true
        } else {
            flickrRequest()
            loadFromDisk = false
        }
    }
    
    func mapViewSetUp(){
        if pin != nil{
            mapView.addAnnotation(pin!)
            
            let center = CLLocationCoordinate2D(latitude: pin!.coordinate.latitude, longitude: pin!.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01,longitudeDelta: 0.01))
            
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    func collectionViewLayOut(){

        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2*space))/3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    // Mark: Flickr
    func flickrRequest(){
        print(photos?.count)

        FlickrClient.sharedInstance().getFlickrPhotoAlbum(self.pin!, page: 1) {(photosArray, maxPages, errorString) in
            if maxPages != 0{
                FlickrClient.sharedInstance().getFlickrPhotoAlbum(self.pin!, page:UInt32(maxPages!)) {(photosArray, maxPages, errorString) in
                
                    if photosArray != nil {
                        for photoArray in photosArray!{
                            let id = photoArray["id"] as? String
                            let title = photoArray["title"] as? String
                            let imageURL = NSURL(string: photoArray["url_m"] as! String)
                            
                            if let imageData = NSData(contentsOfURL: imageURL!) {
                                performUIUpdatesOnMain {
                                    
                                    let photo = Photo(id: id!, title: title!, image: imageData, context: self.sharedContext)

                                    photo.pin = self.pin
                                    self.photos?.append(photo)

                                    self.collectionView.reloadData()
                                    
                                    do {
                                        try self.sharedContext.save()
                                    } catch {
                                        print("save to core data failed")
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
        self.photos = self.pin?.photos
    }
    
    // Mark: Fetch Results
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    // MARK: Collection View Delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       // print(pin?.photos[0].imagePath)
        
        return (pin?.photos.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! photoCollectionViewCell
        
        let photo = photos![indexPath.row]
 
        if let image = UIImage(data: photo.image!){
            cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
            cell.imageView.image = image
        }else{
            print(" Unable to create image]")
        }
        return cell
    }
    
    // MARK: Buttons
    @IBAction func newCollectionButton(sender: AnyObject) {
        deleteData()
        flickrRequest()
    }
    
    func deleteData(){
        for photo in photos! {
            sharedContext.deleteObject(photo)
            
            do {
                try self.sharedContext.save()
            } catch {
                print("save to core data failed")
            }
        }
    }
}



