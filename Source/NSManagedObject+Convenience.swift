//
//  NSManagedObject+Convenience.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 13/08/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObject {
    public static func entityName() -> String {
        let className: NSString = NSStringFromClass(self)
        return className.pathExtension
    }
    
    private static var currentContext: NSManagedObjectContext! {
        get {
            return CoreDataStack.sharedInstance.currentContext()
        }
    }
    
    public static func newManagedObject() -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: currentContext)
    }
    
    public static func allObjects() -> [NSManagedObject]! {
        return currentContext.fetchAllObjectsForEntityName(entityName())
    }
    
    public static func allObjectsWithPredicate(predicate: NSPredicate) -> [NSManagedObject]! {
        return CoreDataStack.sharedInstance.currentContext().fetchAllObjectsForEntityName(entityName(), predicate: predicate)
    }
    
    public static func objectWithPredicate(predicate: NSPredicate) -> NSManagedObject? {
        return allObjectsWithPredicate(predicate).first
    }
    
    public static func objectWithObjectID(objectID: NSManagedObjectID) -> NSManagedObject? {
        return try? currentContext.existingObjectWithID(objectID)
    }
    
    public static func objectWithObjectID(objectIDURL objectIDURL: NSURL) -> NSManagedObject? {
        if let objectID = CoreDataStack.sharedInstance.persistentStoreCoordinator.managedObjectIDForURIRepresentation(objectIDURL) {
            return objectWithObjectID(objectID)
        } else {
            return nil
        }
    }
    
    public static func objectWithObjectID(objectIDURLString objectIDURLString: String) -> NSManagedObject? {
        if let objectIDURL = NSURL(string: objectIDURLString) {
            return objectWithObjectID(objectIDURL: objectIDURL)
        } else {
            return nil
        }
    }
    
    public func delete() {
        CoreDataStack.sharedInstance.currentContext().deleteObject(self)
    }
}
