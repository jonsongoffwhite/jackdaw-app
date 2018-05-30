//
//  FolderSelectViewController.swift
//  Jackdaw
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
            let identifier = "GitCommandsViewController"
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            let gcvc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: identifier)) as! GitCommandsViewController
            gcvc.directory = chosenDir!
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.replaceContentViewController(with: gcvc)
        } else {
            // No directory selected
            return
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
