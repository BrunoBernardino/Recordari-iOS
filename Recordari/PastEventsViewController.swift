//
//  PastEventsViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 21/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData

class PastEventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {

    @IBOutlet weak var fromDateLabel: UITextField!
    @IBOutlet weak var toDateLabel: UITextField!
    @IBOutlet weak var nameFilterBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var fromDate: NSDate? = nil
    var toDate: NSDate? = nil
    
    var events: NSMutableArray = []
    
    var selectedEvent: NSManagedObject!
    var settings: NSUserDefaults!
    
    var statusBarShowing: Bool = true
    
    var loadedOnce: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Change the background color of the search bar
        self.nameFilterBar.tintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        self.nameFilterBar.barTintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        self.nameFilterBar.backgroundColor = UIColor.clearColor()
        
        // Have name filter respond to this controller
        self.nameFilterBar.delegate = self
        
        // Have from date label respond to this controller
        self.fromDateLabel.delegate = self

        // Have to date label respond to this controller
        self.toDateLabel.delegate = self
        
        // Have table respond to this controller
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Fetch settings
        self.fetchSearchSettings()

        // Fetch all events
        self.getAllEvents()
        
        // Make sure the from date input will show a date picker
        addDatePickerToInput("from")
        
        // Make sure the to date input will show a date picker
        addDatePickerToInput("to")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we already loaded this view, fetch search settings and all events again
        if (self.loadedOnce) {
            // Fetch settings
            self.fetchSearchSettings()
            
            // Fetch all events
            self.getAllEvents()
        }
        
        self.loadedOnce = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }

    // Display data in the table view
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: EventTableCell = tableView.dequeueReusableCellWithIdentifier("eventCell") as! EventTableCell
        
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventName: String = self.events.objectAtIndex(indexPath.row).valueForKey("name") as! String
        let eventDate: NSDate = self.events.objectAtIndex(indexPath.row).valueForKey("date") as! NSDate

        let dateString: String = dateFormatter.stringFromDate(eventDate)
        
        cell.eventNameLabel.text = eventName
        cell.eventDateLabel.text = dateString
        
        return cell
    }
    
    // Show edit/update event view
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedEvent = self.events.objectAtIndex(indexPath.row) as! NSManagedObject
        
        // Show edit event
        self.performSegueWithIdentifier("editEvent", sender: self)
    }
    
    // Allow events to be deleted
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Delete event
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context: NSManagedObjectContext? = appDelegate.managedObjectContext
            
            // Delete from core data
            context!.deleteObject(self.events.objectAtIndex(indexPath.row) as! NSManagedObject)
            do {
                try context!.save()
            } catch _ {
            }
            
            // Delete from view
            self.events.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
            
            // Reload data
            self.getAllEvents()
        }
    }
    
    // Table is being dragged
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Dismiss possible keyboard on search field
        self.nameFilterBar.endEditing(true)
        
        // Dismiss possible datepicker on date fields
        self.fromDateLabel.endEditing(true)
        self.toDateLabel.endEditing(true)
    }
    
    // Name filter changed
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.getAllEvents()
    }
    
    // When the from date UIDatePicker is set, update the label and filters
    func fromDatePickerChanged(sender: UIDatePicker) {
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventDate: NSDate = sender.date
        
        let dateString: String = dateFormatter.stringFromDate(eventDate)

        self.fromDateLabel.text = dateString
        self.fromDate = eventDate
        
        // Update Events
        self.getAllEvents()
    }
    
    // When the to date UIDatePicker is set, update the label and filters
    func toDatePickerChanged(sender: UIDatePicker) {
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventDate: NSDate = sender.date
        
        let dateString: String = dateFormatter.stringFromDate(eventDate)
        
        self.toDateLabel.text = dateString
        self.toDate = eventDate
        
        // Update Events
        self.getAllEvents()
    }
    
    // Close the datepicker, when "Done" is tapped
    func datePickerDone(sender: AnyObject) {
        // Dismiss datepicker on date fields
        self.fromDateLabel.endEditing(true)
        self.toDateLabel.endEditing(true)
        
        // Update Events
        self.getAllEvents()
    }
    
    // Get all events (filtered by date and text/name)
    func getAllEvents() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Event", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        // Sort events by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        // Check if the dates are valid
        if ( self.fromDate == nil || self.toDate == nil ) {
            // If not, set the dates as the current month (first to last day)
            //NSLog( "DATES WERE NOT VALID!!!" );
            self.setDefaultSearchDates()
        }
        
        //
        // Update dates' times
        //
        
        // Make start date's time = 00:00:00
        let currentCalendar = NSCalendar.currentCalendar()
        let calendarUnits: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
        let fromDateComponents = currentCalendar.components(calendarUnits, fromDate: self.fromDate!)
        
        fromDateComponents.hour = 0
        fromDateComponents.minute = 0
        fromDateComponents.second = 0
        
        self.fromDate = currentCalendar.dateFromComponents(fromDateComponents)
        
        // Make end date's time = 23:59:59
        let toDateComponents = currentCalendar.components(calendarUnits, fromDate: self.toDate!)
        
        toDateComponents.hour = 23
        toDateComponents.minute = 59
        toDateComponents.second = 59
        
        self.toDate = currentCalendar.dateFromComponents(toDateComponents)
        
        //
        // Update search settings and search
        //
        
        self.updateSearchSettings()
        
        let usedPredicates = NSMutableArray()
        
        // Add dates to search
        let datesPredicate = NSPredicate(format: "(date >= %@) and (date <= %@)", self.fromDate!, self.toDate!)
        
        usedPredicates.addObject(datesPredicate)
        
        // Add any self.currentFilterName to search
        let filterNamePredicate: NSPredicate
        if ( self.nameFilterBar.text!.characters.count > 0 ) {
            filterNamePredicate = NSPredicate(format: "(name CONTAINS[cd] %@)", self.nameFilterBar.text!)
            
            usedPredicates.addObject(filterNamePredicate)
        }
        
        // Add the predicate to the request
        let finalPredicate: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:usedPredicates as AnyObject as! [NSPredicate])
        request.predicate = finalPredicate
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        self.events = NSMutableArray(array: objects)
        
        //NSLog("%@", self.events)
        
        // Reload view with new data
        self.tableView.reloadData()
    }
    
    // Fetch search settings
    func fetchSearchSettings() {
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
        
        var shouldUpdateUI = false
        
        //
        // Dates
        //
        
        if let currentSearchFromDate = self.settings.valueForKey("searchFromDate") as? NSDate {
            self.fromDate = currentSearchFromDate
            shouldUpdateUI = true
        }
        
        if let currentSearchToDate = self.settings.valueForKey("searchToDate") as? NSDate {
            self.toDate = currentSearchToDate
            shouldUpdateUI = true
        }
        
        // UI Updates
        if (shouldUpdateUI) {
            self.updateSearchLabelsAndViews()
        }
    }
    
    // Update search settings
    func updateSearchSettings() {
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
        
        self.settings.setValue(self.fromDate, forKey: "searchFromDate")
        self.settings.setValue(self.toDate, forKey: "searchToDate")
    }
    
    // Update search labels & views
    func updateSearchLabelsAndViews() {
        let dateFormatter = NSDateFormatter()
        
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM d, yyyy", comment: "")
        
        // Set "from date" text view
        self.fromDateLabel.text = dateFormatter.stringFromDate(self.fromDate!)
        
        // Set "to date" text view
        self.toDateLabel.text = dateFormatter.stringFromDate(self.toDate!)
    }
    
    // Set from and to dates to the current month (first and last day)
    func setDefaultSearchDates() {
        let dateFormatter = NSDateFormatter()
        let currentDate = NSDate()
        let currentCalendar = NSCalendar.currentCalendar()
        let calendarUnits: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day]
        
        let dateComponents = currentCalendar.components(calendarUnits, fromDate: currentDate)
        
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM d, yyyy", comment: "")
        
        //
        // Set "from date"
        //
        dateComponents.day = 1
        self.fromDate = currentCalendar.dateFromComponents(dateComponents)
        
        // Set "from date" text field
        self.fromDateLabel.text = dateFormatter.stringFromDate(self.fromDate!)
        
        //
        // Set "to date"
        //
        let daysRange: NSRange = currentCalendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: currentDate)
        dateComponents.day = daysRange.length// Last day of the current month
        
        self.toDate = currentCalendar.dateFromComponents(dateComponents)
        
        // Set "to date" text
        self.toDateLabel.text = dateFormatter.stringFromDate(self.toDate!)
        
        // UI Updates
        updateSearchLabelsAndViews()
    }
    
    // Add a datepicker with the "Done" button to an input
    func addDatePickerToInput(inputShortName: String) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.Date
        datePickerView.backgroundColor = UIColor.whiteColor()

        if (inputShortName == "from") {
            datePickerView.date = self.fromDate!
        } else {
            datePickerView.date = self.toDate!
        }
        
        // Position the UIDatePicker
        datePickerView.frame.origin.x = 0
        datePickerView.frame.origin.y = self.view.frame.size.height - datePickerView.frame.size.height
        
        // Add the done button to the UIDatePicker
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = true
        toolBar.tintColor = UIColor.whiteColor()
        toolBar.sizeToFit()
        toolBar.frame.origin.y = -43
        
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment:""), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PastEventsViewController.datePickerDone(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        doneButton.tintColor = UIColor.blackColor()
        
        toolBar.setItems([spaceButton, doneButton], animated: true)
        toolBar.userInteractionEnabled = true
        doneButton.enabled = true
        
        if (inputShortName == "from") {
            self.fromDateLabel.inputAccessoryView = toolBar
            
            // Add the UIDatePicker to the view
            self.fromDateLabel.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(PastEventsViewController.fromDatePickerChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        } else {
            self.toDateLabel.inputAccessoryView = toolBar
            
            // Add the UIDatePicker to the view
            self.toDateLabel.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(PastEventsViewController.toDatePickerChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        }
    }
    
    // Dismiss keyboard or show date pickers as necessary, when the main view is touched
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch: UITouch = (touches.first as UITouch!)!
        
        // Set action for tapping the "from date" view
        if (touch.view == self.fromDateLabel) {
            // TODO: Trigger date picker
        }
        
        // Set action for tapping the "to date" view
        if (touch.view == self.toDateLabel) {
            // TODO Trigger date picker
        }
        
        // Dismiss possible keyboard on search field
        self.nameFilterBar.endEditing(true)
        
        // Dismiss possible datepicker on date fields
        self.fromDateLabel.endEditing(true)
        self.toDateLabel.endEditing(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Add main controller to editEvent view
        if (segue.identifier == "editEvent") {
            let viewController = segue.destinationViewController as! EditEventViewController
            viewController.listViewController = self
            
            // Set selected event
            viewController.selectedEvent = self.selectedEvent
        }
    }
    
    // Hide or show status bar as necessary
    override func prefersStatusBarHidden() -> Bool {
        return !self.statusBarShowing
    }
    
    // Show alert modal
    func showAlert(message: String) {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "Recordari", message:
                message, preferredStyle: UIAlertControllerStyle.Alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
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
}

