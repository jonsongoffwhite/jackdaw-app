//
//  ConflictSelectViewController.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 31/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation
import Cocoa

class ConflictSelectViewController: NSViewController {
    @IBOutlet weak var table: NSTableView!
    
    var project: AbletonProject?
    
    var git: GitHandler!
    
    var conflicts: [URL]?
    
    // true is ours, false is theirs
    var conflictSolutions: [URL: Bool?]?
    
    var buttonValues: [[NSButton]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.table.delegate = self
        self.table.dataSource = self
        
        let openSelector: Selector = #selector(ConflictSelectViewController.openSelected)
        
        self.table.doubleAction = openSelector
        self.table.target = self
    }
    
    
    @objc func openSelected(sender: Any?) {
        if let sender = sender as? NSTableView {
            print("is table view sending")
            print(sender.selectedRow)
            print(conflicts![sender.selectedRow])
            let toOpen = conflicts?[sender.selectedRow]
            if let toOpen = toOpen {
                print(toOpen)
                NSWorkspace.shared.open(toOpen)
            }
        }
    }
    
    @IBAction func chosen(_ sender: Any?) {
        if self.conflictSolutions!.count ==  self.conflicts!.count {
            git.resolve(with: self.conflictSolutions! as! [URL: Bool])
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.returnFromSchemeView()
        }
    }
    
    @IBAction func cancel(_ sender: Any?) {
        
        git.abortMerge()
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.returnFromSchemeView()
    }
    
    @objc func radioSelected(_ sender: NSButton) {
        print("radio selected!")
        print(self.buttonValues)
        for buttonArray in self.buttonValues {
            if buttonArray.contains(sender) {
                let confIndex = self.buttonValues.index(of: buttonArray)
                print("found correct button array!")
                var other: NSButton!
                buttonArray.forEach { (b) in
                    if b != sender {
                        other = b
                    }
                }
                
                // True is ours, false is theirs
                let senderIndex = buttonArray.index(of: sender)
                
                // UI sets this to on
                if sender.state == .on {
                    let conflict = self.conflicts![confIndex!]
                    self.conflictSolutions![conflict] = senderIndex! == 0
                    print("setting \(conflict) to \(senderIndex!==0)")
                    print(Int(senderIndex!) == 0)
                    print(senderIndex! == 0)
                    print("setting state to on and other to off")
                    other.state = .off
                    print(self.conflictSolutions![conflict]!)
                }
            }
        }
    }
    
}

extension ConflictSelectViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return conflicts!.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let column = table.tableColumns.index(of: tableColumn!)
        
        if column == 1 {
            let cellIdentifier = "OursCellID"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                let radio = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
                radio.title = ""
                let selector = #selector(ConflictSelectViewController.radioSelected(_:))
                radio.action = selector
                self.buttonValues[row].append(radio)
                cell.addSubview(radio)
                return cell
            }
        } else if column == 2 {
            let cellIdentifier = "TheirsCellID"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                
                let radio = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
                radio.title = ""
                
                let selector = #selector(ConflictSelectViewController.radioSelected(_:))
                radio.action = selector
                self.buttonValues[row].append(radio)
                cell.addSubview(radio)
                return cell
            }
        } else {
            let cellIdentifier = "ConflictCellID"
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            
                cell.textField?.stringValue = self.conflicts![row].lastPathComponent
                
                //temporary
                cell.textField?.stringValue = "Conflict 1"
                
                return cell
            }
        }
        return nil
    }
    
}

extension ConflictSelectViewController {
    static func freshController(project: AbletonProject, git: GitHandler, conflicts: [String]) -> ConflictSelectViewController {
        // Get Main story board
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        
        // Get ViewController with identifier ConflictSelectViewController
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "ConflictSelectViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ConflictSelectViewController else {
            fatalError("Why cant i find ConflictSelectViewController? - Check Main.storyboard")
        }
        viewcontroller.project = project
        viewcontroller.git = git
        print(conflicts)
        viewcontroller.conflicts = conflicts.map({ (str) -> URL in
            print(str)
            return project.getURLFromString(str: str)
        })
        var conflictSolutions: [URL: Bool?] = [:]
        for conf in viewcontroller.conflicts! {
            conflictSolutions[conf] = nil
        }
        viewcontroller.conflictSolutions = conflictSolutions
        viewcontroller.buttonValues = []
        for _ in 0..<conflicts.count {
            viewcontroller.buttonValues?.append([])
        }
        return viewcontroller
    }
}
