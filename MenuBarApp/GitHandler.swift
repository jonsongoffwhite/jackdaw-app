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
import KeychainAccess

enum GitError: Error {
    case invalidRepoPath
    case unableToCommitAll
}

class GitHandler {
    
    // File IO
    let manager = FileManager()
    
    // Directory URL with bookmark
    var directory: URL
    
    // SwiftGit2 Repo
    var repo: Repository
    
    // ObjectiveGit repo
    var ogRepo: GTRepository
    
    // Remote URL
    private (set) var remoteURL: URL? 
    
    // Remote Object (OG)
    private var remote: GTRemote?

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
        
        // Set remote if one exists
        let remoteNames = try? ogRepo.remoteNames()
        if let remoteNames = remoteNames {
            if remoteNames.count > 0 {
                // Arbitrarily chose the first existing remote
                let remoteName = remoteNames[0]
                self.remoteURL = URL(string: remoteName)!
                do {
                    self.remote = try GTRemote(name: remoteName, in: ogRepo)
                } catch {
                    print("Error getting existing remote")
                    print(error)
                    self.remoteURL = nil
                }
            }
        }
    }
    
    // Set main repo remote url
    public func setRemote(with remoteURL: URL, name: String = "origin") -> Bool {
        self.remoteURL = remoteURL
        let remoteName = name
        do {
            self.remote = try GTRemote.createRemote(withName: remoteName, urlString: remoteURL.absoluteString, in: ogRepo)
        } catch {
            print("Error creating remote with name: \(remoteName), at url: \(remoteURL.absoluteString)")
            print(error)
            
            // Reset string
            self.remoteURL = nil
            return false
        }
        return true
    }
    
    // Push local commits to remote repo
    public func pushToRemote() {
        let keychain = Keychain(server: "https://github.com", protocolType: .https)
        let username = "jonsongoffwhite"
        var password: String?
        
        do {
            password = try keychain
                .authenticationPrompt("Authenticate with logic to allow access to GitHub credentials")
                .get(username)
        } catch let error {
            // Error handling if needed...
        }
        
        if let remote = self.remote, let password = password {
            // Remote is set, push
            do {
                // make credentials
                let creds = try GTCredential(userName: username, password: password)
                let provider = GTCredentialProvider { (type, url, credUserName) -> GTCredential? in
                    return creds
                }
                
                let options = [GTRepositoryRemoteOptionsCredentialProvider: provider]
                // attach to push
                try ogRepo.push(ogRepo.currentBranch(), to: remote, withOptions: options, progress: nil)
            } catch {
                print(error)
                print("unable to push to repo")
            }
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
