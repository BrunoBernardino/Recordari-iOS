//
//  EventBoxView.swift
//  Recordari
//
//  Created by Bruno Bernardino on 21/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit

class EventBoxView: UIView {
    
    var name: String = ""
    var buttonText: String = "..."
    var button: UIButton!
    var topOffset: CGFloat = 0
    var bottomOffset: CGFloat = 0
    
    init(frame aRect: CGRect, topOffset: CGFloat, bottomOffset: CGFloat) {
        super.init(frame:aRect)
        
        self.topOffset = topOffset
        self.bottomOffset = bottomOffset
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder:decoder)
    }

    func showButton() {
        var buttonRect: CGRect? = nil
        
        if (self.topOffset > 0) {
            buttonRect = CGRectMake(0, self.topOffset, self.frame.size.width, (self.frame.size.height - self.topOffset))
        }
        
        if (self.bottomOffset > 0) {
            buttonRect = CGRectMake(0, 0, self.frame.size.width, (self.frame.size.height - self.bottomOffset * 2))
        }
        
        if (buttonRect == nil) {
            buttonRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
        }
        
        // Add button to the center of the box
        self.button = UIButton(frame:buttonRect!)
        self.button.setTitle(self.buttonText, forState: UIControlState.Normal)

        // If the label is the default one, make the text gray, otherwise black
        if (self.buttonText == "...") {
            self.button.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        } else {
            self.button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        }
        
        self.button.clipsToBounds = true
        self.button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightLight)
        
        self.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).CGColor
        self.layer.borderWidth = 0.5
        
        // Autolayout weirdness?
        if (self.layer.frame.width > 195) {
            self.layer.position.x -= 4
        }
        
        self.addSubview(self.button)
    }
}

