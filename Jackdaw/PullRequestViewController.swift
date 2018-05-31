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
    var branchA: String!
    var branchB: String!
    
    override func viewDidLoad() {
        print("called")
        branchButtonA.data = branchA
        branchButtonA.title = String(branchA.split(separator: ":")[1])
        branchButtonA.sizeToFit()
        
        branchButtonB.data = branchB
        branchButtonB.title = String(branchB.split(separator: ":")[1])
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
    
    @IBAction func checkoutAndLoad(_ sender: Any) {
        // Could actually just be a commit I think
        // Or maybe a remote branch that is not yet on local
        
        if let button = sender as? DataButton {
            guard let data = button.data as? String else {
                return
            }
            git.checkout(toBranchWithName: data)
        }
        print(git.getCurrentBranch())
    }
}

extension PullRequestViewController {
    // MARK: Storyboard instantiation
    static func freshController(repo: String, branchA: String, branchB: String, project: AbletonProject, git: GitHandler) -> PullRequestViewController {
        // Get Main story board
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        // Get ViewController with identifier GitCommandsViewController
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "PullRequestViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PullRequestViewController else {
            fatalError("Why cant i find PullRequestViewController? - Check Main.storyboard")
        }
        viewcontroller.git = git
        viewcontroller.project = project
        viewcontroller.branchA = branchA
        viewcontroller.branchB = branchB
        return viewcontroller
    }
}
