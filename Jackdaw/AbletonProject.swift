//
//  AbletonProject.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 30/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation
import Cocoa

class AbletonProject {
    
    var directory: URL
    var projectFiles: [URL]
    
    init(directory: URL) {
        self.directory = directory
        
        // Populate projectFiles
        let manager = FileManager.default
        let files: [URL] = try! manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        self.projectFiles = files.filter { (url) -> Bool in
            return url.pathExtension == ABLETON_PATH_EXTENSION
        }
    }
    
    // Gets URL for a string that is a relative path from the directory
    func getURLFromString(str: String) -> URL {
        var url: URL = directory
        let split = str.split(separator: "/")
        for sub in split {
            url = url.appendingPathComponent(String(sub))
        }
        return url
    }
    
    func open(projectURL: URL) {
        NSWorkspace.shared.open(projectURL)
    }
    
}
