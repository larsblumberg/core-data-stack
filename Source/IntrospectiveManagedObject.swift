//
//  IntrospectiveManagedObject.swift
//  Pods
//
//  Created by Lars Blumberg on 1/22/16.
//
//

import CoreData

/**
    NSManagedObject that allows for introspection:
    - Provides a `observeProperty(property: String, handler: () -> ())` that is invoked when a given property changes. Can be called in `didAwake()`.
    - If a property is already being observed, the previous observer is being overriden
    - Call `removePropertyObserver(property: String)` to stop observing.
    - Automatically removes property observers when the managed object turns into a fault
*/
open class IntrospectiveManagedObject : NSManagedObject {
    typealias PropertyClosure = (_ oldValue: NSObject?, _ newValue: NSObject?) -> ()
    fileprivate var observedProperties = [String : PropertyClosure]()

    open override func awakeFromInsert() {
        super.awakeFromInsert()
        didAwake()
    }

    open override func awakeFromFetch() {
        super.awakeFromFetch()
        didAwake()
    }

    open override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        didAwake()
    }

    /// Automatically called by `awakeFromInsert()`, `awakeFromFetch()` or `awakeFromSnapshotEvents(flags)`. Good place for calls to `observeProperty(property)`
    open func didAwake() {
        // Can be overriden by subclasses to make calls to observeProperty
    }

    open override func willTurnIntoFault() {
        observedProperties.keys.forEach { removePropertyObserver($0) }
        observedProperties = [:]
        super.willTurnIntoFault()
    }

    public func observeProperty(_ property: String, handler: @escaping (_ oldValue: NSObject?, _ newValue: NSObject?) -> ()) {
        removePropertyObserver(property)
        observedProperties[property] = handler
        addObserver(self, forKeyPath: property, options: [.old, .new], context: &observerContext)
    }

    public func removePropertyObserver(_ property: String) {
        guard observedProperties.keys.contains(property) else { return }
        observedProperties.removeValue(forKey: property)
        removeObserver(self, forKeyPath: property)
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard
            let property = keyPath,
            let handler = observedProperties[property]
        else {
            return
        }
        handler(change?[NSKeyValueChangeKey.oldKey] as? NSObject, change?[NSKeyValueChangeKey.newKey] as? NSObject)
    }
}

private var observerContext = 0
