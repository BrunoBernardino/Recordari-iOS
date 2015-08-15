//
//  AppDelegate.swift
//  Recordari
//
//  Created by Bruno Bernardino on 21/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var settings: NSUserDefaults!
    
    var storeOptions: NSDictionary!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        self.synchronizeSettings()
        
        // Change the default tint color
        self.window!.tintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        
        // Listen for iCloud changes (when they will happen)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudWillUpdate:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: nil)
        
        // Listen for iCloud changes (after it's done)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudDidUpdate:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // Store options for iCloud
    func iCloudStoreOptions() -> NSDictionary {
        return [ NSPersistentStoreUbiquitousContentNameKey: "iCloudStore" ]
    }
    
    // Store options for local
    func localStoreOptions() -> NSDictionary {
        return [ NSPersistentStoreUbiquitousContentNameKey: "localStore" ]
    }
    
    // Get current store URL (it will change based on if iCloud is enabled or not)
    func currentStoreURL() -> NSURL {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent("Oikon.sqlite")
    }

    // iCloud will update
    func iCloudWillUpdate(sender: AnyObject) {
        self.setiCloudStartSyncDate()
    }
    
    // iCloud finished updating
    func iCloudDidUpdate(sender: AnyObject) {
        self.setiCloudEndSyncDate()
    }
    
    // MARK: - Core Data stack
    func observeCloudActions(persistentStoreCoordinator psc: NSPersistentStoreCoordinator?) {
        // iCloud notification subscriptions
        let nc = NSNotificationCenter.defaultCenter();
        nc.addObserver(
            self,
            selector: "storesWillChange:",
            name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
            object: psc);
        
        nc.addObserver(
            self,
            selector: "storesDidChange:",
            name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
            object: psc);
        
        nc.addObserver(
            self,
            selector: "persistentStoreDidImportUbiquitousContentChanges:",
            name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
            object: psc);
        
        nc.addObserver(
            self,
            selector: "mergeChanges:",
            name: NSManagedObjectContextDidSaveNotification,
            object: psc);
    }
    
    func mergeChanges(notification: NSNotification) {
        NSLog("mergeChanges notif:\(notification)")
        if let moc = managedObjectContext {
            moc.performBlock {
                moc.mergeChangesFromContextDidSaveNotification(notification)
                self.postRefetchDatabaseNotification()
            }
        }
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        self.mergeChanges(notification)
    }
    
    // Subscribe to NSPersistentStoreCoordinatorStoresWillChangeNotification
    // most likely to be called if the user enables / disables iCloud
    // (either globally, or just for your app) or if the user changes
    // iCloud accounts.
    func storesWillChange(notification: NSNotification) {
        NSLog("storesWillChange notif:\(notification)");
        if let moc = self.managedObjectContext {
            moc.performBlockAndWait {
                var error: NSError? = nil;
                if moc.hasChanges && !moc.save(&error) {
                    NSLog("Save error: \(error)");
                } else {
                    // drop any managed objects
                }
                
                // Reset context anyway, as suggested by Apple Support
                // The reason is that when storesWillChange notification occurs, Core Data is going to switch the stores. During and after that switch (happening in background), your currently fetched objects will become invalid.
                
                moc.reset();
            }
            
            // now reset your UI to be prepared for a totally different
            // set of data (eg, popToRootViewControllerAnimated:)
            // BUT don't load any new data yet.
        }
    }
    
    // Subscribe to NSPersistentStoreCoordinatorStoresDidChangeNotification
    func storesDidChange(notification: NSNotification) {
        // here is when you can refresh your UI and
        // load new data from the new store
        NSLog("storesDidChange posting notif");
        self.postRefetchDatabaseNotification();
    }
    
    func postRefetchDatabaseNotification() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(
                "kRefetchDatabaseNotification", // Replace with your constant of the refetch name, and add observer in the proper place - e.g. RootViewController
                object: nil);
        })
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "hyouuu.pendo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Recordari", withExtension: "momd")!
        NSLog("modelURL:\(modelURL)")
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Recordari.sqlite")
        NSLog("storeURL:\(url)")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(
            NSSQLiteStoreType,
            configuration: nil,
            URL: url,
            options: [NSPersistentStoreUbiquitousContentNameKey : "Recordari"],
            error: &error) == nil
        {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            //error = NSError(domain: "Pendo_Error_Domain", code: 9999, userInfo: dict as! [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("AddPersistentStore error \(error), \(error!.userInfo)")
        }
        
        self.observeCloudActions(persistentStoreCoordinator: coordinator)
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
            }
        }
    }
    
    // Set / Get default settings
    func synchronizeSettings() {
        NSLog( "## Starting settings synchronization ##" )
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
    
        // iCloud sync
        if (self.settings.objectForKey("iCloud") == nil) {
            var defaultiCloud: NSMutableDictionary = NSMutableDictionary(capacity: 5)
            
            defaultiCloud.setValue(false, forKey: "isEnabled")
            defaultiCloud.setValue(nil, forKey: "lastSyncStart")// Last time a sync was started from the app
            defaultiCloud.setValue(nil, forKey: "lastSuccessfulSync")// Last time a sync was finished successfully from the app
            defaultiCloud.setValue(nil, forKey: "lastRemoteSync")// Last time an update existed remotely
            defaultiCloud.setValue(nil, forKey: "lastLocalUpdate")// Last time something was updated locally
            
            self.settings.setObject(defaultiCloud, forKey: "iCloud")
            self.storeOptions = self.localStoreOptions()
        } else {
            var iCloudSettings: NSMutableDictionary = NSMutableDictionary(capacity: 5)
    
            iCloudSettings = self.settings.objectForKey("iCloud") as! NSMutableDictionary
            
            if (iCloudSettings.valueForKey("isEnabled") as! Bool == true) {
                self.storeOptions = self.iCloudStoreOptions()
            } else {
                self.storeOptions = self.localStoreOptions()
            }
    
        }
    
        // Search dates
        if (self.settings.valueForKey("searchFromDate") == nil) {
            self.settings.setValue(nil, forKey:"searchFromDate")
        }
        
        if (self.settings.valueForKey("searchToDate") == nil) {
            self.settings.setValue(nil, forKey:"searchToDate")
        }
        
        self.settings.synchronize()
        
    }
    
    // Reload store
    func reloadWithNewStore(newStore: NSPersistentStore?) {
        NSLog("RELOADING STORE")
    
        if (newStore != nil) {
            var error: NSError? = nil
            self.persistentStoreCoordinator!.removePersistentStore(newStore!, error: &error)
            if (error != nil) {
                NSLog("Unresolved error while removing persistent store %@, %@", error!, error!.userInfo!)
            }
        }
        
        var error: NSError? = nil
        
        self.persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.currentStoreURL(), options: self.storeOptions as? [NSObject : AnyObject], error: &error)
    }
    
    // Update iCloud start sync date
    func setiCloudStartSyncDate() {
        // Sync data if this is being called too son
        if (self.settings == nil) {
            self.synchronizeSettings()
        }
        
        var iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
    
        NSLog("Set the sync start date to now")
    
        // Set the sync start date to now
        iCloudSettings.setValue(NSDate(), forKey: "lastSyncStart")
        
        self.settings.setObject(iCloudSettings, forKey: "iCloud")
    }
    
    // Update iCloud end sync date
    func setiCloudEndSyncDate() {
        // Sync data if this is being called too son
        if (self.settings == nil) {
            self.synchronizeSettings()
        }
        
        var iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
        
        NSLog("Set the sync end date to now")
        
        // Set the sync start date to now
        iCloudSettings.setValue(NSDate(), forKey: "lastSuccessfulSync")
        
        self.settings.setObject(iCloudSettings, forKey: "iCloud")
    }
    
    // Migrate data to iCloud
    func migrateDataToiCloud() {
        NSLog("Migrating data to iCloud")
        
        var tmpStoreOptions: NSMutableDictionary = self.storeOptions.mutableCopy() as! NSMutableDictionary
        
        tmpStoreOptions.setObject(true, forKey: NSPersistentStoreRemoveUbiquitousMetadataOption)
        
        //var store: NSPersistentStore = self.persistentStoreCoordinator!.persistentStoreForURL(self.currentStoreURL())!
        
        var error: NSError? = nil
        
        //var tmpStore: NSPersistentStore = self.persistentStoreCoordinator!.migratePersistentStore(store, toURL: self.currentStoreURL(), options: self.storeOptions as? [NSObject : AnyObject], withType: NSSQLiteStoreType, error: &error)!
        var tmpStore: NSPersistentStore? = nil
    
        // Update store options for reload
        self.storeOptions = self.iCloudStoreOptions()
    
        // Reload store
        self.reloadWithNewStore(tmpStore)
        
        var iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
    
        NSLog("Set the last remote sync date to now")
    
        // Set the last remote sync date to now
        iCloudSettings.setValue(NSDate(), forKey: "lastRemoteSync")
        
        self.settings.setObject(iCloudSettings, forKey: "iCloud")
    }
    
    // Migrate data to local
    func migrateDataToLocal() {
        NSLog("Migrating data to Local")
        
        var tmpStoreOptions: NSMutableDictionary = self.storeOptions.mutableCopy() as! NSMutableDictionary
        
        tmpStoreOptions.setObject(true, forKey: NSPersistentStoreRemoveUbiquitousMetadataOption)
        
        //var store: NSPersistentStore = self.persistentStoreCoordinator!.persistentStoreForURL(self.currentStoreURL())!
        
        var error: NSError? = nil
        
        //var tmpStore: NSPersistentStore = self.persistentStoreCoordinator!.migratePersistentStore(store, toURL: self.currentStoreURL(), options: self.storeOptions as? [NSObject : AnyObject], withType: NSSQLiteStoreType, error: &error)!
        var tmpStore: NSPersistentStore? = nil
        
        // Update store options for reload
        self.storeOptions = self.localStoreOptions()
        
        // Reload store
        self.reloadWithNewStore(tmpStore)
        
        var iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
        
        NSLog("Set the last local sync date to now")
        
        // Set the last remote sync date to now
        iCloudSettings.setValue(NSDate(), forKey: "lastLocalUpdate")
        
        self.settings.setObject(iCloudSettings, forKey: "iCloud")
    }
    
    // Remove all data
    func removeAllData() {
        NSLog("REMOVING ALL DATA!")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Remove all events
        var entityDesc = NSEntityDescription.entityForName("Event", inManagedObjectContext:context!)
        
        var request = NSFetchRequest()
        request.entity = entityDesc
        
        var objects: [NSManagedObject]
        
        var error: NSError? = nil
        
        objects = context!.executeFetchRequest(request, error: &error) as! [NSManagedObject]
        
        if ( error == nil ) {
            for object: NSManagedObject in objects {
                context?.deleteObject(object)
            }
            
            context?.save(&error)
        } else {
            NSLog("Error: %@", error!)
        }
    }

}

