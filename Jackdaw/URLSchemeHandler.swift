//
//  URLSchemeHandler.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 23/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

let PULL_REQUEST = "pr"

import Foundation

class URLSchemeHandler {
    
    var type: String
    var args: [String]
    
    init(message: String) {
        var split = message.components(separatedBy: "/")
        self.type = split[0]
        self.args = split[1].components(separatedBy: "+")
    }
    
    func execute() {
        if type == PULL_REQUEST {
            
        }
    }
    
}
