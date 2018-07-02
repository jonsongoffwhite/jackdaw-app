//
//  PullRequestViewController.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 25/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation
import Cocoa

class DataButton: JackButton {
    
    var data: Any?
    
}

class PullRequestViewController: NSViewController {
    @IBOutlet weak var branchButtonA: DataButton!
    @IBOutlet weak var branchButtonB: DataButton!
    
    @IBOutlet weak var projectFileDropdown: NSPopUpButton!
    
    var git: GitHandler!
    var project: AbletonProject!
    var base: String!
    var branch: String!
    
    override func viewDidLoad() {
        branchButtonA.data = base
        branchButtonA.title = String(base.split(separator: ":")[1])
        branchButtonA.sizeToFit()
        
        branchButtonB.data = branch
        branchButtonB.title = String(branch.split(separator: ":")[1])
        branchButtonB.sizeToFit()
        
        // Populate projectFileDropdown
        let menu = NSMenu(title: "projectFileMenu")
        project.projectFiles.forEach { (file) in
            let name = file.lastPathComponent
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            item.representedObject = file
            menu.addItem(item)
        }
        projectFileDropdown.menu = menu
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        preferredContentSize = NSSize(width: 400, height: 280)
    }
    
    @IBAction func checkoutAndLoad(_ sender: Any) {
        // Could actually just be a commit I think
        // Or maybe a remote branch that is not yet on local
        
        if let button = sender as? DataButton {
            guard let data = button.data as? String else {
                return
            }
            git.checkout(toBranchWithName: data)
            project.open(projectURL: projectFileDropdown.selectedItem?.representedObject as! URL)
        }
    }
    
    @IBAction func merge(_ sender: Any) {
        
        // do a git pull here to ensure everything up to date?
        // stash changes on initial branch then reapply at end?
        
        let initialBranch = git.getCurrentBranchObject()
        
        let baseName = String(self.base.split(separator: ":").last!)
        git.checkout(toBranchWithName: baseName)
        
        let branchName = String(self.branch.split(separator: ":").last!)
        let branch = git.getBranch(with: branchName)!
        
        do {
            try git.merge(with: branch)
            //try git.commitAllChanges(with: "Merge commit")
            // commit all changed files, not all files
            git.addChanged()
            let _ = try git.commit(with: "Merge commit")
            git.pushToRemote()
        } catch {
            print("merge failed")
            print(error)
        }
        
        git.checkout(to: initialBranch)
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.returnFromSchemeView()
    }
    
    @IBAction func cancel(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.returnFromSchemeView()
    }
}

extension PullRequestViewController {
    // MARK: Storyboard instantiation
    static func freshController(repo: String, base: String, branch: String, project: AbletonProject, git: GitHandler) -> PullRequestViewController {
        // Get Main story board
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        // Get ViewController with identifier GitCommandsViewController
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "PullRequestViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PullRequestViewController else {
            fatalError("Why cant i find PullRequestViewController? - Check Main.storyboard")
        }
        viewcontroller.git = git
        viewcontroller.project = project
        viewcontroller.base = base
        viewcontroller.branch = branch
        return viewcontroller
    }
}
