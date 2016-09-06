//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/23/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var longPressGesture:UILongPressGestureRecognizer?
    var pins:[Pin]!
    var region:MKCoordinateRegion?
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self

        navigationController?.setToolbarHidden(true, animated: false)
        
        addLongPressGesture()
        loadMapRegion()
        
        pins = fetchAnnotation()
        print(pins.count)
        self.mapView.addAnnotations(pins)
        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addLongPressGesture(){
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapView.addAnnotation(_:)))
        longPressGesture?.minimumPressDuration = 2.0
        
        mapView.addGestureRecognizer(longPressGesture!)
    }
    
    // MARK: Save/Load Annotations
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            

            let longitude = coordinates.longitude as Double
            let latitude = coordinates.latitude as Double

            let pin = Pin(longitude:longitude , latitude: latitude, context: sharedContext)
            mapView.addAnnotation(pin)

            pins.append(pin)
            do {
                try self.sharedContext.save()
                
                print("pin saved")
            } catch {
                print("save to core data failed")
            }
        }
    }
    
    func fetchAnnotation() -> [Pin]{
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch  let error as NSError {
            print("Error in fetchAllEvents(): \(error)")
            return [Pin]()
        }
    }
    
    // MARK: Save/Load Map Region
    var mapRegionFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        return (url?.URLByAppendingPathComponent("mapRegion").path)!
    }
    
    func saveMapRegion(){
        
        let mapRegionDictionary =
            ["longitude" : mapView.region.center.longitude,
             "latitude" : mapView.region.center.latitude,
             "longitudeDelta"   : mapView.region.span.longitudeDelta,
             "latitudeDelta"   : mapView.region.span.latitudeDelta]
        
        NSKeyedArchiver.archiveRootObject(mapRegionDictionary, toFile: mapRegionFilePath)
    }
    
    func loadMapRegion(){
        if let mapRegionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String : AnyObject]{
            let longitude = mapRegionDictionary["longitude"] as! CLLocationDegrees
            let longitudeDelta = mapRegionDictionary["longitudeDelta"] as! CLLocationDegrees
            let latitude = mapRegionDictionary["latitude"] as! CLLocationDegrees
            let latitudeDelta = mapRegionDictionary["latitudeDelta"] as! CLLocationDegrees
            
            let center = CLLocationCoordinate2DMake(latitude, longitude)
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            
            self.region = MKCoordinateRegionMake(center, span)
            mapView.setRegion(region!, animated: true)
            print("map region loaded")

        } else{
            print("did not find existing map region")
        }
    }
    
    // MARK: MKMapView Delegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: false)
        performSegueWithIdentifier("PhotoAlbum", sender: view.annotation)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "PhotoAlbum"){
            
            let photoAlbumController = segue.destinationViewController as! PhotoAlbumViewController

            photoAlbumController.pin = sender as? Pin
        }
    }
}


