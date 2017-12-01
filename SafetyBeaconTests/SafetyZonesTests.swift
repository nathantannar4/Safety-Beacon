//
//  SafetyTrackerTests.swift
//  SafetyTrackerTests
//
//  Created by Nathan Tannar on 9/20/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import XCTest
@testable import SafetyBeacon

class SafetyTrackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCorrectLogin() {
        User.loginInBackground(email: "caretaker@safetybeacon.ca", password: "password123") { (success) in
            XCTAssert(success)
        }
    }
    
    func testIncorrectLogin() {
        User.loginInBackground(email: "caretaker@safetybeacon.ca", password: "wrongpassword") { (success) in
            // Success should be false
            XCTAssert(!success)
        }
    }
    
    func testCorrectRegister() {
        let randomEmail = String.random(ofLength: 12) + "safetybeacon.ca"
        User.loginInBackground(email: randomEmail, password: String.random(ofLength: 8)) { (success) in
            XCTAssert(success)
        }
    }
    
    func testIncorrectRegister() {
        User.registerInBackground(email: "caretaker@safetybeacon.ca", password: "password123") { (success) in
            // User already in use
            XCTAssert(!success)
        }
    }
    
}
