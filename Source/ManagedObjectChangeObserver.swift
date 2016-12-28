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
    private lazy var observedTypeFilter: (NSManagedObject) -> Bool = {(object) -> Bool in return object.isKind(of: self.observedType!)}

    private var onObjectsChange: ((_ updatedObjects:  Set<NSManagedObject>, _ deletedObjects: Set<NSManagedObject>) -> ())?
    private var onSetChange:     ((_ insertedObjects: Set<NSManagedObject>, _ removedObjects: Set<NSManagedObject>, _ updatedObjects: Set<NSManagedObject>) -> ())?
    private var onTypeChange:    ((_ insertedObjects: Set<NSManagedObject>, _ deletedObjects: Set<NSManagedObject>) -> ())?

    public init() {
    }

    deinit {
        removeObserver()
    }

    public func observe(managedObjects: [NSManagedObject], onChange: @escaping (_ changedObjects: Set<NSManagedObject>, _ deletedObjects: Set<NSManagedObject>) -> ()) {
        reset()
        observedObjects = Set(managedObjects)
        self.onObjectsChange = onChange
        observe()
    }

    public func observe(managedObject: NSManagedObject, onChange: @escaping (_ changedObjects: Set<NSManagedObject>, _ deletedObjects: Set<NSManagedObject>) -> ()) {
        observe(managedObjects: [managedObject], onChange: onChange)
    }

    public func observe(set: NSSet, onChange: @escaping (_ insertedObjects: Set<NSManagedObject>, _ removedObjects: Set<NSManagedObject>, _ changedObjects: Set<NSManagedObject>) -> ()) {
        reset()
        observedNSSet = set
        self.onSetChange = onChange
        observe()
    }

    public func observe<T: NSManagedObject>(type: T.Type, onChange: @escaping ((_ insertedObjects: Set<T>, _ deletedObjects: Set<T>) -> ())) {
        reset()
        observedType = type
        self.onTypeChange = { insertedObjects, deletedObjects in
            onChange(insertedObjects as! Set<T>, deletedObjects as! Set<T>)
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
        NotificationCenter.default.addObserver(self, selector: #selector(ManagedObjectChangeObserver.didChangeManagedObjectContext(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: CoreDataStack.sharedInstance.currentContext())
    }

    public func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didChangeManagedObjectContext(_ notification: Notification) {
        let updatedObjects = {(notification.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}
        let deletedObjects = {(notification.userInfo?[NSDeletedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}
        let insertedObjects = {(notification.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects as? [NSManagedObject] ?? []}

        // Detect if observed objects got changed or deleted
        if let observedObjects = self.observedObjects, let onChange = self.onObjectsChange {
            let updatedObjects = observedObjects.intersection(updatedObjects())
            let deletedObjects = observedObjects.intersection(deletedObjects())
            if updatedObjects.count + deletedObjects.count > 0 {
                onChange(updatedObjects, deletedObjects)
            }
        }
        // Detect if observed set got changed
        else if let observedSet = self.observedSet, let observedSetCopy = self.observedSetCopy, let onChange = self.onSetChange {
            let insertedObjects = observedSet.subtracting(observedSetCopy)
            let removedObjects = observedSetCopy.subtracting(observedSet)
            let updatedObjects = Set(observedSet.filter { updatedObjects().contains($0) })
            if insertedObjects.count + removedObjects.count + updatedObjects.count > 0 {
                onChange(insertedObjects, removedObjects, updatedObjects)
            }
            // Remember current state of set in order to detect future changes
            self.observedSetCopy = observedSet
        }
        // Detect if objects of observed type got inserted or deleted
        else if let _ = self.observedType, let onChange = self.onTypeChange {
            let insertedObjects = Set(insertedObjects().filter(observedTypeFilter))
            let deletedObjects = Set(deletedObjects().filter(observedTypeFilter))
            if insertedObjects.count + deletedObjects.count > 0 {
                onChange(insertedObjects, deletedObjects)
            }
        }
    }
}
