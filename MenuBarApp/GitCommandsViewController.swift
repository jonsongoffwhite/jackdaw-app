//
//  GitCommandsViewController.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 14/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

let ABLETON_PATH_EXTENSION = "als"

class GitCommandsViewController: NSViewController {
    
    @IBOutlet weak var projectName: NSTextField!
    @IBOutlet weak var status: NSTextField?
    @IBOutlet weak var refreshStatusButton: NSButton?
    
    var abletonLocation: String = "/Applications/Ableton Live 10 Suite.app"
    var abletonProjectFiles: [URL] = []
    
    var git: GitHandler?
    
    //TODO: Check it has .git subdir
    var directory: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let dir = directory {
            do {
                git = try GitHandler(for: dir)
                projectName.stringValue = String(dir.path.split(separator: "/").last!)
                projectName.stringValue += ", is Git: \(git!.isGitDirectory())"
                
                // Populate the abletonProjectFileNames variable
                let manager = FileManager.default
                do {
                    let files: [URL] = try manager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    
                    self.abletonProjectFiles = files.filter { (url) -> Bool in
                        return url.pathExtension == ABLETON_PATH_EXTENSION
                    }
                }
            
                
                
            } catch GitError.invalidRepoPath {
                // Path supplied is not a repository
                // Choose again
            } catch {
                // Other errors
            }
        }
    }
    
    @IBAction func commitChanges(_ sender: Any?) {
        do {
            let commit = try git!.commitAllChanges()
            self.status?.stringValue = commit.message
        } catch GitError.unableToCommitAll {
            self.status?.stringValue = "Unable to commit all"
        } catch {
            self.status?.stringValue = "Committing error"
        }
    }
    
    @IBAction func setRemote(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Please input the remote URL"
        let input = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
        alert.accessoryView = input
        alert.alertStyle = NSAlert.Style.informational
        alert.runModal()
        let repoURLString = input.stringValue
        let repoURL = URL(string: repoURLString)!
        git!.setRemote(with: repoURL)
    }
    
    @IBAction func push(_ sender: Any?) {
        // If remoteURL is set
        if let _ = git!.remoteURL {
            git!.pushToRemote()
        } else {
            print ("not set")
        }
    }
    
    @IBAction func openInAbleton(_ sender: Any?) {
        guard let directory = directory else {
            print("no directory set")
            return
        }
        let location = URL(fileURLWithPath: abletonLocation)
        //let launchConfig = [NSWorkspace.LaunchConfigurationKey.]
        do {
            try NSWorkspace.shared.open([abletonProjectFiles[0]], withApplicationAt: location, options: NSWorkspace.LaunchOptions.default, configuration: [:])
        } catch {
            print("failed to open directory with Ableton")
            print(error)
        }
        
    }
    
}
