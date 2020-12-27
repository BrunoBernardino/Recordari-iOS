//
//  StatsViewController.swift
//  Recordari
//
//  Created by Bruno Bernardino on 12/11/16.
//  Copyright (c) 2016 Bruno Bernardino. All rights reserved.
//

import UIKit
import CoreData

class StatsViewController: UIViewController {
    
    @IBOutlet weak var wrapperView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Always adopt a light interface style on iOS 13
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        // Draw fresh stats on screen
        self.refreshUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Draw fresh stats on screen
        self.refreshUI()
    }
    
    func refreshUI() {
        // Cleanup wrapperView
        for view in self.wrapperView.subviews {
            view.removeFromSuperview()
        }
        
        // Get top 5 events and their frequency for the last year
        self.getEventsAndFrequency()
    }
    
    // Get top 5 events and their frequency for the last year
    func getEventsAndFrequency() {
        let events = self.getTopEvents()
        let frequencies = self.getEventFrequencies(events: events)
        
        var rowIndex = 0
        
        // Add them to self.wrapperView
        for event in events {
            let eventName = (event as AnyObject).value(forKey: "name") as! String
            let eventFrequencies = frequencies.value(forKey: eventName) as! Array<String>
            let eventLastLog = eventFrequencies[0]
            let eventFrequency = eventFrequencies[1]

            let view = self.createStatView(eventName: eventName, eventFrequency: eventFrequency, eventLastLog: eventLastLog, rowIndex: rowIndex)
            self.wrapperView.addSubview(view)
            
            rowIndex += 1
        }
    }
    
    // Get top 5 events
    func getTopEvents() -> NSArray {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Group by Name, with .count
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        let countExpressionArguments = [NSExpression(forKeyPath: "name")]
        let countExpression = NSExpression(forFunction: "count:", arguments: countExpressionArguments)
        
        let countExpressionDescription = NSExpressionDescription()
        countExpressionDescription.expression = countExpression
        countExpressionDescription.name = "count"
        countExpressionDescription.expressionResultType = NSAttributeType.integer64AttributeType
        
        request.propertiesToFetch = ["name", countExpressionDescription]
        request.propertiesToGroupBy = ["name"]
        
        // Fetch 100 at most
        request.fetchLimit = 100
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
            return objects
        }
        
        // Sort by count
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "count", ascending: false)
        objects = (objects.sortedArray(using: [sortDescriptor]) as NSArray?)!
        
        // Return only top 7 elements at most
        if (objects.count > 7) {
            // TODO: This should really just be a swift array to be able to do nicer stuff
            return [
                objects[0],
                objects[1],
                objects[2],
                objects[3],
                objects[4],
                objects[5],
                objects[6]
            ]
        }
        
        return objects
    }
    
    func getEventFrequencies(events: NSArray) -> NSDictionary {
        let frequencies: NSMutableDictionary = [:]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Event", in:context!)

        for event in events {
            let eventName = (event as AnyObject).value(forKey: "name") as! String
            let eventCount = (event as AnyObject).value(forKey: "count") as! Int
            
            // Get 1 year ago
            let today: Date = Date()
            let minDate: Date = (Calendar.current.date(byAdding: .year, value: -1, to: today) as Date?)!

            // Get the latest date for this event
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = entityDesc
            request.resultType = NSFetchRequestResultType.dictionaryResultType
            request.fetchLimit = 1
            let predicate =  NSPredicate(format:"name == %@", eventName)
            request.predicate = predicate
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            
            let error: NSError? = nil
            let objects = try! context!.fetch(request) as [AnyObject]
            
            if ( error != nil ) {
                return frequencies
            }

            let maxDate = (objects.first as AnyObject).value(forKey: "date") as! Date
            
            //
            // Calculate frequencies
            //
            
            var daysDifference = self.getDifferenceInDaysForDates(firstDate: minDate, secondDate: today)
            if (daysDifference == 0) {
                daysDifference = 1
            }
            
            // We want positive only!
            if (daysDifference < 0) {
                daysDifference = daysDifference * -1
            }
            
            // Add min/max date to frequencies
            var finalFrequency = "N/A"
            let frequencyPerDay = (Float(eventCount) / Float(daysDifference))
            NSLog("Min date for %@: %@", eventName, minDate.description)
            NSLog("Max date for %@: %@", eventName, maxDate.description)
            NSLog("Total count for %@: %d", eventName, eventCount)
            NSLog("Total days difference for %@: %d", eventName, daysDifference)
            NSLog("Frequency per day for %@: %f", eventName, frequencyPerDay)
            
            // If it happens less than once per day, let's try weekly
            if (frequencyPerDay < 1) {
                let frequencyPerWeek = (Float(eventCount) / (Float(daysDifference) / 7))
                NSLog("Frequency per week for %@: %f", eventName, frequencyPerWeek)
                
                // If it happens less than once per week, let's try monthly
                if (frequencyPerWeek < 1) {
                    let frequencyPerMonth = (Float(eventCount) / (Float(daysDifference) / 30))
                    NSLog("Frequency per month for %@: %f", eventName, frequencyPerMonth)

                    // If it happens less than once per month, let's try yearly
                    if (frequencyPerMonth < 1) {
                        let frequencyPerYear = (Float(eventCount) / (Float(daysDifference) / 365))
                        NSLog("Frequency per year for %@: %f", eventName, frequencyPerYear)

                        finalFrequency = String(format: "%.2f", frequencyPerYear) + " / year"
                    } else {
                        finalFrequency = String(format: "%.2f", frequencyPerMonth) + " / month"
                    }
                } else {
                    finalFrequency = String(format: "%.2f", frequencyPerWeek) + " / week"
                }
            } else {
                finalFrequency = String(format: "%.2f", frequencyPerDay) + " / day"
            }
            
            NSLog("Final frequency for %@: %@", eventName, finalFrequency)
            
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.dateFormat = "MMM d, YYYY"
            
            let lastLog: String = dateFormatter.string(from: maxDate)
            
            frequencies.setValue([lastLog, finalFrequency], forKey: eventName)
        }
        
        return frequencies as NSDictionary
    }
    
    func getDifferenceInDaysForDates(firstDate: Date, secondDate: Date) -> Int {
        let calendar = NSCalendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: firstDate)
        let date2 = calendar.startOfDay(for: secondDate)
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        
        return components.day ?? 0
    }
    
    func createStatView(eventName: String, eventFrequency: String, eventLastLog: String, rowIndex: Int) -> UIView {
        let fullWidth = Int(self.wrapperView.frame.size.width)
        let thirdWidth = Int(Double(fullWidth) / 3)
        let height = 30
        let yPos = rowIndex * height + 5
        let frame = CGRect(x: 0, y: yPos, width: fullWidth, height: height)
        let nameFrame = CGRect(x: 0, y: yPos, width: fullWidth, height: height)
        let frequencyFrame = CGRect(x: thirdWidth, y: yPos, width: thirdWidth, height: height)
        let lastLogFrame = CGRect(x: thirdWidth * 2, y: yPos, width: thirdWidth, height: height)
        var labelFont = UIFont(name: "System Light", size: 15)
        if #available(iOS 8.2, *) {
            labelFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)
        }
        let statView = UIView(frame: frame)
        
        //
        // Append labels
        //

        let nameLabel = UILabel(frame: nameFrame)
        nameLabel.text = eventName
        nameLabel.font = labelFont
        nameLabel.textAlignment = NSTextAlignment.left
        statView.addSubview(nameLabel)
        
        let frequencyLabel = UILabel(frame: frequencyFrame)
        frequencyLabel.text = eventFrequency
        frequencyLabel.font = labelFont
        frequencyLabel.textAlignment = NSTextAlignment.center
        statView.addSubview(frequencyLabel)
        
        let lastLogLabel = UILabel(frame: lastLogFrame)
        lastLogLabel.text = eventLastLog
        lastLogLabel.font = labelFont
        lastLogLabel.textAlignment = NSTextAlignment.right
        statView.addSubview(lastLogLabel)
        
        return statView
    }
    
}

