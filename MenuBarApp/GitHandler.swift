//
//  GitHandler.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 16/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation

class GitHandler {
    
    var directory: String
    
    init(for directory: String) {
        self.directory = directory
    }
    
    /*
     ** Determines whether the provided directory is yet a git directory
     ** by checking for the existence of the .git hidden directory
     ** present in all git repositories
     */
    func isGitDirectory() -> Bool {
        let manager = FileManager()
        return manager.fileExists(atPath: directory + "/.git")
    }
    
    func status() -> String {
        return ""
    }
    
}
