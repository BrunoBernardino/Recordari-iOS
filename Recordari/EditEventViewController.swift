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
        
        // Always adopt a light interface style on iOS 13
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.nameTextField.delegate = self
        
        // Fill up the fields with the data sent over
        self.nameTextField.text = self.selectedEvent.value(forKey: "name") as? String
        self.datePicker.date = self.selectedEvent.value(forKey: "date") as! Date
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // Update the event
    @IBAction func updateEvent(_ sender: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        // Set defaults
        var eventName: NSString = ""
        var eventDate: Date = Date()// Default event date to "now"
        
        // Avoid empty values crashing the code
        if let tmpEventName: NSString = self.nameTextField.text as NSString? {
            eventName = tmpEventName
        }
        if let tmpEventDate: Date = self.datePicker.date as Date? {
            eventDate = tmpEventDate
        }
        
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
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if (error == nil) {
            // Show toast
            self.listViewController.showToast(NSLocalizedString("Event updated.", comment:""), window: self.view.window!)

            // Reload data/views
            self.listViewController.getAllEvents()

            // Go back
            self.dismiss(animated: true, completion: nil)
        } else {
            NSLog("Error: %@", error!)
            
            self.listViewController.showAlert(NSLocalizedString("There was an error updating your event. Please confirm the name and date are correct.", comment:""))
        }
    }

    // Cancel button was tapped
    @IBAction func cancelTapped(_ sender: AnyObject) {
        // Go back
        self.dismiss(animated: true, completion: nil)
    }

    // Dismiss keyboard on touch outside
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.nameTextField.endEditing(true)
    }
    
    // Dismiss keyboard on pressing done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        
        return true
    }
}

