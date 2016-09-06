//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/23/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import UIKit
import CoreData
import MapKit

//@objc(Pin)

class Pin: NSManagedObject, MKAnnotation{
    
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var photos: [Photo]
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(longitude:Double, latitude:Double, context:NSManagedObjectContext){
        if let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context){
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.longitude = longitude
            self.latitude = latitude
            
        }else{
            fatalError("Unable to find Entity name!")
        }
    }
}
