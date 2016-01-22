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
public class IntrospectiveManagedObject : NSManagedObject {
    typealias PropertyClosure = () -> ()
    private var observedProperties = [String : PropertyClosure]()

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        didAwake()
    }

    public override func awakeFromFetch() {
        super.awakeFromFetch()
        didAwake()
    }

    public override func awakeFromSnapshotEvents(flags: NSSnapshotEventType) {
        super.awakeFromSnapshotEvents(flags)
        didAwake()
    }

    /// Automatically called by `awakeFromInsert()`, `awakeFromFetch()` or `awakeFromSnapshotEvents(flags)`. Good place for calls to `observeProperty(property)`
    public func didAwake() {
        // Can be overriden by subclasses to make calls to observeProperty
    }

    public override func willTurnIntoFault() {
        observedProperties.forEach { removePropertyObserver($0.0) }
        observedProperties = [:]
        super.willTurnIntoFault()
    }

    public func observeProperty(property: String, handler: () -> ()) {
        removePropertyObserver(property)
        observedProperties[property] = handler
        addObserver(self, forKeyPath: property, options: [.Old, .New], context: &observerContext)
    }

    public func removePropertyObserver(property: String) {
        guard observedProperties.keys.contains(property) else { return }
        observedProperties.removeValueForKey(property)
        removeObserver(self, forKeyPath: property)
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &observerContext else { return }
        guard let
            property = keyPath,
            closure = observedProperties[property] else { return }
        closure()
    }
}

private var observerContext = 0
