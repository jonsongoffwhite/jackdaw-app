//
//  GitCommandsViewController.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 14/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

class GitCommandsViewController: NSViewController {
    
    @IBOutlet weak var projectName: NSTextField!
    @IBOutlet weak var abletonStatus: NSTextField?
    @IBOutlet weak var refreshStatusButton: NSButton?
    
    //TODO: Check it has .git subdir
    var directory: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        refreshStatusButton?.action = #selector(refreshStatus(_:))
        
        if let dir = directory {
            projectName.stringValue = String(dir.split(separator: "/").last!)
            projectName.stringValue += ", is Git: \(isGitDirectory())"
        }
        
    }
    
    /*
    ** Determines whether the provided directory is yet a git directory
    ** by checking for the existence of the .git hidden directory
    ** present in all git repositories
    */
    func isGitDirectory() -> Bool {
        guard let dir = directory else {
            return false
        }
        let manager = FileManager()
        return manager.fileExists(atPath: dir + "/.git")
    }
    
    @objc func refreshStatus(_ sender: Any?) {
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = []
        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        
        print(output)
    }
    
}
