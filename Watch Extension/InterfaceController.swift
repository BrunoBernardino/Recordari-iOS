//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Bruno Bernardino on 09/06/16.
//  Copyright © 2016 Bruno Bernardino. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var addLabel: WKInterfaceLabel!
    @IBOutlet var eventsTable: WKInterfaceTable!
    
    var watchSession: WCSession?
    var topEvents: Array<String>! = []

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.updateInterface()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("TAPPED: %@", self.topEvents[rowIndex])
        self.addEvent(self.topEvents[rowIndex])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if (WCSession.isSupported()) {
            watchSession = WCSession.defaultSession()
            watchSession!.delegate = self
            watchSession!.activateSession()
            
            self.requestTopEvents()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateInterface() {
        NSLog("Updating UI...")

        if (topEvents?.count == 0) {
            self.addLabel.setText("No Events Found")
            self.topEvents = ["Test"]// TODO: Remove
        } else {
            self.addLabel.setText("Tap to Add Event")
        }
        
        // Configure interface objects here.
        eventsTable.setNumberOfRows((topEvents?.count)!, withRowType: "EventsTableRowController")
        for (index, eventName) in topEvents.enumerate() {
            let row = eventsTable.rowControllerAtIndex(index) as! EventsTableRowController
            row.label.setText(eventName)
        }
    }
    
    // Ask iOS App to get Top Events
    func requestTopEvents() {
        if (watchSession!.reachable) {
            let message = ["request": "topEvents"]
            
            self.addLabel.setText("# Loading... #")
            
            watchSession!.sendMessage(message, replyHandler: { reply in
                self.topEvents = reply["topEvents"] as! Array<String>
                
                // Update, in a non-GCD thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSelector(#selector(InterfaceController.updateInterface), withObject: nil, afterDelay: 0.0)
                })
                
                }, errorHandler: { error in
                    self.addLabel.setText("# Failed Loading #")
                    print("error: \(error)")
            })
        } else {
            // we aren't in range of the phone, they didn't bring it on their run
            NSLog("SESSION IS NOT REACHABLE")
        }
    }
    
    // Ask iOS App to add event
    func addEvent(eventName: String) {
        if (watchSession!.reachable) {
            let message = ["event": eventName]
            
            watchSession!.sendMessage(message, replyHandler: { reply in
                self.addLabel.setText("# Event Added #")

                // Update after 3 seconds
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSelector(#selector(InterfaceController.updateInterface), withObject: nil, afterDelay: 3.0)
                })

                }, errorHandler: { error in
                    print("error: \(error)")
            })
        } else {
            // we aren't in range of the phone, they didn't bring it on their run
            NSLog("SESSION IS NOT REACHABLE")
        }
    }

}
