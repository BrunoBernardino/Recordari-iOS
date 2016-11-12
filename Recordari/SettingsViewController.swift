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
    
    var settings: UserDefaults!
    
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
    func showAlert(_ message: String) {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: "Recordari", message:
                message, preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Show "toast"
    func showToast(_ message: String, window: UIWindow) {
        // Hide status bar
        self.statusBarShowing = false
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.frame.origin.y = 20// Move view to bottom
        
        // Create view for the notification
        let toastView = UIView(frame: CGRect(x: 0, y: -20, width: window.frame.size.width, height: 20))
        
        // Set properties of the view
        toastView.backgroundColor = UIColor.black
        
        // Create label with text and properties
        let labelView = UILabel(frame: CGRect(x: 0, y: 0, width: window.frame.size.width, height: 20))
        labelView.text = message
        labelView.textColor = UIColor.white
        labelView.textAlignment = NSTextAlignment.center
        labelView.font = UIFont(name: "System-Light", size: 10)
        
        // Add label to view
        toastView.addSubview(labelView)
        
        // Add view to window
        window.addSubview(toastView)
        
        // Animate view entrance
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut
            , animations: {
                toastView.frame.origin.y = 0
            }, completion: {
                (finished: Bool) -> Void in
                
                // Animate view exit
                UIView.animate(withDuration: 0.3, delay: 1.5, options: UIViewAnimationOptions.curveEaseOut
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
    override var prefersStatusBarHidden : Bool {
        return !self.statusBarShowing
    }
    
    // Load settings into view
    func refreshViewWithSettings() {
        self.settings = UserDefaults.standard
        self.settings.synchronize()
    
        NSLog("Refreshing view settings")
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
        
        let isiCloudEnabled: Bool = (iCloudSettings.value(forKey: "isEnabled")! as AnyObject).isEqual(true) ? true : false
        
        // iCloud switch
        if (isiCloudEnabled) {
            self.iCloudSwitch.isOn = true
        } else {
            self.iCloudSwitch.isOn = false
        }
        
        // Set sync text
        let lastSyncEndDate: Date? = iCloudSettings.value(forKey: "lastSuccessfulSync") as! Date?

        let dateFormatter: DateFormatter = DateFormatter()
        let locale: Locale = Locale(identifier: "en_US")
        dateFormatter.locale = locale
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = NSLocalizedString("yyyy.MM.dd HH:mm", comment:"")

        var formattedDate: NSString
        
        if (lastSyncEndDate != nil && isiCloudEnabled) {
            formattedDate = dateFormatter.string(from: lastSyncEndDate!) as NSString
        } else {
            formattedDate = NSLocalizedString("N/A", comment: "") as NSString
        }
            
        self.lastSyncLabel.text = formattedDate as String
    }
    
    // Formats the date for the CSV file
    func formatDateForCSV( _ date: Date ) -> NSString {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US")
        
        dateFormatter.locale = locale
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let formattedDate = dateFormatter.string(from: date)
        
        return formattedDate as NSString
    }
    
    // Get all events, for CSV
    func getAllEvents() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Sort expenses by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
        }
        
        return objects as! [NSManagedObject]
    }
    
    // Generate a CSV file content for all events
    func getCSVFileString() -> NSString {
        var fileContents: NSString = ""
        
        // Add Header
        fileContents = fileContents.appending("Name,Date") as NSString
        
        let events = self.getAllEvents()
        
        for event: NSManagedObject in events {
            // Parse the values for text from the received object
            var eventName: NSString = event.value(forKey: "name")! as! NSString
            var eventDate = self.formatDateForCSV(event.value(forKey: "date")! as! Date)
            
            // parse commas, new lines, and quotes for CSV
            eventName = eventName.replacingOccurrences(of: ",", with: ";") as NSString
            eventName = eventName.replacingOccurrences(of: "\n", with: " ") as NSString
            eventName = eventName.replacingOccurrences(of: "\"", with: "'") as NSString
            
            eventDate = eventDate.replacingOccurrences(of: ",", with: ";") as NSString
            eventDate = eventDate.replacingOccurrences(of: "\n", with: " ") as NSString
            eventDate = eventDate.replacingOccurrences(of: "\"", with: "'") as NSString
            
            let rowForEvent = NSString(format:"\n%@,%@", eventName, eventDate)
            
            // Append string to file contents
            fileContents = fileContents.appending(rowForEvent as String) as NSString
        }
        
        //NSLog("Final file contents:\n\n%@", fileContents);
        
        return fileContents;
    }
    
    // The iCloud Switch was tapped
    @IBAction func iCloudSwitchTapped(_ sender: AnyObject) {
        let switchView: UISwitch = sender as! UISwitch
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        NSLog("Refreshing view settings")
        
        let iCloudSettings: NSMutableDictionary = NSMutableDictionary(dictionary: (self.settings.object(forKey: "iCloud") as! NSDictionary).mutableCopy() as! NSMutableDictionary)
        
        if (switchView.isOn) {
            appDelegate.migrateDataToiCloud()
            
            iCloudSettings.setValue(true, forKey: "isEnabled")
            self.settings.set(iCloudSettings, forKey: "iCloud")
            
            self.showToast(NSLocalizedString("iCloud enabled", comment: ""), window: self.view.window!)
        } else {
            appDelegate.migrateDataToLocal()
            
            iCloudSettings.setValue(false, forKey: "isEnabled")
            self.settings.set(iCloudSettings, forKey: "iCloud")
            
            self.showToast(NSLocalizedString("iCloud disabled", comment: ""), window: self.view.window!)
        }
        
        // Update switch and sync label
        self.refreshViewWithSettings()
    }
    
    // Export CSV button pressed
    @IBAction func exportCSVButtonPressed(_ sender: AnyObject) {
        let textFileContentsString: NSString = self.getCSVFileString()
        let textFileContentsData: Data = textFileContentsString.data(using: String.Encoding.ascii.rawValue)!
        
        let csvFileName = NSString(format:"recordari-export-%d.csv", Int(Date().timeIntervalSince1970)) as String
        
        let emailSubject = NSLocalizedString("Recordari CSV Export", comment:"")
        let emailBody = NSLocalizedString("Enjoy this CSV file with my events data", comment:"")
        
        if (MFMailComposeViewController.canSendMail()) {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setSubject(emailSubject)
            mailComposeViewController.setMessageBody(emailBody, isHTML: false)
            mailComposeViewController.addAttachmentData(textFileContentsData, mimeType: "text/csv", fileName: csvFileName)
            mailComposeViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            
            present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showAlert(NSLocalizedString("It seems you don't have email configured on your iOS device. Please take care of that first.", comment: ""))
        }
    }
    
    // Hide controller once email is sent
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        NSLog("Finished sending email!")
        self.dismiss(animated: true, completion: nil)
    }
    
    // Remove All Data button pressed
    @IBAction func removeAllDataButtonPressed(_ sender: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if #available(iOS 8.0, *) {
            let confirmRemove = UIAlertController( title: NSLocalizedString("Are you sure?", comment: ""), message: NSLocalizedString("This will remove all local & iCloud data for events", comment: ""), preferredStyle: UIAlertControllerStyle.alert )
            
            // Confirmed!
            confirmRemove.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
                appDelegate.removeAllData()
                self.showToast(NSLocalizedString("All data removed!", comment: ""), window: self.view.window!)
            }))
            
            // Canceled!
            confirmRemove.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: { (action: UIAlertAction) in
                // Do nothing
            }))
            
            self.present(confirmRemove, animated: true, completion: nil)
        }
    }
    
}

