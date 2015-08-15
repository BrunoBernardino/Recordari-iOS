//
//  EditEventViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 27/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData

class EditEventViewController: UIViewController, UITextFieldDelegate {
    
    var listViewController: PastEventsViewController!
    
    var selectedEvent: NSManagedObject!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameTextField.delegate = self
        
        // Fill up the fields with the data sent over
        self.nameTextField.text = self.selectedEvent.valueForKey("name") as! String
        self.datePicker.date = self.selectedEvent.valueForKey("date") as! NSDate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // Update the event
    @IBAction func updateEvent(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        var eventName: NSString = ""
        var eventDate: NSDate = NSDate()// Default event date to "now"
        
        // Avoid empty values crashing the code
        if let tmpEventName: NSString = self.nameTextField.text as NSString? {
            eventName = tmpEventName
        }
        if let tmpEventDate: NSDate = self.datePicker.date as NSDate? {
            eventDate = tmpEventDate
        }
        
        NSLog("VALUES = %@, %@", eventName, eventDate)
        
        //
        // START: Validate fields for common errors
        //

        // Check if the event name is not empty
        if ( eventName.length <= 0 ) {
            self.listViewController.showAlert(NSLocalizedString("Please confirm the name of the event.", comment:""))
            
            return
        }
        
        //
        // END: Validate fields for common errors
        //
        
        //
        // Save object
        //
        
        self.selectedEvent!.setValue(eventName, forKey: "name")
        self.selectedEvent!.setValue(eventDate, forKey: "date")
        
        var error: NSError? = nil
        context?.save(&error)
        
        if (error == nil) {
            // Show toast
            self.listViewController.showToast(NSLocalizedString("Event updated.", comment:""), window: self.view.window!)

            // Reload data/views
            self.listViewController.getAllEvents()

            // Go back
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            NSLog("Error: %@", error!)
            
            self.listViewController.showAlert(NSLocalizedString("There was an error updating your event. Please confirm the name and date are correct.", comment:""))
        }
    }

    // Cancel button was tapped
    @IBAction func cancelTapped(sender: AnyObject) {
        // Go back
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // Dismiss keyboard on touch outside
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.nameTextField.endEditing(true)
    }
    
    // Dismiss keyboard on pressing done
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        
        return true
    }
}

