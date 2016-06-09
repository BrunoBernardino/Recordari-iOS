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
    
    var session: WCSession!
    var topEvents: Array<String>! = []

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.updateInterface()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("CLICKED: %@", self.topEvents[rowIndex])
        self.addEvent(self.topEvents[rowIndex])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateInterface() {
        if (topEvents?.count == 0) {
            self.addLabel.setText("No Top Events")
            self.topEvents = ["Smoke", "Cat Pee", "Test"]
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
    
    func setTimeout(delay:NSTimeInterval, block:()->Void) -> NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(delay, target: NSBlockOperation(block: block), selector: #selector(NSOperation.main), userInfo: nil, repeats: false)
    }
    
    func addEvent(eventName: String) {
        if (session.reachable) {
            NSLog("SESSION IS REACHABLE")
            
            let message = ["event": eventName]
            
            session.sendMessage(message, replyHandler: { reply in
                self.addLabel.setText("# Event Added #")

                // Change back after 3 seconds
                self.setTimeout(3, block: {
                    self.addLabel.setText("Tap to Add Event")
                })
                }, errorHandler: { error in
                    print("error: \(error)")
            })
        } else {
            // we aren't in range of the phone, they didn't bring it on their run
            NSLog("SESSION IS NOT REACHABLE")
        }
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]){
        let topEvents : Array<String> = applicationContext["topEvents"] as! Array<String>
        
        NSLog("JUST ABOUT RECEIVED EVENTS")
        self.topEvents = topEvents
        
        self.updateInterface()
    }

}
