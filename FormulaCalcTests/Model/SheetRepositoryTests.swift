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
        func newSheet(id: String, name: String) -> Sheet {
            let sheet = Sheet()
            sheet.id = id
            sheet.name = name
            return sheet
        }
        let testData = [
            newSheet(id: "sheet-1", name: "Sheet 1"),
            newSheet(id: "sheet-2", name: "Sheet 2"),
            newSheet(id: "sheet-3", name: "Sheet 3"),
            newSheet(id: "sheet-4", name: "Sheet 4"),
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

        changeObserver.reset(expectation(description: "Sheet name shoule be changed")) { (sheet: Sheet?) in
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
}
