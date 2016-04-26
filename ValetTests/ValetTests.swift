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
    let valet = VALValet(identifier: "valet_testing", accessibility: VALAccessibility.WhenUnlocked)!

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
    }

    // MARK: Equality

    func test_twoValetsWithSameConfiguration_haveEqualPointers()
    {
        let otherValet = VALValet(identifier: "valet_testing", accessibility: VALAccessibility.WhenUnlocked)!
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
        XCTAssert(firstSubclassValet == secondSubclassValet)
        XCTAssert(firstSubclassValet === secondSubclassValet)
    }
    
}
