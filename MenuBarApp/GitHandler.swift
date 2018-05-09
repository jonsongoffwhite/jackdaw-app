//
//  GitHandler.swift
//  MenuBarApp
//
//  Created by Jonson Goff-White on 16/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//
//  WORKING DIRECTOR
//      add
//  INDEX
//      commit
//  REPOSITORY

import Foundation
import SwiftGit2
import ObjectiveGit
import Result

enum GitError: Error {
    case invalidRepoPath
    case unableToCommitAll
}

class GitHandler {
    
    let manager = FileManager()
    
    var directory: URL
    var repo: Repository
    var ogRepo: GTRepository

    init(for directory: URL) throws {
        self.directory = directory
        
        // SwitfGit2 repository
        let repoRes: Result = Repository.at(directory)
        guard let repo = repoRes.value else {
            throw GitError.invalidRepoPath
        }
        self.repo = repo
        
        // ObjectiveGit repository
        do {
            self.ogRepo = try GTRepository(url: directory)
        } catch {
            throw GitError.invalidRepoPath
        }
    }
    
    /*
     ** Determines whether the provided directory is yet a git directory
     ** by checking for the existence of the .git hidden directory
     ** present in all git repositories
     */
    func isGitDirectory() -> Bool {
        return manager.fileExists(atPath: directory.path + "/.git")
    }
    
    func commitAllChanges() throws -> Commit {
        addAllChanges()
        
        let sig = Signature(
            name: "Jonson Goff-White",
            email: "jonnygoffwhite@gmail.com",
            time: Date(),
            timeZone: TimeZone.current
        )
        
        let result = repo.commit(message: "Commit message", signature: sig)
        if let commit = result.value {
            return commit
        } else {
            print(result.error)
            throw GitError.unableToCommitAll
        }
    
        
    }
    
    private func addAllChanges() {
        let branch = repo.localBranch(named: "master").value!
        let _ = repo.checkout(branch, strategy: CheckoutStrategy.AllowConflicts)
        guard let status = repo.status().value else {
            return
        }
        
        // Stage all changes
        for file in status {
            
//            // Changed (hti)
//            if let hti = file.headToIndex {
//                //let oldFileName = hti.oldFile?.path
//                if let newFileName = hti.newFile?.path {
//                    let _ = repo.add(path: newFileName)
//                    print("adding \(newFileName)")
//                }
//            }
            
            // Unstaged (itwd)
            if let itwd = file.indexToWorkDir {
                if let newFileName = itwd.newFile?.path {
                    let _ = repo.add(path: newFileName)
                    print("adding \(newFileName)")
                }
            }
        }
    }
    
    func statusDescription() -> String {
        
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
