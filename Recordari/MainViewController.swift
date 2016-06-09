//
//  MainViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 21/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity

class MainViewController: UIViewController, WCSessionDelegate {
    
    var addedEventView: Bool = false
    
    var statusBarShowing: Bool = true
    
    var watchSession: WCSession!
    
    @IBOutlet weak var boxesView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add color to the tab bar's active items
        UITabBar.appearance().tintColor = UIColor.blackColor()
        UITabBar.appearance().barTintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        
        // Color for unselected text
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
        
        // Color for selected text
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.blackColor()], forState: UIControlState.Selected)
        
        //
        // Add color to the tab bar's inactive items
        //

        // Main tab item
        let mainIcon: UITabBarItem = self.tabBarController!.tabBar.items![0] 
        
        let unselectedMainImage: UIImage = UIImage(named: "main-icon")!
        let selectedMainImage: UIImage = UIImage(named: "main-icon")!
        
        mainIcon.image = unselectedMainImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        mainIcon.selectedImage = selectedMainImage
        
        // Events tab item
        let eventsIcon: UITabBarItem = self.tabBarController!.tabBar.items![1] 
        
        let unselectedEventsImage: UIImage = UIImage(named: "events-icon")!
        let selectedEventsImage: UIImage = UIImage(named: "events-icon")!
        
        eventsIcon.image = unselectedEventsImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        eventsIcon.selectedImage = selectedEventsImage
        
        // Settings tab item
        let settingsIcon: UITabBarItem = self.tabBarController!.tabBar.items![2] 
        
        let unselectedSettingsImage: UIImage = UIImage(named: "settings-icon")!
        let selectedSettingsImage: UIImage = UIImage(named: "settings-icon")!
        
        settingsIcon.image = unselectedSettingsImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        settingsIcon.selectedImage = selectedSettingsImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we already added the views, remove everything first
        if (self.addedEventView) {
            for view in self.boxesView.subviews {
                view.removeFromSuperview()
            }
        }
        
        //NSLog("Writing views")
        
        // Add "Log New Event" view top the top left, make sure it's half the width and a third of the height.
        let logNewEventView = self.createEventBoxView(0, colIndex: 0)
        logNewEventView.buttonText = NSLocalizedString("Log New Event", comment: "")
        logNewEventView.showButton()
        logNewEventView.button.setTitleColor(UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1), forState: UIControlState.Normal)
        logNewEventView.button.addTarget(self, action: #selector(MainViewController.addEvent(_:)), forControlEvents: UIControlEvents.TouchUpInside)

        self.boxesView.addSubview(logNewEventView)
        
        // Fetch popular events
        let topEvents = self.getTopEvents()
        
        // Send top events to watch app
        NSLog("SENDING DATA TO WATCH")
        do {
            try self.watchSession?.updateApplicationContext(
                ["topEvents" : topEvents]
            )
        } catch let error as NSError {
            NSLog("Updating the context failed: " + error.localizedDescription)
        }
        
        let countOfTopEvents = topEvents.count
        
        var rowIndex: CGFloat = 0
        var colIndex: CGFloat = 0
        
        var numberOfItem = 1
        
        for topEvent in topEvents {
            // Define the proper rowIndex and colIndex for the item
            switch numberOfItem {
                case 1:
                    rowIndex = 0
                    colIndex = 1
                break
                case 2:
                    rowIndex = 1
                    colIndex = 0
                break
                case 3:
                    rowIndex = 1
                    colIndex = 1
                break
                case 4:
                    rowIndex = 2
                    colIndex = 0
                break
                case 5:
                    rowIndex = 2
                    colIndex = 1
                break
                default:
                    NSLog("## This should not be happening!!! ##")
                    continue
            }

            let topEventView = self.createEventBoxView(rowIndex, colIndex: colIndex)
            topEventView.buttonText = topEvent.valueForKey("name") as! String
            topEventView.name = topEvent.valueForKey("name") as! String
            topEventView.showButton()
            topEventView.button.addTarget(self, action: #selector(MainViewController.addEvent(_:)), forControlEvents: UIControlEvents.TouchUpInside)

            self.boxesView.addSubview(topEventView)
            
            numberOfItem += 1
        }
        
        // Add "blank" events to log
        var countOfBlankEvents = 5 - countOfTopEvents

        while (countOfBlankEvents > 0) {
            // Define the proper rowIndex and colIndex for the item
            switch numberOfItem {
                case 1:
                    rowIndex = 0
                    colIndex = 1
                break
                case 2:
                    rowIndex = 1
                    colIndex = 0
                break
                case 3:
                    rowIndex = 1
                    colIndex = 1
                break
                case 4:
                    rowIndex = 2
                    colIndex = 0
                break
                case 5:
                    rowIndex = 2
                    colIndex = 1
                break
                default:
                    NSLog("## This should not be happening!!! ##")
                    continue
            }

            let blankEventView = self.createEventBoxView(rowIndex, colIndex: colIndex)
            blankEventView.showButton()
            blankEventView.button.addTarget(self, action: #selector(MainViewController.addEvent(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            self.boxesView.addSubview(blankEventView)

            countOfBlankEvents -= 1
            numberOfItem += 1
        }
        
        // Add white bar view to hide the divider behind the status bar
        let blankView: UIView = UIView(frame: CGRectMake(0, 0, self.boxesView.frame.width, 20))
        blankView.backgroundColor = UIColor.whiteColor()
        self.boxesView.addSubview(blankView)
        
        // Add white bar on the sides, to hide grey ones due to AutoLayout
        if (self.addedEventView && self.boxesView.frame.width > 391) {
            let leftBlankView: UIView = UIView(frame: CGRectMake(0, 0, 1, self.boxesView.frame.height))
            leftBlankView.backgroundColor = UIColor.whiteColor()
            self.boxesView.addSubview(leftBlankView)
            
            let rightBlankView: UIView = UIView(frame: CGRectMake(self.boxesView.frame.width - 1, 0, 1, self.boxesView.frame.height))
            rightBlankView.backgroundColor = UIColor.whiteColor()
            self.boxesView.addSubview(rightBlankView)
        }
        
        // Mark flag
        self.addedEventView = true
        
    }
    
    // Hide or show status bar as necessary
    override func prefersStatusBarHidden() -> Bool {
        return !self.statusBarShowing
    }
    
    // Create Event Box view
    func createEventBoxView(rowIndex: CGFloat, colIndex: CGFloat) -> EventBoxView {
        //let tabBarHeight: CGFloat = self.tabBarController!.tabBar.frame.size.height
        let statusBarHeight: CGFloat = 20
        
        let originX: CGFloat = self.boxesView.frame.origin.x
        let originY: CGFloat = self.boxesView.frame.origin.y
        let boxWidth: CGFloat = (self.boxesView.frame.size.width / 2)
        var boxHeight: CGFloat = ((self.boxesView.frame.size.height - statusBarHeight) / 3)
        var frame: CGRect
        
        let frameX = originX + (colIndex * boxWidth)
        var frameY = originY + (rowIndex * boxHeight)

        var topOffset: CGFloat = 0
        var bottomOffset: CGFloat = 0
        
        // If this is the first row, position the box behind the status bar, with the increased height
        if (rowIndex == 0) {
            frameY = frameY - statusBarHeight
            boxHeight = boxHeight + statusBarHeight
            topOffset = statusBarHeight
        }
        
        // If this is the last row, position the box behind the tab bar, with the increased height
        if (rowIndex == 2) {
            boxHeight = boxHeight + statusBarHeight
            bottomOffset = statusBarHeight
        }
        
        frame = CGRectMake(frameX, frameY, boxWidth, boxHeight)
        
        let eventView: EventBoxView = EventBoxView(frame: frame, topOffset: topOffset, bottomOffset: bottomOffset)
        
        return eventView
    }
    
    // Get top 5 events
    func getTopEvents() -> NSArray {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Event", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        // Group by Name, with .count
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        let countExpressionArguments = [NSExpression(forKeyPath: "name")]
        let countExpression = NSExpression(forFunction: "count:", arguments: countExpressionArguments)

        let countExpressionDescription = NSExpressionDescription()
        countExpressionDescription.expression = countExpression
        countExpressionDescription.name = "count"
        countExpressionDescription.expressionResultType = NSAttributeType.Integer64AttributeType

        request.propertiesToFetch = ["name", countExpressionDescription]
        request.propertiesToGroupBy = ["name"]
        
        // Fetch 100 at most
        request.fetchLimit = 100
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
            return objects
        }
        
        //NSLog("%@", objects)
        
        // Sort by count
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "count", ascending: false)
        objects = objects.sortedArrayUsingDescriptors([sortDescriptor])
        
        // Return only top 5 elements at most
        if (objects.count > 5) {
            return [ objects[0], objects[1], objects[2], objects[3], objects[4] ]
        }
        
        return objects
    }
    
    // A log button was pressed
    func addEvent(sender: UIButton!) {
        let eventBoxView: EventBoxView = sender.superview! as! EventBoxView
        
        //NSLog("Event Name = %@", eventBoxView.name)
        
        // If we're not adding a quick event (but a new/custom one), trigger the segue
        if (eventBoxView.name == "") {
            self.performSegueWithIdentifier("addEvent", sender: self)
            return
        }
        
        // Otherwise we're adding a quick event
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        let eventName: NSString = eventBoxView.name
        let eventDate: NSDate = NSDate()// Event date will be now
        
        //NSLog("VALUES = %@, %@", eventName, eventDate)
        
        //
        // START: Validate fields for common errors
        //
        
        // Check if the event name is not empty
        if ( eventName.length <= 0 ) {
            self.showAlert(NSLocalizedString("Please confirm the name of the event.", comment:""))
            
            return
        }
        
        //
        // END: Validate fields for common errors
        //
        
        //
        // Save object
        //
        
        let newEvent: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Event", inManagedObjectContext: context!) 
        newEvent.setValue(eventName, forKey: "name")
        newEvent.setValue(eventDate, forKey: "date")
        
        var error: NSError? = nil
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if (error == nil) {
            // Show toast
            self.showToast(NSLocalizedString("Event added.", comment:""), window: self.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.showAlert(NSLocalizedString("There was an error adding your event. Please confirm the name and date are correct.", comment:""))
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Add main controller to addEvent view
        if (segue.identifier == "addEvent") {
            let viewController = segue.destinationViewController as! AddEventViewController
            viewController.mainViewController = self
        }
    }
    
    // Show alert modal
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Recordari", message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Show "toast"
    func showToast(message: String, window: UIWindow) {
        // Hide status bar
        self.statusBarShowing = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Create view for the notification
        let toastView = UIView(frame: CGRectMake(0, -20, window.frame.size.width, 20))
        
        // Set properties of the view
        toastView.backgroundColor = UIColor.blackColor()
        
        // Create label with text and properties
        let labelView = UILabel(frame: CGRectMake(0, 0, window.frame.size.width, 20))
        labelView.text = message
        labelView.textColor = UIColor.whiteColor()
        labelView.textAlignment = NSTextAlignment.Center
        labelView.font = UIFont(name: "System-Light", size: 10)
        
        // Add label to view
        toastView.addSubview(labelView)
        
        // Add view to window
        window.addSubview(toastView)
        
        // Animate view entrance
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseOut
            , animations: {
                toastView.frame.origin.y = 0
            }, completion: {
                (finished: Bool) -> Void in
                
                // Animate view exit
                UIView.animateWithDuration(0.3, delay: 1.5, options: UIViewAnimationOptions.CurveEaseOut
                    , animations: {
                        toastView.frame.origin.y = -20
                    }, completion: {
                        (finished: Bool) -> Void in
                        
                        // Show status bar
                        self.statusBarShowing = true
                        self.setNeedsStatusBarAppearanceUpdate()
                            
                        // Remove the view for the notification
                        toastView.removeFromSuperview()
                    }
                )
            }
        )
    }
    
    // Receive message from the watch to add event
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let newEvent : String = message["event"] as! String
        NSLog("RECEIVED NEW EVENT TO ADD: %@", newEvent)

        self.addQuickEvent(newEvent)
        
        replyHandler(["status": "OK"])
    }
    
    // Add a quick event
    func addQuickEvent(eventName: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        let eventDate: NSDate = NSDate()// Default event date to "now"
        
        NSLog("VALUES = %@, %@", eventName, eventDate)
        
        //
        // Save object
        //
        
        let newEvent: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Event", inManagedObjectContext: context!)
        newEvent.setValue(eventName, forKey: "name")
        newEvent.setValue(eventDate, forKey: "date")
        
        var error: NSError? = nil
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if (error == nil) {
            // Nothing?
        } else {
            NSLog("Error: %@", error!)
        }
    }
}

