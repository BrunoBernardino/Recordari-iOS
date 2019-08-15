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

    var settings: UserDefaults!
    
    var storeOptions: NSDictionary!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.synchronizeSettings()
        
        // Change the default tint color
        self.window!.tintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        
        // Listen for iCloud changes (when they will happen)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.iCloudWillUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: nil)
        
        // Listen for iCloud changes (after it's done)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.iCloudDidUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: nil)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
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
    func currentStoreURL() -> URL {
        return self.applicationDocumentsDirectory.appendingPathComponent("Oikon.sqlite")
    }

    // iCloud will update
    @objc func iCloudWillUpdate(_ sender: AnyObject) {
        self.setiCloudStartSyncDate()
    }
    
    // iCloud finished updating
    @objc func iCloudDidUpdate(_ sender: AnyObject) {
        self.setiCloudEndSyncDate()
    }
    
    // MARK: - Core Data stack
    func observeCloudActions(persistentStoreCoordinator psc: NSPersistentStoreCoordinator?) {
        // iCloud notification subscriptions
        let nc = NotificationCenter.default;
        nc.addObserver(
            self,
            selector: #selector(AppDelegate.storesWillChange(_:)),
            name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange,
            object: psc);
        
        nc.addObserver(
            self,
            selector: #selector(AppDelegate.storesDidChange(_:)),
            name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange,
            object: psc);
        
        nc.addObserver(
            self,
            selector: #selector(AppDelegate.persistentStoreDidImportUbiquitousContentChanges(_:)),
            name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges,
            object: psc);
        
        nc.addObserver(
            self,
            selector: #selector(AppDelegate.mergeChanges(_:)),
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: psc);
    }
    
    @objc func mergeChanges(_ notification: Notification) {
        NSLog("mergeChanges notif:\(notification)")
        if let moc = managedObjectContext {
            moc.perform {
                moc.mergeChanges(fromContextDidSave: notification)
                self.postRefetchDatabaseNotification()
            }
        }
    }
    
    @objc func persistentStoreDidImportUbiquitousContentChanges(_ notification: Notification) {
        self.mergeChanges(notification)
    }
    
    // Subscribe to NSPersistentStoreCoordinatorStoresWillChangeNotification
    // most likely to be called if the user enables / disables iCloud
    // (either globally, or just for your app) or if the user changes
    // iCloud accounts.
    @objc func storesWillChange(_ notification: Notification) {
        NSLog("storesWillChange notif:\(notification)");
        if let moc = self.managedObjectContext {
            moc.performAndWait {
                do {
                    if moc.hasChanges {
                        try moc.save()
                    } else {
                        // drop any managed objects
                    }
                
                    // Reset context anyway, as suggested by Apple Support
                    // The reason is that when storesWillChange notification occurs, Core Data is going to switch the stores. During and after that switch (happening in background), your currently fetched objects will become invalid.
                
                    moc.reset();
                } catch {
                    NSLog("Save error: \(error)");
                }
            }
            
            // now reset your UI to be prepared for a totally different
            // set of data (eg, popToRootViewControllerAnimated:)
            // BUT don't load any new data yet.
        }
    }
    
    // Subscribe to NSPersistentStoreCoordinatorStoresDidChangeNotification
    @objc func storesDidChange(_ notification: Notification) {
        // here is when you can refresh your UI and
        // load new data from the new store
        NSLog("storesDidChange posting notif");
        self.postRefetchDatabaseNotification();
    }
    
    func postRefetchDatabaseNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "kRefetchDatabaseNotification"), // Replace with your constant of the refetch name, and add observer in the proper place - e.g. RootViewController
                object: nil);
        })
    }
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "hyouuu.pendo" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] 
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Recordari", withExtension: "momd")!
        NSLog("modelURL:\(modelURL)")
        return NSManagedObjectModel(contentsOf: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Recordari.sqlite")
        NSLog("storeURL:\(url)")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: url,
                        options: [NSPersistentStoreUbiquitousContentNameKey : "Recordari"])
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            //error = NSError(domain: "Pendo_Error_Domain", code: 9999, userInfo: dict as! [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("AddPersistentStore error \(String(describing: error)), \(error!.userInfo)")
        } catch {
            fatalError()
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                }
            }
        }
    }
    
    // Set / Get default settings
    func synchronizeSettings() {
        NSLog( "## Starting settings synchronization ##" )
        self.settings = UserDefaults.standard
        self.settings.synchronize()
    
        // iCloud sync
        if (self.settings.object(forKey: "iCloud") == nil) {
            let defaultiCloud: NSMutableDictionary = NSMutableDictionary(capacity: 5)
            
            defaultiCloud.setValue(false, forKey: "isEnabled")
            defaultiCloud.setValue(nil, forKey: "lastSyncStart")// Last time a sync was started from the app
            defaultiCloud.setValue(nil, forKey: "lastSuccessfulSync")// Last time a sync was finished successfully from the app
            defaultiCloud.setValue(nil, forKey: "lastRemoteSync")// Last time an update existed remotely
            defaultiCloud.setValue(nil, forKey: "lastLocalUpdate")// Last time something was updated locally
            
            self.settings.set(defaultiCloud, forKey: "iCloud")
            self.storeOptions = self.localStoreOptions()
        } else {
            var iCloudSettings: NSMutableDictionary = NSMutableDictionary(capacity: 5)
            
            iCloudSettings = (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary
            
            if (iCloudSettings.value(forKey: "isEnabled") as! Bool == true) {
                self.storeOptions = self.iCloudStoreOptions()
            } else {
                self.storeOptions = self.localStoreOptions()
            }
    
        }
    
        // Search dates
        if (self.settings.value(forKey: "searchFromDate") == nil) {
            self.settings.setValue(nil, forKey:"searchFromDate")
        }
        
        if (self.settings.value(forKey: "searchToDate") == nil) {
            self.settings.setValue(nil, forKey:"searchToDate")
        }
        
        self.settings.synchronize()
        
    }
    
    // Reload store
    func reloadWithNewStore(_ newStore: NSPersistentStore?) {
        NSLog("RELOADING STORE")
    
        if (newStore != nil) {
            var error: NSError? = nil
            do {
                try self.persistentStoreCoordinator!.remove(newStore!)
            } catch let error1 as NSError {
                error = error1
            }
            if (error != nil) {
                NSLog("Unresolved error while removing persistent store %@, %@", error!, error!.userInfo)
            }
        }
        
        do {
            try self.persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.currentStoreURL(), options: self.storeOptions as? [AnyHashable: Any])
        } catch {
            print("Error %@", error)
        }
    }
    
    // Update iCloud start sync date
    func setiCloudStartSyncDate() {
        // Sync data if this is being called too son
        if (self.settings == nil) {
            self.synchronizeSettings()
        }
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
    
        NSLog("Set the sync start date to now")
    
        // Set the sync start date to now
        iCloudSettings.setValue(Date(), forKey: "lastSyncStart")
        
        self.settings.set(iCloudSettings, forKey: "iCloud")
    }
    
    // Update iCloud end sync date
    func setiCloudEndSyncDate() {
        // Sync data if this is being called too son
        if (self.settings == nil) {
            self.synchronizeSettings()
        }
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
        
        NSLog("Set the sync end date to now")
        
        // Set the sync start date to now
        iCloudSettings.setValue(Date(), forKey: "lastSuccessfulSync")
        
        self.settings.set(iCloudSettings, forKey: "iCloud")
    }
    
    // Migrate data to iCloud
    func migrateDataToiCloud() {
        NSLog("Migrating data to iCloud")
        
        let tmpStoreOptions: NSMutableDictionary = self.storeOptions.mutableCopy() as! NSMutableDictionary
        
        tmpStoreOptions.setObject(true, forKey: NSPersistentStoreRemoveUbiquitousMetadataOption as NSCopying)
        
        //var store: NSPersistentStore = self.persistentStoreCoordinator!.persistentStoreForURL(self.currentStoreURL())!
        
        //var tmpStore: NSPersistentStore = self.persistentStoreCoordinator!.migratePersistentStore(store, toURL: self.currentStoreURL(), options: self.storeOptions as? [NSObject : AnyObject], withType: NSSQLiteStoreType, error: &error)!
        let tmpStore: NSPersistentStore? = nil
    
        // Update store options for reload
        self.storeOptions = self.iCloudStoreOptions()
    
        // Reload store
        self.reloadWithNewStore(tmpStore)
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
    
        NSLog("Set the last remote sync date to now")
    
        // Set the last remote sync date to now
        iCloudSettings.setValue(Date(), forKey: "lastRemoteSync")
        
        self.settings.set(iCloudSettings, forKey: "iCloud")
    }
    
    // Migrate data to local
    func migrateDataToLocal() {
        NSLog("Migrating data to Local")
        
        let tmpStoreOptions: NSMutableDictionary = self.storeOptions.mutableCopy() as! NSMutableDictionary
        
        tmpStoreOptions.setObject(true, forKey: NSPersistentStoreRemoveUbiquitousMetadataOption as NSCopying)
        
        //var store: NSPersistentStore = self.persistentStoreCoordinator!.persistentStoreForURL(self.currentStoreURL())!
        
        //var tmpStore: NSPersistentStore = self.persistentStoreCoordinator!.migratePersistentStore(store, toURL: self.currentStoreURL(), options: self.storeOptions as? [NSObject : AnyObject], withType: NSSQLiteStoreType, error: &error)!
        let tmpStore: NSPersistentStore? = nil
        
        // Update store options for reload
        self.storeOptions = self.localStoreOptions()
        
        // Reload store
        self.reloadWithNewStore(tmpStore)
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
        
        NSLog("Set the last local sync date to now")
        
        // Set the last remote sync date to now
        iCloudSettings.setValue(Date(), forKey: "lastLocalUpdate")
        
        self.settings.set(iCloudSettings, forKey: "iCloud")
    }
    
    // Remove all data
    func removeAllData() {
        NSLog("REMOVING ALL DATA!")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Remove all events
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        var objects: [NSManagedObject]
        
        var error: NSError? = nil
        
        objects = (try! context!.fetch(request)) as! [NSManagedObject]
        
        if ( error == nil ) {
            for object: NSManagedObject in objects {
                context?.delete(object)
            }
            
            do {
                try context?.save()
            } catch let error1 as NSError {
                error = error1
            }
        } else {
            NSLog("Error: %@", error!)
        }
    }

}

