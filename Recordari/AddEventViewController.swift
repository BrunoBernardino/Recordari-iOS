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

    @IBOutlet weak var addEventButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Always adopt a light interface style on iOS 13
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.nameTextField.delegate = self
        
        // Make sure the buttons will work for shorter screens
        if (self.view.frame.height <= 568) {
            // TODO: moving to front view, changing layout, etc. just doesn't work.
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // Add an event
    @IBAction func addEvent(_ sender: AnyObject) {
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
            self.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the event.", comment:""))
            
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
            // Cleanup fields
            self.nameTextField.text = ""
            self.datePicker.date = Date()

            // Show toast
            self.mainViewController.showToast(NSLocalizedString("Event added.", comment:""), window: self.view.window!)

            // Go back
            self.dismiss(animated: true, completion: nil)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.showAlert(NSLocalizedString("There was an error adding your event. Please confirm the name and date are correct.", comment:""))
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

