//
//  CommitViewController.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 11/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Cocoa

protocol CommitDelegate {
    func commit(with message: String)
}

class CommitViewController: NSViewController {
    
    @IBOutlet weak var commitMessageField: NSTextField!
    
    var delegate: CommitDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func commit(_ sender: Any) {
        // Get commit message
        let message = commitMessageField.stringValue
        self.delegate?.commit(with: message)
        dismiss(self)
    }
}
