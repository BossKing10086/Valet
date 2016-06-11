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
    static let identifier = "valet_testing"
    let valet = VALValet(identifier: identifier, accessibility: .WhenUnlocked)!
    let subclassValet = TestValet(identifier: identifier, accessibility: .WhenUnlocked)!
    let key = "key"
    let passcode = "topsecret"

    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
        subclassValet.removeAllObjects()
    }

    // MARK: Equality

    func test_twoValetsWithSameConfiguration_haveEqualPointers()
    {
        let otherValet = VALValet(identifier: ValetTests.identifier, accessibility: .WhenUnlocked)
        XCTAssert(otherValet == valet)
        XCTAssert(otherValet === valet)
    }

    func test_valetSubclassWithSameConfiguration_doesNotHaveEqualPointer()
    {
        XCTAssertFalse(valet == subclassValet)
        XCTAssertFalse(valet === subclassValet)
    }

    func test_twoValetSubclassesWithSameConfiguration_haveEqualPointers()
    {
        let secondSubclassValet = TestValet(identifier: ValetTests.identifier, accessibility: .WhenUnlocked)
        XCTAssertNotNil(subclassValet)
        XCTAssert(subclassValet == secondSubclassValet)
        XCTAssert(subclassValet === secondSubclassValet)
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

        let otherValet = VALValet(identifier: ValetTests.identifier, accessibility: .AfterFirstUnlockThisDeviceOnly)
        XCTAssertNotNil(otherValet)
        XCTAssertNil(otherValet?.stringForKey(key))
    }

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        XCTAssertNil(valet.stringForKey(key))
        valet.setString("1", forKey: key)
        XCTAssertEqual("1", valet.stringForKey(key))
        valet.setString("2", forKey: key)
        XCTAssertEqual("2", valet.stringForKey(key))
    }

    func disabled_test_setStringForKey_failsWithInvalidArguments()
    {
        // TODO: nilValue tap dance test
        var nilVar: String?
        nilVar = nil
        XCTAssertFalse(valet.setString(nilVar!, forKey: key))
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let removeQueue = dispatch_queue_create("Remove Object Queue", DISPATCH_QUEUE_CONCURRENT)

        for _ in 1...50 {
            dispatch_async(setQueue, { XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key)) })
            dispatch_async(removeQueue, { XCTAssertTrue(self.valet.removeObjectForKey(self.key)) })
        }

        let setQueueExpectation = self.expectationWithDescription("Set String Queue")
        let removeQueueExpectation = self.expectationWithDescription("Remove String Queue")

        dispatch_barrier_async(setQueue, { setQueueExpectation.fulfill() })
        dispatch_barrier_async(removeQueue, { removeQueueExpectation.fulfill() })

        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenOnAnotherThread()
    {
        let setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT)

        let expectation = self.expectationWithDescription(#function)

        dispatch_async(setStringQueue) {
            XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key))
            dispatch_async(stringForKeyQueue, { 
                XCTAssertEqual(self.valet.stringForKey(self.key), self.passcode)
                expectation.fulfill()
            })
        }

        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenToValetAllocatedOnDifferentThread()
    {
        let setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT)

        let backgroundIdentifier = "valet_background_testing"
        let expectation = self.expectationWithDescription(#function)

        dispatch_async(setStringQueue) {
            let backgroundValet = VALValet(identifier: backgroundIdentifier, accessibility: .WhenUnlocked)!
            XCTAssertTrue(backgroundValet.setString(self.passcode, forKey: self.key))
            dispatch_async(stringForKeyQueue, {
                XCTAssertEqual(backgroundValet.stringForKey(self.key), self.passcode)
                expectation.fulfill()
            })
        }

        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    // MARK: Removal

    // MARK: Migration

    func test_migrateObjectsMatchingQuery_failsIfNoItemsMatchQuery()
    {
        let noItemsFoundError = VALMigrationError.NoItemsToMigrateFound

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertEqual(noItemsFoundError, _migrationError(valet.migrateObjectsMatchingQuery(queryWithNoMatches, removeOnCompletion: false)))
        XCTAssertEqual(noItemsFoundError, _migrationError(valet.migrateObjectsMatchingQuery(queryWithNoMatches, removeOnCompletion: true)))

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, _migrationError(subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: false)))
        XCTAssertEqual(noItemsFoundError, _migrationError(subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: true)))
    }

    func test_migrateObjectsMatchingQuery_failsIfQueryHasNoInputClass()
    {
        valet.setString(passcode, forKey: key)

        // Test for base query success.
        XCTAssertNil(subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: false))
        XCTAssertEqual(passcode, subclassValet.stringForKey(key))

        var mutableQuery = valet.baseQuery
        mutableQuery.removeValueForKey(kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(VALMigrationError.InvalidQuery, _migrationError(subclassValet.migrateObjectsMatchingQuery(mutableQuery, removeOnCompletion: false)))
    }

    func test_migrateObjectsMatchingQuery_failsForBadQueries()
    {
        let invalidQueryError = VALMigrationError.InvalidQuery

        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery([:], removeOnCompletion: false)))
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery([:], removeOnCompletion: true)))

        var invalidQuery: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchLimit as String: kSecMatchLimitOne as String
        ]
        // Migration queries should have kSecMatchLimit set to .All
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnData as String: kCFBooleanTrue as AnyObject
        ]
        // Migration queries do not support kSecReturnData
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnRef as String: kCFBooleanTrue as AnyObject
        ]
        // Migration queries do not support kSecReturnRef
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnPersistentRef as String: kCFBooleanFalse as AnyObject
        ]
        // Migration queries must have kSecReturnPersistentRef set to true
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)))


        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnAttributes as String: kCFBooleanFalse as AnyObject
        ]
        // Migration queries must have kSecReturnAttributes set to true
        XCTAssertEqual(invalidQueryError, _migrationError(valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)))

        // TODO: Secure Enclave
    }

    func test_migrateObjectsMatchingQuery_bailsOutIfConflictExistsInQueryResult()
    {
        let migrationValet = VALValet(identifier: "Migrate_Me", accessibility: .AfterFirstUnlock)!
        let conflictingValet = TestValet(identifier: "Migrate_Me", accessibility: .AfterFirstUnlock)!

        migrationValet.setString(passcode, forKey: key)
        conflictingValet.setString(passcode, forKey:key)
    }

    // MARK: Private - Helpers

    // The NSError.code -> VALMigrationError conversion is gross right now:
    private func _migrationError(error: NSError?) -> VALMigrationError
    {
        return VALMigrationError(rawValue: UInt(error!.code))!
    }
}


#if os(OSX)
class ValetMacTests: XCTestCase
{
    func test_setStringForKey_neutralizesMacOSAccessControlListVuln()
    {
        // TODO: Mac Access Control List VULN
        XCTFail("Write me pls")
    }
}
#endif
