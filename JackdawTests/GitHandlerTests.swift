//
//  GitHandlerTests.swift
//  JackdawTests
//
//  Created by Jonson Goff-White on 17/04/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

import XCTest
import SwiftGit2

class GitHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Setup test repo
        Repository.create(at: URL(fileURLWithPath: "test-repo"))
        print("setup")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRepoPresent() {
        let repo = Repository.at(URL(fileURLWithPath: "test-repo"))
        XCTAssertNotNil(repo.value)
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
