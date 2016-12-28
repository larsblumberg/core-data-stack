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
    public func fetchAllObjects(forEntityName entityName: String, predicate: NSPredicate? = nil) -> [NSManagedObject]! {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        return try! self.fetch(fetchRequest) as! [NSManagedObject]
    }
}
