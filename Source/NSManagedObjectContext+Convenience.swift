//
//  NSManagedObjectContext+Convenience.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 13/08/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectContext {
    public func fetchAllObjectsForEntityName(entityName: String!) -> [NSManagedObject]! {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        return try! self.executeFetchRequest(fetchRequest) as! [NSManagedObject]
    }
    
    public func fetchAllObjectsForEntityName(entityName: String!, predicate: NSPredicate!) -> [NSManagedObject]! {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        return try! self.executeFetchRequest(fetchRequest) as! [NSManagedObject]
    }
}
