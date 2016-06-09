//
//  AddEventViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 22/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData

class AddEventViewController: UIViewController, UITextFieldDelegate {
    
    var mainViewController: MainViewController!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // Add an event
    @IBAction func addEvent(sender: AnyObject) {
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
            self.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the event.", comment:""))
            
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
            // Cleanup fields
            self.nameTextField.text = ""
            self.datePicker.date = NSDate()

            // Show toast
            self.mainViewController.showToast(NSLocalizedString("Event added.", comment:""), window: self.view.window!)

            // Go back
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.showAlert(NSLocalizedString("There was an error adding your event. Please confirm the name and date are correct.", comment:""))
        }
    }
    
    // Cancel button was tapped
    @IBAction func cancelTapped(sender: AnyObject) {
        // Go back
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // Dismiss keyboard on touch outside
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.nameTextField.endEditing(true)
    }
    
    // Dismiss keyboard on pressing done
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        
        return true
    }
}

