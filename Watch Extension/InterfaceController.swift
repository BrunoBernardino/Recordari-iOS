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

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    @IBOutlet var addLabel: WKInterfaceLabel!
    @IBOutlet var eventsTable: WKInterfaceTable!
    
    var watchSession: WCSession?
    var topEvents: Array<String>! = []
    var lastLoad: Date! = Date()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.updateInterface()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        //NSLog("TAPPED: %@", self.topEvents[rowIndex])
        self.addEvent(self.topEvents[rowIndex])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let oneDayAgo: Date = Date().addingTimeInterval(86400)
        
        if (WCSession.isSupported()) {
            watchSession = WCSession.default
            watchSession!.delegate = self
            watchSession!.activate()
            
            NSLog("Last Load date = %@", lastLoad.description)
            
            // Only request new events if the lastLoad has been done more than a day ago or if there are less than 5 events
            if (lastLoad <= oneDayAgo || topEvents.count < 5) {
                self.requestTopEvents()
                
                // Save new load date
                lastLoad = Date()
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @objc func updateInterface() {
        NSLog("Updating UI...")

        if (topEvents?.count == 0) {
            self.addLabel.setText("No Events Found")
            self.topEvents = ["Test"]// TODO: Remove
        } else {
            self.addLabel.setText("Tap to Add Event")
        }
        
        // Configure interface objects here.
        eventsTable.setNumberOfRows((topEvents?.count)!, withRowType: "EventsTableRowController")
        for (index, eventName) in topEvents.enumerated() {
            let row = eventsTable.rowController(at: index) as! EventsTableRowController
            row.label.setText(eventName)
        }
    }
    
    // Ask iOS App to get Top Events
    func requestTopEvents() {
        if (watchSession!.isReachable) {
            let message = ["request": "topEvents"]
            
            self.addLabel.setText("# Loading... #")
            
            watchSession!.sendMessage(message, replyHandler: { reply in
                self.topEvents = reply["topEvents"] as! Array<String>
                
                // Update, in a non-GCD thread
                DispatchQueue.main.async(execute: {
                    self.perform(#selector(InterfaceController.updateInterface), with: nil, afterDelay: 0.0)
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
    func addEvent(_ eventName: String) {
        if (watchSession!.isReachable) {
            self.addLabel.setText("# Adding Event #")

            let message = ["event": eventName]
            
            watchSession!.sendMessage(message, replyHandler: { reply in
                self.addLabel.setText("# Event Added #")

                // Update after 3 seconds
                DispatchQueue.main.async(execute: {
                    self.perform(#selector(InterfaceController.updateInterface), with: nil, afterDelay: 3.0)
                })

                }, errorHandler: { error in
                    print("error: \(error)")
            })
        } else {
            // we aren't in range of the phone, they didn't bring it on their run
            NSLog("SESSION IS NOT REACHABLE")
            self.addLabel.setText("# Can't Reach Phone #")
        }
    }

}
