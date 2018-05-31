//
//  JackButton.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 30/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation
import Cocoa

class JackButton: NSButton {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.bezelStyle = .smallSquare
        self.font = NSFont(name: "Futura", size: 12)
    }
    
}
