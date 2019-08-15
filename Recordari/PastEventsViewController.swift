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
    
    var fromDate: Date? = nil
    var toDate: Date? = nil
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    
    var events: NSMutableArray = []
    
    var selectedEvent: NSManagedObject!
    var settings: UserDefaults!
    
    var statusBarShowing: Bool = true
    
    var loadedOnce: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Change the background color of the search bar
        self.nameFilterBar.tintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        self.nameFilterBar.barTintColor = UIColor(red: 255/255.0, green: 20/255.0, blue: 168/255.0, alpha: 1)
        self.nameFilterBar.backgroundColor = UIColor.clear
        
        // Have name filter respond to this controller
        self.nameFilterBar.delegate = self
        
        // Have from date label respond to this controller
        self.fromDateLabel.delegate = self

        // Have to date label respond to this controller
        self.toDateLabel.delegate = self
        
        // Have table respond to this controller
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Remove insets
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.layoutMargins = UIEdgeInsets.zero
        
        // Fetch settings
        self.fetchSearchSettings()

        // Fetch all events
        self.getAllEvents()
        
        // Make sure the from date input will show a date picker
        addDatePickerToInput("from")
        
        // Make sure the to date input will show a date picker
        addDatePickerToInput("to")
        
        // Make sure the "To:" label will be visible for narrower screens
        if (self.view.frame.width <= 320) {
            self.toLabel.layer.position.x += 32
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }

    // Display data in the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: EventTableCell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventTableCell
        
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventName: String = (self.events.object(at: indexPath.row) as AnyObject).value(forKey: "name") as! String
        let eventDate: Date = (self.events.object(at: indexPath.row) as AnyObject).value(forKey: "date") as! Date

        let dateString: String = dateFormatter.string(from: eventDate)
        
        cell.eventNameLabel.text = eventName
        cell.eventDateLabel.text = dateString
        
        return cell
    }
    
    // Show edit/update event view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedEvent = (self.events.object(at: indexPath.row) as! NSManagedObject)
        
        // Show edit event
        self.performSegue(withIdentifier: "editEvent", sender: self)
    }
    
    // Allow events to be deleted
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Delete event
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context: NSManagedObjectContext? = appDelegate.managedObjectContext
            
            // Delete from core data
            context!.delete(self.events.object(at: indexPath.row) as! NSManagedObject)
            do {
                try context!.save()
            } catch _ {
            }
            
            // Delete from view
            self.events.removeObject(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with:UITableView.RowAnimation.fade)
            
            // Reload data
            self.getAllEvents()
        }
    }
    
    // Table is being dragged
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Dismiss possible keyboard on search field
        self.nameFilterBar.endEditing(true)
        
        // Dismiss possible datepicker on date fields
        self.fromDateLabel.endEditing(true)
        self.toDateLabel.endEditing(true)
    }
    
    // Name filter changed
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.getAllEvents()
    }
    
    // When the from date UIDatePicker is set, update the label and filters
    @objc func fromDatePickerChanged(_ sender: UIDatePicker) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventDate: Date = sender.date
        
        let dateString: String = dateFormatter.string(from: eventDate)

        self.fromDateLabel.text = dateString
        self.fromDate = eventDate
        
        // Update Events
        self.getAllEvents()
    }
    
    // When the to date UIDatePicker is set, update the label and filters
    @objc func toDatePickerChanged(_ sender: UIDatePicker) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "MMM d, YYYY"
        
        let eventDate: Date = sender.date
        
        let dateString: String = dateFormatter.string(from: eventDate)
        
        self.toDateLabel.text = dateString
        self.toDate = eventDate
        
        // Update Events
        self.getAllEvents()
    }
    
    // Close the datepicker, when "Done" is tapped
    @objc func datePickerDone(_ sender: AnyObject) {
        // Dismiss datepicker on date fields
        self.fromDateLabel.endEditing(true)
        self.toDateLabel.endEditing(true)
        
        // Update Events
        self.getAllEvents()
    }
    
    // Get all events (filtered by date and text/name)
    func getAllEvents() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
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
        let currentCalendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        var fromDateComponents = (currentCalendar as NSCalendar).components(calendarUnits, from: self.fromDate!)
        
        fromDateComponents.hour = 0
        fromDateComponents.minute = 0
        fromDateComponents.second = 0
        
        self.fromDate = currentCalendar.date(from: fromDateComponents)
        
        // Make end date's time = 23:59:59
        var toDateComponents = (currentCalendar as NSCalendar).components(calendarUnits, from: self.toDate!)
        
        toDateComponents.hour = 23
        toDateComponents.minute = 59
        toDateComponents.second = 59
        
        self.toDate = currentCalendar.date(from: toDateComponents)
        
        //
        // Update search settings and search
        //
        
        self.updateSearchSettings()
        
        let usedPredicates = NSMutableArray()
        
        // Add dates to search
        let datesPredicate = NSPredicate(format: "(date >= %@) and (date <= %@)", self.fromDate! as CVarArg, self.toDate! as CVarArg)
        
        usedPredicates.add(datesPredicate)
        
        // Add any self.currentFilterName to search
        let filterNamePredicate: NSPredicate
        if ( self.nameFilterBar.text!.characters.count > 0 ) {
            filterNamePredicate = NSPredicate(format: "(name CONTAINS[cd] %@)", self.nameFilterBar.text!)
            
            usedPredicates.add(filterNamePredicate)
        }
        
        // Add the predicate to the request
        let finalPredicate: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:usedPredicates as AnyObject as! [NSPredicate])
        request.predicate = finalPredicate
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
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
        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        var shouldUpdateUI = false
        
        //
        // Dates
        //
        
        if let currentSearchFromDate = self.settings.value(forKey: "searchFromDate") as? Date {
            self.fromDate = currentSearchFromDate
            shouldUpdateUI = true
        }
        
        if let currentSearchToDate = self.settings.value(forKey: "searchToDate") as? Date {
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
        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        self.settings.setValue(self.fromDate, forKey: "searchFromDate")
        self.settings.setValue(self.toDate, forKey: "searchToDate")
    }
    
    // Update search labels & views
    func updateSearchLabelsAndViews() {
        let dateFormatter = DateFormatter()
        
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM d, yyyy", comment: "")
        
        // Set "from date" text view
        self.fromDateLabel.text = dateFormatter.string(from: self.fromDate!)
        
        // Set "to date" text view
        self.toDateLabel.text = dateFormatter.string(from: self.toDate!)
    }
    
    // Set from and to dates to the current month (first and last day)
    func setDefaultSearchDates() {
        let dateFormatter = DateFormatter()
        let currentDate = Date()
        let currentCalendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day]
        
        var dateComponents = (currentCalendar as NSCalendar).components(calendarUnits, from: currentDate)
        
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM d, yyyy", comment: "")
        
        //
        // Set "from date"
        //
        dateComponents.day = 1
        self.fromDate = currentCalendar.date(from: dateComponents)
        
        // Set "from date" text field
        self.fromDateLabel.text = dateFormatter.string(from: self.fromDate!)
        
        //
        // Set "to date"
        //
        let daysRange: NSRange = (currentCalendar as NSCalendar).range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: currentDate)
        dateComponents.day = daysRange.length// Last day of the current month
        
        self.toDate = currentCalendar.date(from: dateComponents)
        
        // Set "to date" text
        self.toDateLabel.text = dateFormatter.string(from: self.toDate!)
        
        // UI Updates
        updateSearchLabelsAndViews()
    }
    
    // Add a datepicker with the "Done" button to an input
    func addDatePickerToInput(_ inputShortName: String) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        datePickerView.backgroundColor = UIColor.white

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
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.white
        toolBar.sizeToFit()
        toolBar.frame.origin.y = -43
        
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment:""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(PastEventsViewController.datePickerDone(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        doneButton.tintColor = UIColor.black
        
        toolBar.setItems([spaceButton, doneButton], animated: true)
        toolBar.isUserInteractionEnabled = true
        doneButton.isEnabled = true
        
        if (inputShortName == "from") {
            self.fromDateLabel.inputAccessoryView = toolBar
            
            // Add the UIDatePicker to the view
            self.fromDateLabel.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(PastEventsViewController.fromDatePickerChanged(_:)), for: UIControl.Event.valueChanged)
        } else {
            self.toDateLabel.inputAccessoryView = toolBar
            
            // Add the UIDatePicker to the view
            self.toDateLabel.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(PastEventsViewController.toDatePickerChanged(_:)), for: UIControl.Event.valueChanged)
        }
    }
    
    // Dismiss keyboard or show date pickers as necessary, when the main view is touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Add main controller to editEvent view
        if (segue.identifier == "editEvent") {
            let viewController = segue.destination as! EditEventViewController
            viewController.listViewController = self
            
            // Set selected event
            viewController.selectedEvent = self.selectedEvent
        }
    }
    
    // Hide or show status bar as necessary
    override var prefersStatusBarHidden : Bool {
        return !self.statusBarShowing
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
}

