//
// SheetListStoreTests.swift
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
@testable import FormulaCalc

class SheetListStoreTests: XCTestCase {
    class TestLocator: SheetListStore.Locator {
        var sheetDatabase: ISheetDatabase
        init(sheetDatabase: ISheetDatabase) {
            self.sheetDatabase = sheetDatabase
        }

        func resolveErrorStore() -> IErrorStore {
            return ErrorStore.sharedInstance
        }

        func resolveSheetDatabase() -> ISheetDatabase {
            return sheetDatabase
        }
    }
    
    var disposeBag: DisposeBag!
    var testLocator: TestLocator!
    var sheetListStore: SheetListStore!
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        let testSheetDatabase = TestSheetDatabase(inMemoryIdentifier: "SheetListStoreTests")
        testLocator = TestLocator(sheetDatabase: testSheetDatabase)
        sheetListStore = SheetListStore(locator: testLocator)
    }
    
    override func tearDown() {
        sheetListStore = nil
        testLocator = nil
        disposeBag = nil
        
        super.tearDown()
    }
    
    func testNewSheet() {
        // Initially there are no items
        let updateObserver = FulfillObserver(expectation(description: "There are no items")) { (update: SheetListStoreUpdate) in
            return update.sheetList.count == 0
        }
        sheetListStore.update
            .bindTo(updateObserver)
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        // Add one item
        updateObserver.reset(expectation(description: "Came one item")) { (update: SheetListStoreUpdate) in
            guard update.sheetList.count == 1 else { return false }
            guard update.insertions.count == 1 else { return false }
            guard update.deletions.count == 0 else { return false }
            guard update.modifications.count == 0 else { return false }
            
            let insertedIndex = update.insertions.first!
            let inserted = update.sheetList[update.sheetList.index(update.sheetList.startIndex, offsetBy: IntMax(insertedIndex))]
            return inserted.name == "First Sheet"
        }
        sheetListStore.onCreateNewSheet.onNext("First Sheet")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testNewSheet2() {
        sheetListStore.onCreateNewSheet.onNext("New Sheet")

        var newSheet: Sheet? = nil
        let updateObserver = FulfillObserver(expectation(description: "There are no items")) { (update: SheetListStoreUpdate) in
            if update.sheetList.count == 1 {
                newSheet = update.sheetList.first!
                return true
            }
            return false
        }
        sheetListStore.update
            .bindTo(updateObserver)
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 3.0, handler: nil)

        if let newSheet = newSheet {
            XCTAssertEqual(newSheet.name, "New Sheet")
            XCTAssert(!newSheet.id.isEmpty)
            XCTAssertEqual(newSheet.items.count, 0)
        } else {
            XCTFail()
        }
    }
    
    func testDeleteSheet() {
        sheetListStore.onCreateNewSheet.onNext("Sheet 1")
        sheetListStore.onCreateNewSheet.onNext("Sheet 2")
        sheetListStore.onCreateNewSheet.onNext("Sheet 3")
        sheetListStore.onCreateNewSheet.onNext("Sheet 4")

        var sheet2Id: String? = nil
        let updateObserver = FulfillObserver(expectation(description: "There are four items")) { (update: SheetListStoreUpdate) in
            if update.sheetList.count == 4 {
                sheet2Id = update.sheetList.first(where: { $0.name == "Sheet 2" }).map({ $0.id })
                return true
            }
            return false
        }
        sheetListStore.update
            .bindTo(updateObserver)
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 3.0, handler: nil)

        XCTAssertNotNil(sheet2Id, "'Sheet 2' should be found")
        if let sheet2Id = sheet2Id {
            updateObserver.reset(expectation(description: "There are three items then")) { (update: SheetListStoreUpdate) in
                if update.sheetList.count == 3 {
                    if !update.sheetList.contains(where: { $0.name == "Sheet 2" }) {
                        return true
                    }
                }
                return false
            }
            sheetListStore.onDeleteSheet.onNext(sheet2Id)
            waitForExpectations(timeout: 3.0, handler: nil)
        }
    }
}
