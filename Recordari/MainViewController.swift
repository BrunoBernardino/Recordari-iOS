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
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    
    var addedEventView: Bool = false
    
    var statusBarShowing: Bool = true
    
    @IBOutlet weak var boxesView: UIView!
    @IBOutlet weak var logNewEventButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    public override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            self.view.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add color to the tab bar's active items
        UITabBar.appearance().tintColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        
        // Color for unselected text
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State())
        
        // Color for selected text
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: UIControl.State.selected)
        
        //
        // Add color to the tab bar's inactive items
        //

        // Main tab item
        let mainIcon: UITabBarItem = self.tabBarController!.tabBar.items![0] 
        
        let unselectedMainImage: UIImage = UIImage(named: "main-icon")!
        let selectedMainImage: UIImage = UIImage(named: "main-icon")!
        
        mainIcon.image = unselectedMainImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        mainIcon.selectedImage = selectedMainImage
        
        // Events tab item
        let eventsIcon: UITabBarItem = self.tabBarController!.tabBar.items![1] 
        
        let unselectedEventsImage: UIImage = UIImage(named: "events-icon")!
        let selectedEventsImage: UIImage = UIImage(named: "events-icon")!
        
        eventsIcon.image = unselectedEventsImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        eventsIcon.selectedImage = selectedEventsImage
        
        // Settings tab item
        let settingsIcon: UITabBarItem = self.tabBarController!.tabBar.items![2] 
        
        let unselectedSettingsImage: UIImage = UIImage(named: "settings-icon")!
        let selectedSettingsImage: UIImage = UIImage(named: "settings-icon")!
        
        settingsIcon.image = unselectedSettingsImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        settingsIcon.selectedImage = selectedSettingsImage
        
        // Stats tab item
        let statsIcon: UITabBarItem = self.tabBarController!.tabBar.items![3]
        
        let unselectedStatsImage: UIImage = UIImage(named: "stats-icon")!
        let selectedStatsImage: UIImage = UIImage(named: "stats-icon")!
        
        statsIcon.image = unselectedStatsImage.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        statsIcon.selectedImage = selectedStatsImage
        
        // Initialize Watch Session
        if #available(iOS 9.0, *) {
            self.initializeWatchSession()
        }
        
        // Make sure you can log a new event
        self.logNewEventButton.addTarget(self, action: #selector(MainViewController.addEvent(_:)), for: UIControl.Event.touchUpInside)
        
        // Make sure you can always scroll
        self.scrollView.contentSize = CGSize(width: self.boxesView.frame.size.width, height: self.boxesView.frame.size.height + 100)
        
        // Make sure the "Log New Event" button will be visible for shorter screens
        if (self.view.frame.height <= 568) {
            self.logNewEventButton.layer.position.y += 40
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we already added the views, remove everything first
        if (self.addedEventView) {
            for view in self.boxesView.subviews {
                if view.isKind(of: UIButton.self) == true {
                    let button = view as! UIButton

                    if button.currentTitle != "Log New Event" {
                        view.removeFromSuperview()
                    }
                }
            }
        }
        
        // Fetch popular events
        let topEvents = self.getTopEvents()
        
        var currentEventIndex: CGFloat = 1
        
        for topEvent in topEvents {
            let topEventButton = self.createEventButton(rowIndex: currentEventIndex, buttonText: (topEvent as AnyObject).value(forKey: "name") as! String)
            topEventButton.addTarget(self, action: #selector(MainViewController.addEvent(_:)), for: UIControl.Event.touchUpInside)

            self.boxesView.addSubview(topEventButton)
            
            currentEventIndex += 1
        }
        
        // Mark flag
        self.addedEventView = true
        
    }
    
    // Hide or show status bar as necessary
    override var prefersStatusBarHidden : Bool {
        return !self.statusBarShowing
    }
    
    // Create an event button
    func createEventButton(rowIndex: CGFloat, buttonText: String) -> UIButton {
        let yPos = rowIndex * (self.logNewEventButton.frame.size.height + 10) + self.logNewEventButton.layer.position.y
        let buttonRect: CGRect = CGRect(x: 0, y: 0, width: self.logNewEventButton.frame.size.width, height: self.logNewEventButton.frame.size.height)

        let button = UIButton(frame: buttonRect)
        
        button.center = CGPoint(x: self.logNewEventButton.layer.position.x, y: yPos)
        
        button.setTitle(buttonText, for: UIControl.State())
        
        button.setTitleColor(UIColor.black, for: UIControl.State())
        //button.backgroundColor = UIColor.black
        
        button.clipsToBounds = true
        if #available(iOS 8.2, *) {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.light)
        } else {
            // Fallback on earlier versions
        }
        
        return button
    }
    
    // Get top events
    func getTopEvents() -> NSArray {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Group by Name, with .count
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        let countExpressionArguments = [NSExpression(forKeyPath: "name")]
        let countExpression = NSExpression(forFunction: "count:", arguments: countExpressionArguments)

        let countExpressionDescription = NSExpressionDescription()
        countExpressionDescription.expression = countExpression
        countExpressionDescription.name = "count"
        countExpressionDescription.expressionResultType = NSAttributeType.integer64AttributeType

        request.propertiesToFetch = ["name", countExpressionDescription]
        request.propertiesToGroupBy = ["name"]
        
        // Fetch 100 at most
        request.fetchLimit = 100
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
            return objects
        }
        
        //NSLog("%@", objects)
        
        // Sort by count
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "count", ascending: false)
        objects = (objects.sortedArray(using: [sortDescriptor]) as NSArray?)!
        
        // Return only top 12 elements at most
        if (objects.count > 12) {
            // TODO: This should really just be a swift array to be able to do nicer stuff
            return [
                objects[0],
                objects[1],
                objects[2],
                objects[3],
                objects[4],
                objects[5],
                objects[6],
                objects[7],
                objects[8],
                objects[9],
                objects[10],
                objects[11]
            ]
        }
        
        return objects
    }
    
    // A log button was pressed
    @objc func addEvent(_ sender: UIButton!) {
        //NSLog("Event Name = %@", sender.currentTitle!)
        
        // If we're not adding a quick event (but a new/custom one), trigger the segue
        if (sender.currentTitle == "Log New Event") {
            self.performSegue(withIdentifier: "addEvent", sender: self)
            return
        }
        
        // Otherwise we're adding a quick event
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        let eventName: NSString = sender.currentTitle! as NSString
        let eventDate: Date = Date()// Event date will be now
        
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
        
        let newEvent: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context!) 
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Add main controller to addEvent view
        if (segue.identifier == "addEvent") {
            let viewController = segue.destination as! AddEventViewController
            viewController.mainViewController = self
        }
    }
    
    // Show alert modal
    func showAlert(_ message: String) {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "Recordari", message:
                message, preferredStyle: UIAlertController.Style.alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: UIAlertAction.Style.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Show "toast"
    func showToast(_ message: String, window: UIWindow) {
        let initialYPos: CGFloat = window.frame.size.height
        let finalYPos: CGFloat = window.frame.size.height - 50
        
        // Create view for the notification
        let toastView = UIView(frame: CGRect(x: 0, y: initialYPos, width: window.frame.size.width, height: 50))
        
        // Set properties of the view
        toastView.backgroundColor = UIColor.black
        
        // Create label with text and properties
        let labelView = UILabel(frame: CGRect(x: 0, y: 0, width: window.frame.size.width, height: 50))
        labelView.text = message
        labelView.textColor = UIColor.white
        labelView.textAlignment = NSTextAlignment.center
        labelView.font = UIFont(name: "System-Light", size: 10)
        
        // Add label to view
        toastView.addSubview(labelView)
        
        // Add view to window
        window.addSubview(toastView)
        
        // Animate view entrance
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.curveEaseOut
            , animations: {
                toastView.frame.origin.y = finalYPos
            }, completion: {
                (finished: Bool) -> Void in
                
                // Animate view exit
                UIView.animate(withDuration: 0.3, delay: 1.5, options: UIView.AnimationOptions.curveEaseOut
                    , animations: {
                        toastView.frame.origin.y = initialYPos
                    }, completion: {
                        (finished: Bool) -> Void in
                        // Remove the view for the notification
                        toastView.removeFromSuperview()
                    }
                )
            }
        )
    }
    
    func getSimpleTopEvents() -> Array<String> {
        let topEvents = self.getTopEvents()

        var simpleEvents: Array<String> = []
        
        let arrayEvents = topEvents as Array<AnyObject>
        
        // Simplify topEvents
        for event in arrayEvents {
            simpleEvents.append(event.value(forKey: "name") as! String)
        }
        
        return simpleEvents
    }
    
    // Initialize Watch Session
    @available(iOS 9.0, *)
    func initializeWatchSession() {
        if (WCSession.isSupported()) {
            let watchSession = WCSession.default
            watchSession.delegate = self
            watchSession.activate()
        }
    }
    
    // Receive message from the watch to add event
    @available(iOS 9.0, *)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let newRequest : String? = message["request"] as? String
        let newEvent : String? = message["event"] as? String

        if newRequest == "topEvents" {
            // The Watch is Requesting top events
            NSLog("RECEIVED NEW REQUEST FOR TOP EVENTS")
            
            let simpleEvents = self.getSimpleTopEvents()
            
            replyHandler(["topEvents": simpleEvents])
        } else {
            // The watch is asking to add an event
            NSLog("RECEIVED NEW EVENT TO ADD: %@", newEvent!)

            self.addQuickEvent(newEvent!)
            
            replyHandler(["status": "OK"])
        }
    }
    
    // Add a quick event
    func addQuickEvent(_ eventName: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        let eventDate: Date = Date()// Default event date to "now"
        
        //
        // Save object
        //
        
        let newEvent: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context!)
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

