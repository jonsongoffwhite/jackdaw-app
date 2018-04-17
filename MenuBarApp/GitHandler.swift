//
//  GitHandler.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 16/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import Foundation
import SwiftGit2
import Result

class GitHandler {
    
    let manager = FileManager()
    
    var directory: String
    
    init(for directory: String) {
        self.directory = directory
    }
    
    /*
     ** Determines whether the provided directory is yet a git directory
     ** by checking for the existence of the .git hidden directory
     ** present in all git repositories
     */
    func isGitDirectory() -> Bool {
        return manager.fileExists(atPath: directory + "/.git")
    }
    
    func statusDescription() -> String {
        let repoRes: Result = Repository.at(URL(fileURLWithPath: directory))
        guard let repo = repoRes.value else {
            return "Error"
        }
        
        var added = ""
        var modified = ""
        
        if let status = repo.status().value {
            for file in status {
                if let hti = file.headToIndex {
                    let oldFileName = hti.oldFile?.path != nil ? hti.oldFile!.path : "nil"
                    let newFileName = hti.newFile?.path != nil ? hti.newFile!.path : "nil"
                    
                    if oldFileName == newFileName {
                        added += "\(oldFileName)\n"
                    } else {
                        added += "\(oldFileName) -> \(newFileName)\n"
                    }
                }
                
                if let itwd = file.indexToWorkDir {
                    let oldFileName = itwd.oldFile?.path != nil ? itwd.oldFile!.path : "nil"
                    let newFileName = itwd.newFile?.path != nil ? itwd.newFile!.path : "nil"
                    
                    if oldFileName == newFileName {
                        modified += "\(oldFileName)\n"
                    } else {
                        modified += "\(oldFileName) -> \(newFileName)\n"
                    }
                }
            }
            
        }
        return "added: \n\n" + added + "\nmodified: \n\n" + modified
    }
    
}
