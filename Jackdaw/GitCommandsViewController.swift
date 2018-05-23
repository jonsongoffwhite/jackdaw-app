//
//  GitCommandsViewController.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 14/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa
import ObjectiveGit

let ABLETON_PATH_EXTENSION = "als"

// Make GitHandler the delegate for the other ViewControllers directly

class GitCommandsViewController: NSViewController {
    
    @IBOutlet weak var projectName: NSTextField!
    @IBOutlet weak var currentBranch: NSTextField?
    @IBOutlet weak var commitChangesButton: NSButton?
    @IBOutlet weak var projectFileDropdown: NSPopUpButton!
    @IBOutlet weak var mergeBranchDropdown: NSPopUpButton!
    
    var abletonLocation: String = "/Applications/Ableton Live 10 Suite.app"
    var abletonProjectFiles: [URL] = []
    
    var git: GitHandler!
    
    //TODO: Check it has .git subdir
    var directory: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let dir = directory {
            do {
                git = try GitHandler(for: dir)
                projectName.stringValue = String(dir.path.split(separator: "/").last!)
                projectName.stringValue += ", is Git: \(git.isGitDirectory())"
                
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
                return
            } catch {
                // Other errors
                return
            }
        }
        
        // Show branch
        let currentBranch = git.getCurrentBranch()
        if let currentBranch = currentBranch {
            self.currentBranch?.stringValue = currentBranch
        }
        
        // populate projectFileDropdown
        self.projectFileDropdown.addItems(withTitles: abletonProjectFiles.map({ (url) -> String in
                return url.lastPathComponent
            })
        )
        
        // populate mergeBranchDropDown
        let menu = NSMenu(title: "mergeBranchesMenu")
        git.getBranches().forEach { (branch) in
            let name = branch.name != nil ? branch.name! : "unnamed branch"
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            item.representedObject = branch
            menu.addItem(item)
        }
        mergeBranchDropdown.menu = menu
        
        // Inject merge driver
        git.injectMergeDriver()
        
        // Register merge driver
        //init_als_merge_driver()
            
        
    }
    
    @IBAction func commitChanges(_ sender: Any?) {
        
        let vc = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "commit")) as! CommitViewController
        
        vc.delegate = self
        self.presentViewControllerAsSheet(vc)
        
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
        let _ = git.setRemote(with: repoURL)
    }
    
    @IBAction func push(_ sender: Any?) {
        // If remoteURL is set
        if let _ = git.remoteURL {
            git.pushToRemote()
        } else {
            print ("not set")
        }
    }
    
    @IBAction func checkoutBranch(_ sender: Any?) {
        // segue to popover branch select
        let branches = git.getBranches()
        let msvc = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "multiselect")) as! MultiSelectViewController
        
        msvc.delegate = self
        var ds: [String: AnyObject]  = [:]
        branches.forEach { (branch) in
            ds[branch.name!] = branch
        }
        msvc.dataSource = ds
        self.presentViewControllerAsSheet(msvc)
        
    }
    
    @IBAction func merge(_ sender: Any?) {
        let branch = mergeBranchDropdown.selectedItem?.representedObject! as! GTBranch
        do {
            try git.merge(with: branch)
        } catch GitError.mergeFailure {
            // present alert that merge failed
            let alert = NSAlert()
            alert.messageText = "Merge failed"
            alert.runModal()
            return
        } catch {
            // Other error
            return
        }
    }
    
    @IBAction func openInAbleton(_ sender: Any?) {
        guard let project = self.projectFileDropdown.selectedItem?.title else {
            print("no project selected")
            return
        }
        let projectURL = self.abletonProjectFiles.first { (url) -> Bool in
            url.lastPathComponent == project
        }
        do {
            try NSWorkspace.shared.open([projectURL!], withApplicationAt: URL(fileURLWithPath: self.abletonLocation), options: NSWorkspace.LaunchOptions.default, configuration: [:])
        } catch {
            print(error)
            print("error opening project file")
        }
        
    }
    
}

// MARK: MultiSelectDelegate implementation

extension GitCommandsViewController: MultiSelectDelegate {
    func optionSelected(selected: AnyObject) {
        // Only works for branch select so far
        // make more general
        git.checkout(to: selected as! GTBranch)
        
        if let currentBranch = git.getCurrentBranch() {
            self.currentBranch?.stringValue = currentBranch
        }
    }
}

// MARK: CommitDelegate implementation

extension GitCommandsViewController: CommitDelegate {
    func commit(with message: String) {
        do {
            let _ = try git.commitAllChanges(with: message)
        } catch {
            print(error)
        }
    }
}