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
       
       let fetched = fetchedResultsController
        fetched.delegate = self
        try! fetched.performFetch()
        
        photos = fetched.fetchedObjects as? [Photo]
        if photos?.count != 0 {
            loadFromDisk = true
            print(photos?.count)
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
        FlickrClient.sharedInstance().getFlickrPhotoAlbum(pin!) {(photosArray, errorString) in
            
            if photosArray != nil {
                for photoArray in photosArray!{
                    let id = photoArray["id"] as? String
                    let title = photoArray["title"] as? String
                    var image:UIImage?
                    var imagePath:NSURL?
                    let imageURL = NSURL(string: photoArray["url_m"] as! String)
                    
                    if let imageData = NSData(contentsOfURL: imageURL!) {
                        performUIUpdatesOnMain {
                            
                            image = UIImage(data: imageData)
                            let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
                            
                            imagePath = documentsPath!.URLByAppendingPathComponent("\(id!).jpg")
                           // self.testImage.image = image
                            UIImageJPEGRepresentation(image!, 1.0)!.writeToFile(imagePath!.path!, atomically: true)
                            
                            let photo = Photo(id: id!, title: title!, imagePath: imagePath!.path!, context: self.sharedContext)
                            //  print(photo.imagePath)
                            
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
                print("finished request")
                self.photos = self.pin?.photos
            }
        }
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
        
        let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let imagePath = documentsPath!.URLByAppendingPathComponent("\(photo.id!).jpg")
        
        if let image = UIImage(contentsOfFile: imagePath.path!){
            cell.imageView.image = image
        }else{
            print("getImage() [Warning: file exists at \(imagePath) :: Unable to create image]")
        }
        
        return cell
    }
}



