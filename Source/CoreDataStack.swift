//
//  CoreDataStack.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 13/08/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataStack {
    public static var modelName: String?
    #if os(tvOS)
    public static var storeType: String = NSInMemoryStoreType
    #else
    public static var storeType: String = NSSQLiteStoreType
    #endif
    public static var storeDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!

    public static let shared: CoreDataStack = {
        guard let modelName = modelName else { fatalError("CoreDataStack.modelName not set") }
        return CoreDataStack(modelName: modelName, storeType: storeType, storeDirectoryURL: storeDirectoryURL)
    }()

    public weak var delegate: CoreDataStackDelegate?

    private let modelName: String
    private let storeType: String
    private let storeDirectoryURL: URL

    public lazy var managedObjectContext: NSManagedObjectContext! = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()

    public lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator! = {
        // Enable for lightweight model migration
        var options = [String: AnyObject]()
        options[NSMigratePersistentStoresAutomaticallyOption] = true as AnyObject?
        options[NSInferMappingModelAutomaticallyOption] = true as AnyObject?

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try FileManager.default.createDirectory(at: self.storeURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: self.storeURL as URL, options: options)
        }
        catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // TODO: Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    private lazy var storeURL: URL = self.storeDirectoryURL.appendingPathComponent(self.modelName + ".sqlite")

    private init(modelName: String, storeType: String, storeDirectoryURL: URL) {
        self.modelName = modelName
        self.storeType = storeType
        self.storeDirectoryURL = storeDirectoryURL
        NotificationCenter.default.addObserver(self, selector: #selector(self.managedObjectContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeManagedObjectContext(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }

    //MARK: Support for managed object context access from different threads

    func currentContext() -> NSManagedObjectContext! {
        if Thread.isMainThread {
            return self.managedObjectContext
        }
        // Retrieve or create new context for current thread
        let currentThread = Thread.current
        var context = currentThread.threadDictionary["CoreDataStack"] as? NSManagedObjectContext
        if (context == nil) {
            if let coordinator = self.persistentStoreCoordinator {
                context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                context!.persistentStoreCoordinator = coordinator
                currentThread.threadDictionary["CoreDataStack"] = context
            }
        }
        return context
    }

    public func saveCurrentContext() {
        saveContext(currentContext())
    }

    internal func saveContext(_ context: NSManagedObjectContext!) {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch let error as NSError {
            //TODO: Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error.userInfo)")
            delegate?.coreDataStack(self, didFailSaveWithError: error)
        }
    }

    // Merging other object contexts into the main context
    @objc private func managedObjectContextDidSaveNotification(_ notification: Notification!) {
        guard let notificationManagedObjectContext = notification.object as? NSManagedObjectContext else { return }

        // No need to merge the main context into itself
        guard notificationManagedObjectContext != self.managedObjectContext else { return }

        // No need to merge a context from other store coordinators than ours
        guard notificationManagedObjectContext.persistentStoreCoordinator == self.persistentStoreCoordinator else { return }

        // Make sure to perform the merge operation on the main thread
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.managedObjectContextDidSaveNotification(notification)
            }
            return;
        }

        // Merge thread-related context into the main context
        self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
    }

    @objc private func didChangeManagedObjectContext(_ notification: Notification) {
        self.delegate?.coreDataStackDidChangeManagedObjectContext(self)
    }

    public func resetDatabase() throws {
        //TODO: If the persistentStoreCoordinator had been already created, it must also be reset
        let path = storeURL.path
        guard FileManager.default.fileExists(atPath: path) else { return }
        try FileManager.default.removeItem(at: storeURL as URL)
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }
}

public protocol CoreDataStackDelegate: class {
    func coreDataStack(_ stack: CoreDataStack, didFailSaveWithError error: NSError)
    func coreDataStackDidChangeManagedObjectContext(_ stack: CoreDataStack)
}

public extension CoreDataStackDelegate {
    func coreDataStackDidChangeManagedObjectContext(_stack: CoreDataStack) {}
}
