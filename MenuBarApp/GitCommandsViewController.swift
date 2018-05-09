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
    @IBOutlet weak var status: NSTextField?
    @IBOutlet weak var refreshStatusButton: NSButton?
    
    var git: GitHandler?
    
    //TODO: Check it has .git subdir
    var directory: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let dir = directory {
            do {
                git = try GitHandler(for: dir)
                projectName.stringValue = String(dir.split(separator: "/").last!)
                projectName.stringValue += ", is Git: \(git!.isGitDirectory())"
            } catch GitError.invalidRepoPath {
                // Path supplied is not a repository
                // Choose again
            } catch {
                // Other errors
            }
        }
    }
    
    @IBAction func refreshStatus(_ sender: Any?) {
        do {
            let commit = try git!.commitAllChanges()
            self.status?.stringValue = commit.message
        } catch GitError.unableToCommitAll {
            self.status?.stringValue = "Unable to commit all"
        } catch {
            self.status?.stringValue = "Committing error"
        }
    }
    
}
