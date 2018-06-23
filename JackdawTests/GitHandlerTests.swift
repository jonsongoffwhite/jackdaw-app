//
//  GitHandlerTests.swift
//  JackdawTests
//
//  Created by Jonson Goff-White on 17/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import XCTest
import SwiftGit2
@testable import Jackdaw

class GitHandlerTests: XCTestCase {
    
    var handler: GitHandler!
    var url: URL!
    var ogrepo: GTRepository!
    var repo: Repository!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // set up test repo
        
        url = URL(fileURLWithPath: "test-repo")
        repo = Repository.create(at: url).value!
        ogrepo = try! GTRepository(url: url)
        //let branchName = "refs/heads/master"
        let manager = FileManager.default
        let data = "contents of filler file".data(using: .utf8)
        manager.createFile(atPath: url.appendingPathComponent("filler").path, contents: data, attributes: nil)
        let _ = self.shell(command: "cd test-repo && git add . && git commit -m 'Initial Commit'")
        let _ = self.shell(command: "cd test-repo && git status")
        
        handler = try! GitHandler(for: url)
        
        print("setup")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // delete test repo
        let manager = FileManager.default
        try! manager.removeItem(at: url)
        
    }
    
    func testCreateBranchWithName() {
        let name = "new-branch"

        XCTAssertNil(handler.getBranch(with: "name"))

        let branch = try? handler.createBranch(with: name)

        XCTAssertNotNil(branch)
        XCTAssertNotNil(handler.getBranch(with: name))
    }
    
    func testCommit() {
        let message = "test commit message"
        let enumerator = try! GTEnumerator(repository: ogrepo)
        try! enumerator.pushHEAD()
        let firstCommit = try! enumerator.allObjectsWithError().first!
        let firstCommitHash = firstCommit.hash
        
        // Make a change
        let manager = FileManager.default
        let data = "change".data(using: .utf8)
        manager.createFile(atPath: url.appendingPathComponent("new").path, contents: data, attributes: nil)
        // Stage change
        repo.add(path: ".")
        // Commit with message
        try! handler.commit(with: message)
        // Check commits have changed
        let newEnumerator = try! GTEnumerator(repository: ogrepo)
        try! newEnumerator.pushHEAD()
        let commit = try! newEnumerator.allObjectsWithError().first!
        let commitHash = commit.hash
        
        XCTAssertTrue(commitHash != firstCommitHash)
        XCTAssertTrue(commit.message! == message + "\n")
        
    }
    
    func testCheckout() {
        let name = "new-branch"
        let branch = try! handler.createBranch(with: name)
        XCTAssertTrue(try! ogrepo.currentBranch().name != name)
        handler.checkout(to: branch)
        XCTAssertTrue(try! ogrepo.currentBranch() == branch)
    }
    
    func testRepoPresent() {
        let repo = Repository.at(URL(fileURLWithPath: "test-repo"))
        XCTAssertNotNil(repo.value)
    }
    
    func testMerge() {
        let manager = FileManager.default
        let name = "new-branch"
        let branch = try! handler.createBranch(with: name)
        let current = try! ogrepo.currentBranch()
        let data = "content".data(using: .utf8)
        handler.checkout(to: branch)
        manager.createFile(atPath: url.appendingPathComponent("new").path, contents: data, attributes: nil)
        try! handler.commit(with: "new branch commit")
        handler.checkout(to: current)
        manager.createFile(atPath: url.appendingPathComponent("on_master").path, contents: data, attributes: nil)
        try! handler.commit(with: "master commit")
        try! handler.merge(with: branch)
        XCTAssertTrue(manager.fileExists(atPath: url.appendingPathComponent("new").path))
        XCTAssertTrue(manager.fileExists(atPath: url.appendingPathComponent("on_master").path))
        
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
