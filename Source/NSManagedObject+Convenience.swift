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

    private static var currentContext: NSManagedObjectContext! { return CoreDataStack.shared.currentContext() }

    public static func newManagedObject() -> Self {
        return autocast(NSEntityDescription.insertNewObject(forEntityName: entityName, into: currentContext))
    }

    public static func allObjects<T: NSManagedObject>() -> [T] {
        return currentContext.fetchAllObjects(forEntityName: entityName) as! [T]
    }

    public static func allObjectsWithPredicate<T: NSManagedObject>(_ predicate: NSPredicate) -> [T] {
        return CoreDataStack.shared.currentContext().fetchAllObjects(forEntityName: entityName, predicate: predicate) as! [T]
    }

    public static func objectWithPredicate(_ predicate: NSPredicate) -> Self? {
        return autocast(allObjectsWithPredicate(predicate).first)
    }

    public static func objectWithID(_ objectID: NSManagedObjectID) -> Self? {
        return autocast(try? currentContext.existingObject(with: objectID))
    }

    public static func objectWithURL(_ objectURL: URL) -> Self? {
        if let objectID = CoreDataStack.shared.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectURL) {
            return objectWithID(objectID)
        } else {
            return nil
        }
    }

    public static func objectWithURLString(_ objectURLString: String) -> Self? {
        if let objectURL = URL(string: objectURLString) {
            return objectWithURL(objectURL)
        }
        else {
            return nil
        }
    }

    public func delete() {
        CoreDataStack.shared.currentContext().delete(self)
    }
}

private func autocast<T>(_ some: Any) -> T {
    return some as! T
}
