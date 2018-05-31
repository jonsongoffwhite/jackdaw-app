//
//  GitHandler.swift
//  Jackdaw
//
//  Created by Jonson Goff-White on 16/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//
//  WORKING DIRECTORY
//      add                 RED
//  INDEX
//      commit              GREEN
//  REPOSITORY

import Foundation
import SwiftGit2
import ObjectiveGit
import Result
import KeychainAccess

enum GitError: Error {
    case invalidRepoPath
    case unableToCommitAll
    case mergeFailure
    case currentBranchInvalid
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
    
    func addChanged() {
        // iterate through files in repo
        // add modified
        
        
        let status = repo.status().value!
        
        for entry in status {
            
            if let newFilePath = entry.headToIndex?.newFile?.path {
                let _ = repo.add(path: newFilePath)
            }
        
            if let newFilePath = entry.indexToWorkDir?.newFile?.path {
                let _ = repo.add(path: newFilePath)
            }
            
        }
        
        
    }
    
    func commit(with message: String) throws -> Commit {
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
    
    func commitAllChanges(with message: String) throws -> Commit {
        addAllChanges()
        
        return try commit(with: message)
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
    
    func checkout(toBranchWithName branchName: String) {
        do {
            let branches = try ogRepo.localBranches()
            var branch: GTBranch?
            for b in branches {
                if let name = b.name {
                    if name == branchName {
                        branch = b
                    }
                }
            }
            if let branch = branch {
                self.checkout(to: branch)
            }
        } catch {
            print(error)
            print("unable to checkout to branch with name \(branchName)")
        }
    }
    
    func merge(with branch: GTBranch) throws {
        let path = directory.path.replacingOccurrences(of: " ", with: "\\ ")
        let branchName = String(branch.name!.split(separator: "/")[0])
        shell(command: "cd \(path) && git merge \(branchName)")
        
        
//        let ocurrent = try? ogRepo.currentBranch()
//        guard let current = ocurrent else {
//            throw GitError.currentBranchInvalid
//        }
//
//        // Arguments mislabelled
//        // intoCurrentBranch is actually fromBranch
//        do {
//            try ogRepo.mergeBranch(intoCurrentBranch: branch)
//        } catch {
//            print(error)
//            throw GitError.mergeFailure
//        }
        
        
//        let tmpURL = directory.appendingPathComponent(".tmp")
//        do {
//            try manager.createDirectory(at: tmpURL, withIntermediateDirectories: false, attributes: nil)
//        } catch {
//            // Already exists?
//            print("error creating temp merge directory")
//            print(error)
//            throw GitError.mergeFailure
//        }
//
//        func saveTempData(appendix: String) -> (URL, Data) -> () {
//            return {(url: URL, data: Data) in
//                let filename = url.lastPathComponent
//                let file = tmpURL.appendingPathComponent(appendix + "_" + filename)
//                print(url)
//                self.manager.createFile(atPath: file.path, contents: data, attributes: nil)
//            }
//        }
//
//        guard let currentBranch = try? ogRepo.currentBranch() else {
//            throw GitError.mergeFailure
//        }
//        let ourData = copyAlss()
//        ourData.forEach(saveTempData(appendix: "ours"))
//        guard let ourOID = currentBranch.oid else {
//            throw GitError.mergeFailure
//        }
//
//        do {
//            let options = GTCheckoutOptions(strategy: .safe)
//            try ogRepo.checkoutReference(branch.reference, options: options)
//        } catch {
//            print(error)
//            throw GitError.mergeFailure
//        }
//
//        let theirData = copyAlss()
//
//        guard let theirOID = branch.oid else {
//            throw GitError.mergeFailure
//        }
//        theirData.forEach(saveTempData(appendix: "theirs"))
//        guard let ancestorCommit = try? ogRepo.mergeBaseBetweenFirstOID(ourOID, secondOID: theirOID) else {
//            throw GitError.mergeFailure
//        }
//        do {
//            let options = GTCheckoutOptions(strategy: .safe)
//            try ogRepo.checkoutCommit(ancestorCommit, options: options)
//        } catch {
//            print(error)
//            throw GitError.mergeFailure
//        }
//        let baseData = copyAlss()
//        baseData.forEach(saveTempData(appendix: "base"))
//
//
//        // Return to original branch
//        do {
//            let options = GTCheckoutOptions(strategy: .safe)
//            try ogRepo.checkoutReference(currentBranch.reference, options: options)
//        } catch {
//            print(error)
//            throw GitError.mergeFailure
//        }
//
//        do {
//            //manager.removeItem(at: directory.appendingPathComponent(".tmp"))
//        } catch {
//            print(error)
//        }
        
        
    }
    
    // Returns mapping of file URL to data at that time
    // May need to move this out of memory depending on performance
    private func copyAlss() -> [URL: Data] {
        let files = manager.enumerator(at: directory, includingPropertiesForKeys: nil)
        var alss: [URL: Data]  = [:]
        while let file = files?.nextObject() {
            let file = file as! URL
            if file.pathExtension == ABLETON_PATH_EXTENSION
            && file.deletingLastPathComponent() != directory.appendingPathComponent("Backup")
            && file.deletingLastPathComponent() != directory.appendingPathComponent(".tmp")
            {
                let data = try! Data(contentsOf: file)
                alss[file] = data
            }
        }
        return alss
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
    
    func getCurrentBranchObject() -> GTBranch {
        return try! self.ogRepo.currentBranch()
    }
    
    func getBranch(with branchName: String) -> GTBranch? {
        do {
            let branches = try ogRepo.localBranches()
            var branch: GTBranch?
            for b in branches {
                if let name = b.name {
                    if name == branchName {
                        branch = b
                    }
                }
            }
            if let branch = branch {
                return branch
            }
        } catch {
            print(error)
            print("unable to checkout to branch with name \(branchName)")
        }
        return nil
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
        
        let localConfigURL = Bundle.main.url(forResource: "config", withExtension: "", subdirectory: "als-merge-driver")!
        let localAttributesURL = Bundle.main.url(forResource: "attributes", withExtension: "", subdirectory: "als-merge-driver")!
        
        let configString = try! String(contentsOf: localConfigURL, encoding: .utf8)
        let attributeString = try! String(contentsOf: localAttributesURL, encoding: .utf8)

        
        // ATTRIBUTES
        
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
        
        // CONFIG
        
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
        
        // SCRIPTS
        
        let scriptsURL = directory.appendingPathComponent(".merge")
        
        do {
            try manager.createDirectory(at: scriptsURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            // Already exists?
            print("error creating merge scripts directory")
            print(error)
        }
        
        let bashMergeURL = scriptsURL.appendingPathComponent("merge-als.sh")
        
        // Refactor to an iterator over the folder, if it ends in .py
        let driverFiles = Bundle.main.urls(forResourcesWithExtension: "py", subdirectory: "als-merge-driver")!
        
        
        for url in driverFiles {
            let repoFile = scriptsURL.appendingPathComponent(url.lastPathComponent)
            if !manager.fileExists(atPath: repoFile.path) {
                let localData = try! Data(contentsOf: url)
                manager.createFile(atPath: repoFile.path, contents: localData, attributes: nil)
            }
        }
        
        if !manager.fileExists(atPath: bashMergeURL.path) {
            let localBashMerge = Bundle.main.url(forResource: "merge-als.sh", withExtension: "", subdirectory: "als-merge-driver")!
            let localBashMergeData = try! Data(contentsOf: localBashMerge)
            manager.createFile(atPath: bashMergeURL.path, contents: localBashMergeData, attributes: nil)
        }
        
    }
    
    func gitStatus() -> Int32 {
        let task = Process()
        let git = Bundle.main.url(forResource: "git", withExtension: "")!
        task.executableURL = git
        task.arguments = ["status"]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    func shell(command: String) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["bash", "-c", command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}

/*
 
 int git_merge(
 git_repository *repo,
 const git_annotated_commit **their_heads,
 size_t their_heads_len,
 const git_merge_options *merge_opts,
 const git_checkout_options *given_checkout_opts)
 
 
 
 */
