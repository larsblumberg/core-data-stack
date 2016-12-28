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
    public static var entityName: String { return (NSStringFromClass(self) as NSString).pathExtension }
    
    private static var currentContext: NSManagedObjectContext! { return CoreDataStack.sharedInstance.currentContext() }
    
    public static func newManagedObject() -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: currentContext)
    }
    
    public static func allObjects() -> [NSManagedObject]! {
        return currentContext.fetchAllObjects(forEntityName: entityName)
    }
    
    public static func allObjectsWithPredicate(_ predicate: NSPredicate) -> [NSManagedObject]! {
        return CoreDataStack.sharedInstance.currentContext().fetchAllObjects(forEntityName: entityName, predicate: predicate)
    }
    
    public static func objectWithPredicate(_ predicate: NSPredicate) -> NSManagedObject? {
        return allObjectsWithPredicate(predicate).first
    }
    
    public static func objectWithID(_ objectID: NSManagedObjectID) -> NSManagedObject? {
        return try? currentContext.existingObject(with: objectID)
    }
    
    public static func objectWithURL(_ objectURL: URL) -> NSManagedObject? {
        if let objectID = CoreDataStack.sharedInstance.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectURL) {
            return objectWithID(objectID)
        } else {
            return nil
        }
    }
    
    public static func objectWithURLString(_ objectURLString: String) -> NSManagedObject? {
        if let objectURL = URL(string: objectURLString) {
            return objectWithURL(objectURL)
        }
        else {
            return nil
        }
    }
    
    public func delete() {
        CoreDataStack.sharedInstance.currentContext().delete(self)
    }
}
