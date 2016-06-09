//
//  SettingsViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 21/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    var statusBarShowing: Bool = true
    
    var settings: NSUserDefaults!
    
    @IBOutlet weak var lastSyncLabel: UILabel!
    @IBOutlet weak var iCloudSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Update switch and sync label
        self.refreshViewWithSettings()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        self.view.frame.origin.y = 20// Move view to bottom
        
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
                        self.view.frame.origin.y = 0// Move view to top
                        
                        // Remove the view for the notification
                        toastView.removeFromSuperview()
                    }
                )
            }
        )
    }
    
    // Hide or show status bar as necessary
    override func prefersStatusBarHidden() -> Bool {
        return !self.statusBarShowing
    }
    
    // Load settings into view
    func refreshViewWithSettings() {
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
    
        NSLog("Refreshing view settings")
        
        let iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
        
        let isiCloudEnabled: Bool = iCloudSettings.valueForKey("isEnabled")!.isEqual(true) ? true : false
    
        //NSLog(@"iCloud Settings = %@", iCloudSettings);
        
        // iCloud switch
        if (isiCloudEnabled) {
            self.iCloudSwitch.on = true
        } else {
            self.iCloudSwitch.on = false
        }
        
        // Set sync text
        //var lastSyncStartDate: NSDate? = iCloudSettings.valueForKey("lastSyncStart") as! NSDate?
        let lastSyncEndDate: NSDate? = iCloudSettings.valueForKey("lastSuccessfulSync") as! NSDate?

        let dateFormatter: NSDateFormatter = NSDateFormatter()
        let locale: NSLocale = NSLocale(localeIdentifier: "en_US")
        dateFormatter.locale = locale
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = NSLocalizedString("yyyy.MM.dd HH:mm", comment:"")

        var formattedDate: NSString
        
        //NSLog("%@", iCloudSettings)
        
        if (lastSyncEndDate != nil) {
            formattedDate = dateFormatter.stringFromDate(lastSyncEndDate!)
        } else {
            formattedDate = NSLocalizedString("N/A", comment: "")
        }
            
        self.lastSyncLabel.text = formattedDate as String
    }
    
    // Formats the date for the CSV file
    func formatDateForCSV( date: NSDate ) -> NSString {
        let dateFormatter = NSDateFormatter()
        let locale = NSLocale(localeIdentifier: "en_US")
        
        dateFormatter.locale = locale
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let formattedDate = dateFormatter.stringFromDate(date)
        
        return formattedDate
    }
    
    // Get all events, for CSV
    func getAllEvents() -> [NSManagedObject] {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Event", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        // Sort expenses by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        return objects as! [NSManagedObject]
    }
    
    // Generate a CSV file content for all events
    func getCSVFileString() -> NSString {
        var fileContents: NSString = ""
        
        // Add Header
        fileContents = fileContents.stringByAppendingString("Name,Date")
        
        let events = self.getAllEvents()
        
        for event: NSManagedObject in events {
            // Parse the values for text from the received object
            var eventName: NSString = event.valueForKey("name")! as! NSString
            var eventDate = self.formatDateForCSV(event.valueForKey("date")! as! NSDate)
            
            // parse commas, new lines, and quotes for CSV
            eventName = eventName.stringByReplacingOccurrencesOfString(",", withString: ";")
            eventName = eventName.stringByReplacingOccurrencesOfString("\n", withString: " ")
            eventName = eventName.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            eventDate = eventDate.stringByReplacingOccurrencesOfString(",", withString: ";")
            eventDate = eventDate.stringByReplacingOccurrencesOfString("\n", withString: " ")
            eventDate = eventDate.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            let rowForEvent = NSString(format:"\n%@,%@", eventName, eventDate)
            
            // Append string to file contents
            fileContents = fileContents.stringByAppendingString(rowForEvent as String)
        }
        
        //NSLog("Final file contents:\n\n%@", fileContents);
        
        return fileContents;
    }
    
    // The iCloud Switch was tapped
    @IBAction func iCloudSwitchTapped(sender: AnyObject) {
        let switchView: UISwitch = sender as! UISwitch
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
        
        NSLog("Refreshing view settings")
        
        let iCloudSettings: NSMutableDictionary = self.settings.objectForKey("iCloud")!.mutableCopy() as! NSMutableDictionary
        
        if (switchView.on) {
            appDelegate.migrateDataToiCloud()
            
            iCloudSettings.setValue(true, forKey: "isEnabled")
            self.settings.setObject(iCloudSettings, forKey: "iCloud")
            
            self.showToast(NSLocalizedString("iCloud enabled", comment: ""), window: self.view.window!)
        } else {
            appDelegate.migrateDataToLocal()
            
            iCloudSettings.setValue(false, forKey: "isEnabled")
            self.settings.setObject(iCloudSettings, forKey: "iCloud")
            
            self.showToast(NSLocalizedString("iCloud disabled", comment: ""), window: self.view.window!)
        }
        
        // Update switch and sync label
        self.refreshViewWithSettings()
    }
    
    // Export CSV button pressed
    @IBAction func exportCSVButtonPressed(sender: AnyObject) {
        let textFileContentsString: NSString = self.getCSVFileString()
        let textFileContentsData: NSData = textFileContentsString.dataUsingEncoding(NSASCIIStringEncoding)!
        
        let csvFileName = NSString(format:"recordari-export-%d.csv", Int(NSDate().timeIntervalSince1970)) as String
        
        let emailSubject = NSLocalizedString("Recordari CSV Export", comment:"")
        let emailBody = NSLocalizedString("Enjoy this CSV file with my events data", comment:"")
        
        if (MFMailComposeViewController.canSendMail()) {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setSubject(emailSubject)
            mailComposeViewController.setMessageBody(emailBody, isHTML: false)
            mailComposeViewController.addAttachmentData(textFileContentsData, mimeType: "text/csv", fileName: csvFileName)
            mailComposeViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            
            presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showAlert(NSLocalizedString("It seems you don't have email configured on your iOS device. Please take care of that first.", comment: ""))
        }
    }
    
    // Hide controller once email is sent
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        NSLog("Finished sending email!")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Remove All Data button pressed
    @IBAction func removeAllDataButtonPressed(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let confirmRemove = UIAlertController( title: NSLocalizedString("Are you sure?", comment: ""), message: NSLocalizedString("This will remove all local & iCloud data for events", comment: ""), preferredStyle: UIAlertControllerStyle.Alert )
        
        // Confirmed!
        confirmRemove.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
            appDelegate.removeAllData()
            self.showToast(NSLocalizedString("All data removed!", comment: ""), window: self.view.window!)
        }))
        
        // Canceled!
        confirmRemove.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
            // Do nothing
        }))
        
        self.presentViewController(confirmRemove, animated: true, completion: nil)
    }
    
}

