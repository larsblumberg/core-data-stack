//
//  ManagedObjectChangeObserver.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 8/27/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import CoreData

public class ManagedObjectChangeObserver {
    private var observedObjects: Set<NSManagedObject>?
    private var observedNSSet: NSSet? { didSet { observedSetCopy = self.observedNSSet as? Set<NSManagedObject> } }
    private var observedSet: Set<NSManagedObject>? { get {
        if let array = self.observedNSSet?.allObjects as? [NSManagedObject] {
            return Set(array)
        } else {
            return nil
        } } }
    private var observedSetCopy: Set<NSManagedObject>?
    private var observedType: NSManagedObject.Type?
    private lazy var observedTypeFilter: (NSManagedObject) -> Bool = {(object) -> Bool in return object.isKindOfClass(self.observedType!)}

    private var onObjectsChange: ((updatedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>) -> ())?
    private var onSetChange: ((insertedObjects: Set<NSManagedObject>, removedObjects: Set<NSManagedObject>) -> ())?
    private var onTypeChange: ((insertedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>) -> ())?

    public init() {
    }

    deinit {
        removeObserver()
    }

    public func observe(managedObjects managedObjects: [NSManagedObject], onChange: (changedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>) -> ()) {
        reset()
        observedObjects = Set(managedObjects)
        self.onObjectsChange = onChange
        observe()
    }

    public func observe(managedObject managedObject: NSManagedObject, onChange: (changedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>) -> ()) {
        observe(managedObjects: [managedObject], onChange: onChange)
    }

    public func observe(set set: NSSet, onChange: (insertedObjects: Set<NSManagedObject>, removedObjects: Set<NSManagedObject>) -> ()) {
        reset()
        observedNSSet = set
        self.onSetChange = onChange
        observe()
    }

    public func observe<T: NSManagedObject>(type type: T.Type, onChange: ((insertedObjects: Set<T>, deletedObjects: Set<T>) -> ())) {
        reset()
        observedType = type
        self.onTypeChange = { insertedObjects, deletedObjects in
            onChange(insertedObjects: insertedObjects as! Set<T>, deletedObjects: deletedObjects as! Set<T>)
        }
        observe()
    }

    private func reset() {
        observedObjects = nil
        observedNSSet = nil
        observedSetCopy = nil
        observedType = nil
        onObjectsChange = nil
        onSetChange = nil
        onTypeChange = nil
        removeObserver()
    }

    private func observe() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeManagedObjectContext:", name: NSManagedObjectContextObjectsDidChangeNotification, object: CoreDataStack.sharedInstance.currentContext())
    }

    public func removeObserver() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc private func didChangeManagedObjectContext(notification: NSNotification) {
        let updatedObjects = {(notification.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}
        let deletedObjects = {(notification.userInfo?[NSDeletedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}
        let insertedObjects = {(notification.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}

        // Detect if observed objects got changed or deleted
        if let observedObjects = self.observedObjects, onChange = self.onObjectsChange {
            let updatedObjects = observedObjects.intersect(updatedObjects())
            let deletedObjects = observedObjects.intersect(deletedObjects())
            if updatedObjects.count > 0 || deletedObjects.count > 0 {
                onChange(updatedObjects: updatedObjects, deletedObjects: deletedObjects)
            }
        }
        // Detect if observed set got changed
        else if let observedSet = self.observedSet, observedSetCopy = self.observedSetCopy, onChange = self.onSetChange {
            let insertedObjects = observedSet.subtract(observedSetCopy)
            let removedObjects = observedSetCopy.subtract(observedSet)
            if insertedObjects.count > 0 || removedObjects.count > 0 {
                onChange(insertedObjects: insertedObjects, removedObjects: removedObjects)
            }
            // Remember current state of set in order to detect future changes
            self.observedSetCopy = observedSet
        }
        // Detect if objects of observed type got inserted or deleted
        else if let _ = self.observedType, onChange = self.onTypeChange {
            let insertedObjects = Set(insertedObjects().filter(observedTypeFilter))
            let deletedObjects = Set(deletedObjects().filter(observedTypeFilter))
            if insertedObjects.count > 0 || deletedObjects.count > 0 {
                onChange(insertedObjects: insertedObjects, deletedObjects: deletedObjects)
            }
        }
    }
}
