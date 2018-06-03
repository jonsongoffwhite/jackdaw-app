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
        //var split = message.components(separatedBy: "/")
        var split = message.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
        print(split)
        self.type = String(split[0])
        split.remove(at: 0)
        print(split)
        self.args = String(split[0]).components(separatedBy: "+")
    }
    
    func execute() {
        if type == PULL_REQUEST {
            
        }
    }
    
}
