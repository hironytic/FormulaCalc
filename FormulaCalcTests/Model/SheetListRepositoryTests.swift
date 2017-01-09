//
// SheetListRepositoryTests.swift
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

class SheetListRepositoryTests: XCTestCase {
    class TestContext: ISheetListRepositoryContext {
        var sheetDatabase: ISheetDatabase
        var errorStore: IErrorStore { get { return ErrorStore.sharedInstance } }
        init(sheetDatabase: ISheetDatabase) {
            self.sheetDatabase = sheetDatabase
        }
    }

    var disposeBag: DisposeBag!
    var testContext: TestContext!
    var sheetListRepository: SheetListRepository!
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        let testSheetDatabase = TestSheetDatabase(inMemoryIdentifier: "SheetListRepositoryTests")
        testContext = TestContext(sheetDatabase: testSheetDatabase)
        sheetListRepository = SheetListRepository(context: testContext)
    }
    
    override func tearDown() {
        sheetListRepository = nil
        testContext = nil
        disposeBag = nil
        
        super.tearDown()
    }
    
    func testNewSheet() {
        // Initially there are no items
        let changeObserver = FulfillObserver(expectation(description: "There are no items")) { (change: SheetListRepositoryChange) in
            return change.sheetList.count == 0
        }
        sheetListRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        // Add one item
        changeObserver.reset(expectation(description: "Came one item")) { (change: SheetListRepositoryChange) in
            guard change.sheetList.count == 1 else { return false }
            guard change.insertions.count == 1 else { return false }
            guard change.deletions.count == 0 else { return false }
            guard change.modifications.count == 0 else { return false }
            
            let insertedIndex = change.insertions.first!
            let inserted = change.sheetList[change.sheetList.index(change.sheetList.startIndex, offsetBy: IntMax(insertedIndex))]
            return inserted.name == "First Sheet"
        }
        sheetListRepository.onCreateNewSheet.onNext("First Sheet")
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testNewSheet2() {
        sheetListRepository.onCreateNewSheet.onNext("New Sheet")

        var newSheet: Sheet? = nil
        let changeObserver = FulfillObserver(expectation(description: "There are no items")) { (change: SheetListRepositoryChange) in
            if change.sheetList.count == 1 {
                newSheet = change.sheetList.first!
                return true
            }
            return false
        }
        sheetListRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
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
        sheetListRepository.onCreateNewSheet.onNext("Sheet 1")
        sheetListRepository.onCreateNewSheet.onNext("Sheet 2")
        sheetListRepository.onCreateNewSheet.onNext("Sheet 3")
        sheetListRepository.onCreateNewSheet.onNext("Sheet 4")

        var sheet2Id: String? = nil
        let changeObserver = FulfillObserver(expectation(description: "There are four items")) { (change: SheetListRepositoryChange) in
            if change.sheetList.count == 4 {
                sheet2Id = change.sheetList.first(where: { $0.name == "Sheet 2" }).map({ $0.id })
                return true
            }
            return false
        }
        sheetListRepository.change
            .bindTo(changeObserver)
            .addDisposableTo(disposeBag)
        waitForExpectations(timeout: 3.0, handler: nil)

        XCTAssertNotNil(sheet2Id, "'Sheet 2' should be found")
        if let sheet2Id = sheet2Id {
            changeObserver.reset(expectation(description: "There are three items then")) { (change: SheetListRepositoryChange) in
                if change.sheetList.count == 3 {
                    if !change.sheetList.contains(where: { $0.name == "Sheet 2" }) {
                        return true
                    }
                }
                return false
            }
            sheetListRepository.onDeleteSheet.onNext(sheet2Id)
            waitForExpectations(timeout: 3.0, handler: nil)
        }
    }
}
