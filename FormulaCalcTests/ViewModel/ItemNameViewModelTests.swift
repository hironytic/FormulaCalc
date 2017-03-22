//
// ItemNameViewModelTests.swift
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

class ItemNameViewModelTests: XCTestCase {
    
    class MockLocator: ItemNameViewModel.Locator {
        var _sheetItemStores: [String: ISheetItemStore] = [:]
        
        func resolveSheetItemStore(id: String) -> ISheetItemStore {
            if let sheetItemStore = _sheetItemStores[id] {
                return sheetItemStore
            }
            
            let result = MockSheetItemStore(item: nil)
            _sheetItemStores[id] = result
            return result
        }
    }

    var disposeBag: DisposeBag!
    var mockLocator: MockLocator!
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        mockLocator = MockLocator()
        
        let sheetItem0 = SheetItem()
        sheetItem0.id = "sheet_item_zero"
        sheetItem0.name = "Item 0"
        sheetItem0.type = .string
        sheetItem0.numberValue = 0
        sheetItem0.stringValue = "foobar"
        sheetItem0.formula = ""
        sheetItem0.thousandSeparator = true
        sheetItem0.fractionDigits = 2
        sheetItem0.visible = true
        
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: sheetItem0.id) as! MockSheetItemStore
        sheetItemStore0.update(item: sheetItem0)
    }
    
    override func tearDown() {
        mockLocator = nil
        disposeBag = nil
        
        super.tearDown()
    }
    
    func testName() {
        // SCENARIO:
        // (1) Check the name of the item.
        
        let viewModel = ItemNameViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let nameObserver = FulfillObserver(expectation(description: "The item name becomes 'Item 0'")) { (name: String?) in
            guard let name = name else { return false }
            return name == "Item 0"
        }
        
        viewModel.name
            .bindTo(nameObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testChangeName() {
        // SCENARIO:
        // (1) User changes name
        // (2) The name is updated by SheetItemStore
        // (3) It is refrected to UI

        let viewModel = ItemNameViewModel(locator: mockLocator, id: "sheet_item_zero")

        let expectUpdateName = expectation(description: "OnUpdateName is fired")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        var updateCount = 0
        sheetItemStore0.updateNameHandler = { name in
            updateCount += 1
            
            // (2) The name is updated by SheetItemStore
            if name == "New name" {
                expectUpdateName.fulfill()
            }
            if let sheetItem = sheetItemStore0.item {
                sheetItem.name = name
                sheetItemStore0.update(item: sheetItem)
            }
        }
        
        let nameObserver = FulfillObserver(expectation(description: "The item name becomes 'New name'")) { (name: String?) in
            // (3) It is refrected to UI
            guard let name = name else { return false }
            return name == "New name"
        }
        
        viewModel.name
            .bindTo(nameObserver)
            .disposed(by: disposeBag)

        // (1) User changes name
        viewModel.onNameChanged.onNext("New")
        viewModel.onNameChanged.onNext("New name")
        viewModel.onNameEditingDidEnd.onNext(())
        
        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(updateCount, 1)
    }
}
