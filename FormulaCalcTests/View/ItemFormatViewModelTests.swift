//
// ItemFormatViewModelTests.swift
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

class ItemFormatViewModelTests: XCTestCase {
    
    class MockLocator: ItemFormatViewModel.Locator {
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
    
    func testThousandSeparator() {
        // SCENARIO:
        // (1) The thousand-separator is true.
        // (2) User changes it to false.
        // (3) The value is updated by SheetItemStore
        // (4) It is refrected to UI

        let viewModel = ItemFormatViewModel(locator: mockLocator, id: "sheet_item_zero")

        let thousandSeparator = viewModel.items
            .flatMapLatest { items -> Observable<Bool> in
                if items.thousandSeparator.count == 1 {
                    return items.thousandSeparator[0].thousandSeparator
                } else {
                    return Observable.never()
                }
            }
    
        let thousandSeparatorObserver = FulfillObserver(expectation(description: "The thousand separator is true" )) { (ts: Bool) in
            // (1) The thousand-separator is true.
            return ts
        }
        
        thousandSeparator
            .bind(to: thousandSeparatorObserver)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 3.0)

        let expectUpdateType = expectation(description: "OnUpdateThousandSeparator is fired")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        var updateCount = 0
        sheetItemStore0.updateThousandSeparatorHandler = { value in
            updateCount += 1
            
            // (3) The value is updated by SheetItemStore
            if !value {
                expectUpdateType.fulfill()
            }
            if let sheetItem = sheetItemStore0.item {
                sheetItem.thousandSeparator = value
                sheetItemStore0.update(item: sheetItem)
            }
        }
        
        thousandSeparatorObserver.reset(expectation(description: "The value is changed to false")) { (ts: Bool) in
            // (4) It is refrected to UI
            return !ts
        }
        
        // (2) User changes it to false.
        viewModel.items
            .filter { $0.thousandSeparator.count == 1 }
            .take(1)
            .subscribe(onNext: { items in
                items.thousandSeparator[0].onChangeThousandSeparator.onNext(false)
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(updateCount, 1)
    }
    
    func testFractionDigitsOptions() {
        // SCENARIO:
        // (1) There are seven options about fraction digits.
        
        let viewModel = ItemFormatViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let optionNames = viewModel.items
            .flatMapLatest { items -> Observable<[String?]> in
                return Observable.combineLatest(items.fractionDigits.map({ $0.name })) { $0 }
            }

        let optionNamesObserver = FulfillObserver(expectation(description: "There are 7 options (auto, 0, 1, ..., 5)")) { (optionNames: [String?]) in
            // (1) There are seven options about fraction digits.
            guard optionNames.count == 7 else { return false }
            guard optionNames[0] == ResourceUtils.getString(R.String.fractionDigitsAuto) else { return false }
            guard optionNames[1] == "0" else { return false }
            guard optionNames[2] == "1" else { return false }
            guard optionNames[3] == "2" else { return false }
            guard optionNames[4] == "3" else { return false }
            guard optionNames[5] == "4" else { return false }
            guard optionNames[6] == "5" else { return false }
            return true
        }
        
        optionNames
            .bind(to: optionNamesObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testFractionDigitsChange() {
        // SCENARIO:
        // (1) "2" is checked on fraction digits list.
        // (2) User taps "auto".
        // (3) The value is updated by SheetItemStore
        // (4) It is refrected to UI
        
        let viewModel = ItemFormatViewModel(locator: mockLocator, id: "sheet_item_zero")

        let accessoryTypes = viewModel.items
            .flatMapLatest { items -> Observable<[UITableViewCellAccessoryType]> in
                return Observable.combineLatest(items.fractionDigits.map({ $0.accessoryType })) { $0 }
            }
        
        let accessoryTypesObserver = FulfillObserver(expectation(description: "Only '2' is checked")) { (accessoryTypes: [UITableViewCellAccessoryType]) in
            // (1) "2" is checked on fraction digits list.
            guard accessoryTypes.count == 7 else { return false }
            guard accessoryTypes[0] == .none else { return false }
            guard accessoryTypes[1] == .none else { return false }
            guard accessoryTypes[2] == .none else { return false }
            guard accessoryTypes[3] == .checkmark else { return false }
            guard accessoryTypes[4] == .none else { return false }
            guard accessoryTypes[5] == .none else { return false }
            guard accessoryTypes[6] == .none else { return false }
            return true
        }
        
        accessoryTypes
            .bind(to: accessoryTypesObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)

        let expectUpdateFractionDigits = expectation(description: "OnUpdateFractionDigits is fired")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        var updateCount = 0
        sheetItemStore0.updateFractionDigitsHandler = { fractionDigits in
            updateCount += 1
            
            // (3) The value is updated by SheetItemStore
            if fractionDigits == -1 {
                expectUpdateFractionDigits.fulfill()
            }
            if let sheetItem = sheetItemStore0.item {
                sheetItem.fractionDigits = fractionDigits
                sheetItemStore0.update(item: sheetItem)
            }
        }

        accessoryTypesObserver.reset(expectation(description: "'auto' is checked")) { (accessoryTypes: [UITableViewCellAccessoryType]) in
            // (4) It is refrected to UI
            guard accessoryTypes.count == 7 else { return false }
            guard accessoryTypes[0] == .checkmark else { return false }
            guard accessoryTypes[1] == .none else { return false }
            guard accessoryTypes[2] == .none else { return false }
            guard accessoryTypes[3] == .none else { return false }
            guard accessoryTypes[4] == .none else { return false }
            guard accessoryTypes[5] == .none else { return false }
            guard accessoryTypes[6] == .none else { return false }
            return true
        }

        // (2) User taps "auto".
        viewModel.items
            .filter { $0.fractionDigits.count == 7 }
            .take(1)
            .subscribe(onNext: { items in
                viewModel.onSelectFractionDigits.onNext(items.fractionDigits[0])
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(updateCount, 1)
    }
}
