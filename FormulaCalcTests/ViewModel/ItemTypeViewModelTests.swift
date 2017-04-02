//
// ItemTypeViewModelTests.swift
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

private typealias R = Resource

class ItemTypeViewModelTests: XCTestCase {

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

    func testOptions() {
        // SCENARIO:
        // (1) Check the options.
        
        let viewModel = ItemTypeViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        var listDisposeBag: DisposeBag!
        let exp = expectation(description: "Right options are in the list")
        viewModel.typeList.subscribe (onNext: { list in
            listDisposeBag = DisposeBag()
            
            var conditions = [false, false, false]
            func fulfillCondition(index: Int) {
                conditions[index] = true
                if !conditions.contains(false) {
                    exp.fulfill()
                }
            }
            
            if list.count == 3 {
                list[0].name.subscribe(onNext: { (name: String?) in
                    if name == ResourceUtils.getString(R.String.sheetItemTypeNumeric) {
                        fulfillCondition(index: 0)
                    }
                })
                .disposed(by: listDisposeBag)

                list[1].name.subscribe(onNext: { (name: String?) in
                    if name == ResourceUtils.getString(R.String.sheetItemTypeString) {
                        fulfillCondition(index: 1)
                    }
                })
                .disposed(by: listDisposeBag)

                list[2].name.subscribe(onNext: { (name: String?) in
                    if name == ResourceUtils.getString(R.String.sheetItemTypeFormula) {
                        fulfillCondition(index: 2)
                    }
                })
                .disposed(by: listDisposeBag)
            }
        }, onDisposed: {
            listDisposeBag = nil
        })
        .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testOptionsAccessoryType() {
        // SCENARIO:
        // (1) Check the each option's accessory type.
        
        let viewModel = ItemTypeViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        var listDisposeBag: DisposeBag!
        let exp = expectation(description: "String is only checked")
        viewModel.typeList.subscribe (onNext: { list in
            listDisposeBag = DisposeBag()
            
            var conditions = [false, false, false]
            func fulfillCondition(index: Int) {
                conditions[index] = true
                if !conditions.contains(false) {
                    exp.fulfill()
                }
            }
            
            if list.count == 3 {
                list[0].accessoryType.subscribe(onNext: { (type: UITableViewCellAccessoryType) in
                    if type == .none {
                        fulfillCondition(index: 0)
                    }
                })
                .disposed(by: listDisposeBag)
                
                list[1].accessoryType.subscribe(onNext: { (type: UITableViewCellAccessoryType) in
                    if type == .checkmark {
                        fulfillCondition(index: 1)
                    }
                })
                .disposed(by: listDisposeBag)
                
                list[2].accessoryType.subscribe(onNext: { (type: UITableViewCellAccessoryType) in
                    if type == .none {
                        fulfillCondition(index: 2)
                    }
                })
                .disposed(by: listDisposeBag)
            }
        }, onDisposed: {
            listDisposeBag = nil
        })
        .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testSelectItemType() {
        // SCENARIO:
        // (1) "String" is checked
        // (2) User taps "Numeric"
        // (3) The type is updated to .string by SheetItemStore
        // (4) It is refrected to UI

        let viewModel = ItemTypeViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let accessoryTypes = viewModel.typeList
            .flatMapLatest { (list) -> Observable<(UITableViewCellAccessoryType, UITableViewCellAccessoryType, UITableViewCellAccessoryType)> in
                return Observable
                    .combineLatest(list[0].accessoryType, list[1].accessoryType, list[2].accessoryType, resultSelector: { ($0, $1, $2) })
            }
        
        // (1) "String" is checked
        let accessoryTypeObserver = FulfillObserver(expectation(description: "String is checked")) { (type0: UITableViewCellAccessoryType, type1: UITableViewCellAccessoryType, type2: UITableViewCellAccessoryType) in
            return type0 == .none
                && type1 == .checkmark
                && type2 == .none
        }
        accessoryTypes
            .bindTo(accessoryTypeObserver)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 3.0)

        let expectUpdateType = expectation(description: "OnUpdateType is fired")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        var updateCount = 0
        sheetItemStore0.updateTypeHandler = { type in
            updateCount += 1
            
            // (3) The type is updated to .string by SheetItemStore
            if type == .numeric {
                expectUpdateType.fulfill()
            }
            if let sheetItem = sheetItemStore0.item {
                sheetItem.type = type
                sheetItemStore0.update(item: sheetItem)
            }
        }
        
        // (4) It is refrected to UI
        accessoryTypeObserver.reset(expectation(description: "Nueric is checked")) { (type0: UITableViewCellAccessoryType, type1: UITableViewCellAccessoryType, type2: UITableViewCellAccessoryType) in
            return type0 == .checkmark
                && type1 == .none
                && type2 == .none
            
        }
        
        // (2) User taps "Numeric"
        viewModel.typeList
            .subscribe (onNext: { list in
                viewModel.onSelect.onNext(list[0])
            })
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(updateCount, 1)
    }
}
