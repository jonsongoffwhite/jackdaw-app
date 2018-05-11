//
//  FolderSelectViewController.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 16/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

class FolderSelectViewController: NSViewController {
    
    @IBOutlet weak var selectedDir: NSTextField?
    var chosenDir: URL?
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func browseFile(sender: AnyObject) {
        
        let dialog = NSOpenPanel()
        
        dialog.title = "Select project folder"
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        // dialog.allowedFileTypes        = [];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            guard let directory = dialog.url else {
                return
            }
            selectedDir?.stringValue = directory.path
            self.chosenDir = directory
        } else {
            return
        }
    }
    
    @IBAction func confirm(sender: AnyObject) {
        if let _ = chosenDir {
            performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showGitCommands"), sender: sender)
        } else {
            // No directory selected
            return
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.destinationController is GitCommandsViewController {
            let vc = segue.destinationController as! GitCommandsViewController
            vc.directory = chosenDir!
        }
    }
    
}

extension FolderSelectViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> FolderSelectViewController {
        // Get Main story board
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        // Get ViewController with identifier GitCommandsViewController
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "FolderSelectViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? FolderSelectViewController else {
            fatalError("Why cant i find FolderSelectViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
