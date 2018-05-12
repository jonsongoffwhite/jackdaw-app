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
        } catch {
            print(error)
        }
        
        // TODO: check if it is correct user/pass that has been retrieved from Keychain
        
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
    
    func commitAllChanges(with message: String) throws -> Commit {
        addAllChanges()
        
        let sig = Signature(
            name: "Jonson Goff-White",
            email: "jonnygoffwhite@gmail.com",
            time: Date(),
            timeZone: TimeZone.current
        )

        let result = repo.commit(message: message, signature: sig)
        if let commit = result.value {
            // Try and push the changes
            self.pushToRemote()
            
            // Return commit
            return commit
        } else {
            print(result.error)
            throw GitError.unableToCommitAll
        }
    }
    
    private func addAllChanges() {
        //print (repo.status())
        let _ = repo.add(path: ".")
    }
    
    func checkout(to branch: GTBranch) {
        let options = GTCheckoutOptions(strategy: .allowConflicts)
        do {
            try ogRepo.checkoutReference(branch.reference, options: options)
        } catch {
            print(error)
            print("error checking out")
        }
    }
    
    func getBranches() -> [GTBranch] {
        // just gets local branches
        do {
            let branches = try ogRepo.localBranches()
            return branches
        } catch {
            print(error)
            print("error getting branches")
            return []
        }
    }
    
    func getCurrentBranch() -> String? {
        let curr = try? self.ogRepo.currentBranch()
        return curr?.name
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
    
    func injectMergeDriver() {
        // If .gitattributes or .git/info/attributes exists then append necessary line
        // Check if line actually needs to be appended
        // Append to .git/config
        // Create hidden folder in root, store merge scripts
        // Add to .gitignore if exists, else create and add
        
        var dotAttributesExists: Bool
        var infoAttributesExists: Bool
        var gitConfigExists: Bool
        
        if !isGitDirectory() {
            return
        }
        
        dotAttributesExists = manager.fileExists(atPath: directory.path + "/.attributes")
        infoAttributesExists = manager.fileExists(atPath: directory.path + "/.git/info/attributes")
        gitConfigExists = manager.fileExists(atPath: directory.path + "/.git/config")
        
        let localConfigURL = Bundle.main.url(forResource: "config", withExtension: "")!
        let localAttributesURL = Bundle.main.url(forResource: "attributes", withExtension: "")!
        
        let configString = try! String(contentsOf: localConfigURL, encoding: .utf8)
        let attributeString = try! String(contentsOf: localAttributesURL, encoding: .utf8)

        var attr: URL
        
        // Prefer info attributes
        if infoAttributesExists {
            attr = directory.appendingPathComponent(".git")
                            .appendingPathComponent("info")
                            .appendingPathComponent("attributes")
        } else if dotAttributesExists {
            attr = directory.appendingPathComponent(".attributes")
        } else {
            attr = directory.appendingPathComponent(".git")
                            .appendingPathComponent("info")
                            .appendingPathComponent("attributes")
            manager.createFile(atPath: attr.path, contents: nil, attributes: nil)
        }
        
        if let fileHandle = try? FileHandle(forWritingTo: attr) {
        
            let attrContentsString = try! String(contentsOf: attr, encoding: .utf8)
            
            if attrContentsString.range(of: attributeString) == nil {
                // attribute setup not already in file
                fileHandle.seekToEndOfFile()
                fileHandle.write(attributeString.data(using: .utf8)!)
            }
            fileHandle.closeFile()
        }
        
        let config = directory.appendingPathComponent(".git")
                              .appendingPathComponent("config")
        
        if !gitConfigExists {
            manager.createFile(atPath: config.path, contents: nil, attributes: nil)
        }
        
        if let fileHandle = try? FileHandle(forWritingTo: config) {
            let configContentsString = try! String(contentsOf: config, encoding: .utf8)
            
            if configContentsString.range(of: configString) == nil {
                // config setup not already in file
                fileHandle.seekToEndOfFile()
                fileHandle.write(configString.data(using: .utf8)!)
            }
            fileHandle.closeFile()
        }
        
        
    }
}
