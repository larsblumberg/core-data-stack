//
//  CoreDataStack+ChangeNotification.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 8/27/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import CoreData

public extension CoreDataStack {
    func postChangeNotification(managedObject managedObject: NSManagedObject) {
        postChangeNotification(managedObjects: [managedObject])
    }
    
    func postChangeNotification(managedObjects managedObjects: [NSManagedObject]) {
        NSNotificationCenter.defaultCenter().postNotificationName(NSManagedObjectContextObjectsDidChangeNotification, object: currentContext(), userInfo: [NSUpdatedObjectsKey: Set(managedObjects) as NSSet])
    }
}
