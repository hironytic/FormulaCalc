//
// SheetRepositoryTests.swift
// FormulaCalcTests
//
// Copyright (c) 2017 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import XCTest
import RxSwift
import RealmSwift
@testable import FormulaCalc

class SheetRepositoryTests: XCTestCase {
    class TestContext: ISheetRepositoryContext {
        let sheetDatabase: ISheetDatabase
        let testRealm: Realm? // to keep test data in In-Memory database
        init(sheetDatabase: ISheetDatabase) throws {
            self.sheetDatabase = sheetDatabase
            testRealm = try sheetDatabase.createRealm()
        }
    }
    
    var disposeBag: DisposeBag!
    var testContext: TestContext!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
        let testSheetDatabase = TestSheetDatabase(inMemoryIdentifier: "SheetRepositoryTests")
        testContext = try! TestContext(sheetDatabase: testSheetDatabase)
        
        // test data
        let testData = [
            Sheet(value: ["id": "sheet-1", "name": "Sheet 1"]),
            Sheet(value: ["id": "sheet-2", "name": "Sheet 2"]),
            Sheet(value: ["id": "sheet-3", "name": "Sheet 3"]),
            Sheet(value: ["id": "sheet-4", "name": "Sheet 4", "items": [
                ["id": "item-1", "name": "Item 1", "_type": "numeric", "numberValue": 5.0],
                ["id": "item-2", "name": "Item 2", "_type": "string", "stringValue": ""],
                ["id": "item-3", "name": "Item 3", "_type": "formula", "formula": "1+2"],
            ]]),
        ]
        let realm = try! testSheetDatabase.createRealm()
        try! realm.write {
            realm.add(testData)
        }
    }
    
    override func tearDown() {
        testContext = nil
        disposeBag = nil
        
        super.tearDown()
    }
    
    func testExistingSheet() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-2")
        
        let changeObserver = FulfillObserver(expectation(description: "There is a sheet whose id is 'sheet-2'")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            return sheet.name == "Sheet 2"
        }
        sheetRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testNonexistentSheet() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-x")
        
        let changeObserver = FulfillObserver(expectation(description: "It's not found that a sheet whose id is 'sheet-x'")) { (sheet: Sheet?) in
            return sheet == nil
        }
        sheetRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testUpdateName() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-2")
        
        let changeObserver = FulfillObserver(expectation(description: "There is a sheet whose id is 'sheet-2'")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            return sheet.name == "Sheet 2"
        }
        sheetRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0, handler: nil)

        changeObserver.reset(expectation(description: "Sheet name should be changed")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            return sheet.name == "Renamed"
        }
        sheetRepository.onUpdateName.onNext("Renamed")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testUpdateNonexistentSheetName() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-x")
        
        let errorObserver = FulfillObserver(expectation(description: "Updating nonexistent sheet name causes an error"), nextChecker: { (error: Error) in
            if case SheetRepositoryError.sheetNotFound = error {
                return true
            } else {
                return false
            }
        })
        sheetRepository.error
            .bindTo(errorObserver)
            .addDisposableTo(disposeBag)
        
        sheetRepository.onUpdateName.onNext("Renamed")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testNewItem() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-2")
        
        let changeObserver = FulfillObserver(expectation(description: "There is a sheet whose id is 'sheet-2'")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            return sheet.items.isEmpty
        }
        sheetRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0, handler: nil)

        var newItem: SheetItem? = nil
        changeObserver.reset(expectation(description: "A new item should be added")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            guard !sheet.items.isEmpty else { return false }
            newItem = sheet.items.first
            return true
        }
        sheetRepository.onNewItem.onNext(())
        waitForExpectations(timeout: 3.0, handler: nil)
        
        XCTAssertNotNil(newItem)
        if let newItem = newItem {
            XCTAssert(!newItem.name.isEmpty)
            XCTAssertEqual(newItem.type, .numeric)
        } else {
            XCTFail()
        }
    }
    
    func testNewItemOnNonexistentSheet() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-x")
        
        let errorObserver = FulfillObserver(expectation(description: "Creating new item on nonexistent sheet causes an error"), nextChecker: { (error: Error) in
            if case SheetRepositoryError.sheetNotFound = error {
                return true
            } else {
                return false
            }
        })
        sheetRepository.error
            .bindTo(errorObserver)
            .addDisposableTo(disposeBag)
        
        sheetRepository.onNewItem.onNext(())
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDeleteItem() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-4")
        
        let changeObserver = FulfillObserver(expectation(description: "There is a sheet whose id is 'sheet-4'")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            guard sheet.items.count == 3 else { return false }
            return true
        }
        sheetRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0, handler: nil)
        
        changeObserver.reset(expectation(description: "An item should be deleted")) { (sheet: Sheet?) in
            guard let sheet = sheet else { return false }
            guard sheet.items.count == 2 else { return false }
            return !sheet.items.contains(where: { $0.name == "Item 2" })
        }
        sheetRepository.onDeleteItem.onNext("item-2")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDeleteNonexistentItem() {
        let sheetRepository = try! SheetRepository(context: testContext, id: "sheet-4")
        
        let errorObserver = FulfillObserver(expectation(description: "Creating new item on nonexistent sheet causes an error"), nextChecker: { (error: Error) in
            if case SheetRepositoryError.itemNotFound = error {
                return true
            } else {
                return false
            }
        })
        sheetRepository.error
            .bindTo(errorObserver)
            .addDisposableTo(disposeBag)
        
        sheetRepository.onDeleteItem.onNext("item-x")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
}
