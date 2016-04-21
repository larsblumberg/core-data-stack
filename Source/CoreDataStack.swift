//
//  CoreDataStack.swift
//  CoreDataStack
//
//  Created by Lars Blumberg on 13/08/15.
//  Copyright © 2015 Lars Blumberg. All rights reserved.
//

import Foundation
import CoreData

//TODO: Opensource, create CocoaPod "CoreDataStackSwift"
public class CoreDataStack {
    public static var modelName: String?

    public static let sharedInstance: CoreDataStack = {
        guard let modelName = modelName else { fatalError("CoreDataStack.modelName not set") }
        return CoreDataStack(modelName: modelName)
    }()

    private let modelName: String

    public lazy var managedObjectContext: NSManagedObjectContext! = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()

    public lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator! = {
        // Enable for lightweight model migration
        var options = [String: AnyObject]()
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // TODO: Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    private lazy var storeURL: NSURL = self.applicationDocumentsDirectory().URLByAppendingPathComponent(self.modelName + ".sqlite")

    private init(modelName: String) {
        self.modelName = modelName
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "managedObjectContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }

    private func applicationDocumentsDirectory() -> NSURL! {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }

    //MARK: Support for managed object context access from different threads

    func currentContext() -> NSManagedObjectContext! {
        if NSThread.isMainThread() {
            return self.managedObjectContext
        }
        // Retrieve or create new context for current thread
        let currentThread = NSThread.currentThread()
        var context = currentThread.threadDictionary["CoreDataStack"] as? NSManagedObjectContext
        if (context == nil) {
            if let coordinator = self.persistentStoreCoordinator {
                context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                context!.persistentStoreCoordinator = coordinator
                currentThread.threadDictionary["CoreDataStack"] = context
            }
        }
        return context
    }

    public func saveCurrentContext() {
        saveContext(currentContext())
    }

    internal func saveContext(context: NSManagedObjectContext!) {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch let error as NSError {
            //TODO: Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error.userInfo)")
            abort();
        }
    }

    // Merging other object contexts into the main context
    @objc private func managedObjectContextDidSaveNotification(notification: NSNotification!) {
        guard let notificationManagedObjectContext = notification.object as? NSManagedObjectContext else { return }

        // No need to merge the main context into itself
        guard notificationManagedObjectContext != self.managedObjectContext else { return }

        // No need to merge a context from other store coordinators than ours
        guard notificationManagedObjectContext.persistentStoreCoordinator == self.persistentStoreCoordinator else { return }

        // Make sure to perform the merge operation on the main thread
        if (!NSThread.isMainThread()) {
            dispatch_async(dispatch_get_main_queue()) {
                self.managedObjectContextDidSaveNotification(notification)
            }
            return;
        }

        // Merge thread-related context into the main context
        self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
    }

    public func resetDatabase() throws {
        //TODO: If the persistentStoreCoordinator had been already created, it must also be reset
        let path = storeURL.path!
        guard NSFileManager.defaultManager().fileExistsAtPath(path) else { return }
        try NSFileManager.defaultManager().removeItemAtURL(storeURL)
        try NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
    }
}
