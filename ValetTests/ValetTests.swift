//
//  ValetTests.swift
//  Valet
//
//  Created by Eric Muller on 4/25/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//

import Foundation
import XCTest


class TestValet: VALValet {}


class ValetTests: XCTestCase
{
    let valet = VALValet(identifier: "valet_testing", accessibility: .WhenUnlocked)!
    let key = "key"
    let passcode = "topsecret"

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
    }

    // MARK: Equality

    func test_twoValetsWithSameConfiguration_haveEqualPointers()
    {
        let otherValet = VALValet(identifier: "valet_testing", accessibility: .WhenUnlocked)
        XCTAssert(otherValet == valet)
        XCTAssert(otherValet === valet)
    }

    func test_valetSubclassWithSameConfiguration_doesNotHaveEqualPointer()
    {
        let subclassValet = TestValet(identifier: "valet_testing", accessibility: .WhenUnlocked)
        XCTAssertFalse(valet == subclassValet)
        XCTAssertFalse(valet === subclassValet)
    }

    func test_twoValetSubclassesWithSameConfiguration_haveEqualPointers()
    {
        let firstSubclassValet = TestValet(identifier: "valet_testing", accessibility: .WhenUnlocked)
        let secondSubclassValet = TestValet(identifier: "valet_testing", accessibility: .WhenUnlocked)
        XCTAssertNotNil(firstSubclassValet)
        XCTAssert(firstSubclassValet == secondSubclassValet)
        XCTAssert(firstSubclassValet === secondSubclassValet)
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        XCTAssertTrue(valet.canAccessKeychain())
    }

    func test_canAccessKeychain_Performance()
    {
        self.measureBlock {
            self.valet.canAccessKeychain()
        }
    }

    // MARK: stringForKey / setStringForKey

    func test_stringForKey_isNilForInvalidKey()
    {
        XCTAssertNil(valet.stringForKey(key))
    }

    func test_stringForKey_retrievesStringForValidKey()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.stringForKey(key))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        let otherValet = VALValet(identifier: "wat", accessibility: .AfterFirstUnlock)
        XCTAssertNotNil(otherValet)
        XCTAssertNil(otherValet?.stringForKey(key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        let otherValet = VALValet(identifier: "valet_testing", accessibility: .AfterFirstUnlockThisDeviceOnly)
        XCTAssertNotNil(otherValet)
        XCTAssertNil(otherValet?.stringForKey(key))
    }
}
