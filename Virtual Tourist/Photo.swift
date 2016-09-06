//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Steven Chen on 5/25/16.
//  Copyright © 2016 Steven Chen. All rights reserved.
//

import UIKit
import CoreData
import MapKit



class Photo: NSManagedObject{

    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin:Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(id:String, title:String, imagePath:String, context:NSManagedObjectContext){
        if let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context){
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.id = id
            self.title = title
            self.imagePath = imagePath
            
        }else{
            fatalError("Unable to find Entity name!")
        }
    }
}