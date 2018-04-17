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
    
    var git: GitHandler?
    
    //TODO: Check it has .git subdir
    var directory: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let dir = directory {
            git = GitHandler(for: dir)
            projectName.stringValue = String(dir.split(separator: "/").last!)
            projectName.stringValue += ", is Git: \(git!.isGitDirectory())"
        }
        
    }
    
    @IBAction func refreshStatus(_ sender: Any?) {
        print(git!.status())
    }
    
}
