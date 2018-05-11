//
//  MultiSelectViewController.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 10/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

protocol MultiSelectDelegate {
    func optionSelected(selected: AnyObject)
}

class MultiSelectViewController: NSViewController {
    
    var dataSource: [String : AnyObject]?
    var dataSourceKeys: [String]?
    
    var delegate: MultiSelectDelegate?
    
    @IBOutlet weak var table: NSTableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let dataSource = dataSource {
            dataSourceKeys = Array(dataSource.keys)
            table?.dataSource = self
            table?.delegate = self
        } else {
            // This is bad
            print("data source not set")
            return
        }
        
    }
    
    @IBAction func selectChoice(_ sender: Any?) {
        guard let row = table?.selectedRow else {
            // Do nothing if no row selected
            return
        }
        
        let elemStr = dataSourceKeys![row]
        let obj = dataSource![elemStr]
        delegate?.optionSelected(selected: obj!)
        dismiss(self)
    }
    
}

extension MultiSelectViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource!.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return dataSourceKeys![row]
    }
}
