//
//  EventTableCell.swift
//  Recordari
//
//  Created by Bruno Bernardino on 22/07/15.
//  Copyright (c) 2015 Bruno Bernardino. All rights reserved.
//

import UIKit

class EventTableCell: UITableViewCell {
    
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventDateLabel: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

