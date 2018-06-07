//
//  VersionSelectionViewController.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 06/06/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa
import ObjectiveGit

class VersionSelectViewController: NSViewController {
    
    @IBOutlet var table: NSTableView!
    
    var commits: [GTCommit]?
    
    var delegate: VersionSelectDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.table.delegate = self
        self.table.dataSource = self
        
        let chooseCommit: Selector = #selector(VersionSelectViewController.chooseCommit)
        
    }
    
    
    
}

extension VersionSelectViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return commits?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let column = table.tableColumns.index(of: tableColumn!)
        let commit = commits![row]
        
        if column == 0 {
            let cellIdentifier = "commitDescriptionCell"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = commit.message ?? ""
                return cell
            }
        } else if column == 1 {
            let cellIdentifier = "commitDateTimeCell"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = formatter.string(from: commit.commitDate)
                cell.textField?.stringValue = dateString
                return cell
            }
        } else {
            let cellIdentifier = "commitHashCell"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = String(commit.hashValue)
                return cell
            }
        }
        return nil
    }
    
    @objc func chooseCommit(sender: Any?) {
        if let sender = sender as? NSTableView {
            let chosenCommit = self.commits?[sender.selectedRow]
            if let chosenCommit = chosenCommit {
                // return this commit and checkout to it
                delegate?.checkout(to: chosenCommit)
            }
        }
    }
}

extension VersionSelectViewController {
    
    static func freshController(commits: [GTCommit]) -> VersionSelectViewController {
        // Get Main story board
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        // Get ViewController with identifier VersionSelectViewController
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "VersionSelectViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier)
        print(vc is VersionSelectViewController)
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? VersionSelectViewController else {
            print(identifier)
            fatalError("Why cant i find VersionSelectViewController? - Check Main.storyboard")
        }
        viewcontroller.commits = commits
        print(commits.count)
        return viewcontroller
    }
}

protocol VersionSelectDelegate {
    func checkout(to commit: GTCommit)
}
