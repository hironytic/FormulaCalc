//
// SheetViewModelTests.swift
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

class SheetViewModelTests: XCTestCase {
    class MockDesignSheetViewModel: ViewModel, IDesignSheetViewModel {
        let id: String
        
        var title = Observable<String?>.never()
        var itemList = Observable<[IDesignSheetElementViewModel]>.never()
        
        var onNewItem = ActionObserver<Void>().asObserver()
        var onSelectItem = ActionObserver<IDesignSheetElementViewModel>().asObserver()
        var onDeleteItem = ActionObserver<IDesignSheetElementViewModel>().asObserver()
        var onDone = ActionObserver<Void>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockLocator: SheetViewModel.Locator {
        var _sheetStores: [String: ISheetStore] = [:]
        var _sheetItemStores: [String: ISheetItemStore] = [:]
        
        func resolveSheetStore(id: String) -> ISheetStore {
            if let sheetStore = _sheetStores[id] {
                return sheetStore
            }

            
            let result = MockSheetStore(sheet: nil)
            _sheetStores[id] = result
            return result
        }
        
        func resolveSheetItemStore(id: String) -> ISheetItemStore {
            if let sheetItemStore = _sheetItemStores[id] {
                return sheetItemStore
            }
            
            let result = MockSheetItemStore(item: nil)
            _sheetItemStores[id] = result
            return result
        }
        
        func resolveDesignSheetViewModel(id: String) -> IDesignSheetViewModel {
            return MockDesignSheetViewModel(id: id)
        }
    }
    
    var disposeBag: DisposeBag!
    var mockLocator: MockLocator!
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        mockLocator = MockLocator()
        
        let sheet1 = Sheet()
        sheet1.id = "id1"
        sheet1.name = "The sheet"
        
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
        
        let sheetItem1 = SheetItem()
        sheetItem1.id = "sheet_item_one"
        sheetItem1.name = "Item 1"
        sheetItem1.type = .numeric
        sheetItem1.numberValue = 100
        sheetItem1.stringValue = ""
        sheetItem1.formula = ""
        sheetItem1.thousandSeparator = false
        sheetItem1.fractionDigits = 0
        sheetItem1.visible = true
        
        let sheetItems = [sheetItem0, sheetItem1]
        sheet1.items.append(objectsIn: sheetItems)
        
        let sheetStore1 = mockLocator.resolveSheetStore(id: "id1") as! MockSheetStore
        sheetStore1.update(sheet: sheet1)
        sheetStore1.updateItemList(sheetStoreItemListUpdate: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(sheet1.items),
                                                                                      deletions: [],
                                                                                      insertions: Array(0 ..< sheet1.items.count),
                                                                                      modifications: []))
        
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        sheetItemStore0.update(item: sheetItem0)
        
        let sheetItemStore1 = mockLocator.resolveSheetItemStore(id: "sheet_item_one") as! MockSheetItemStore
        sheetItemStore1.update(item: sheetItem1)
    }
    
    override func tearDown() {
        mockLocator = nil
        disposeBag = nil
        
        super.tearDown()
    }

    func testTitle() {
        // SCENARIO:
        // (1) Check the title of the sheet.
        
        let sheetViewModel = SheetViewModel(locator: mockLocator, id: "id1")

        let titleObserver = FulfillObserver(expectation(description: "The sheet title becomes 'The sheet'")) { (title: String?) in
            guard let title = title else { return false }
            return title == "The sheet"
        }
        
        sheetViewModel.title
            .bindTo(titleObserver)
            .addDisposableTo(disposeBag)

        waitForExpectations(timeout: 3.0)
    }
    
    func testItemList() {
        // SCENARIO:
        // (1) Two items are shown on list.
        // (2) The name of the first item is 'Item 0'.
        // (3) The value of the first item is 'foobar'.
        
        let sheetViewModel = SheetViewModel(locator: mockLocator, id: "id1")

        let itemListObserver = FulfillObserver(expectation(description: "There are two items")) { (elementViewModels: [ISheetElementViewModel]) in
            // (1) Two items are shown on list.
            guard elementViewModels.count == 2 else { return false }

            let elementViewModel0 = elementViewModels[0]
            guard elementViewModel0.id == "sheet_item_zero" else { return false }

            // (2) The first one is 'Item 0'.
            let itemNameObserver = FulfillObserver(self.expectation(description: "The first item is Item 0.")) { (name: String?) in
                guard let name = name else { return false }
                return name == "Item 0"
            }
            elementViewModel0.name
                .bindTo(itemNameObserver)
                .addDisposableTo(self.disposeBag)
            
            // (3) The value of the first item is 'foobar'.
            let itemValueObserver = FulfillObserver(self.expectation(description: "The first value is foobar.")) { (value: String?) in
                guard let value = value else { return false }
                return value == "foobar"
            }
            elementViewModel0.value
                .bindTo(itemValueObserver)
                .addDisposableTo(self.disposeBag)
            
            return true
        }
        
        sheetViewModel.itemList
            .bindTo(itemListObserver)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testTapDesignButton() {
        // SCENARIO:
        // (1) User taps design button.
        // (2) The design view is shown with same sheet ID.
        
        let sheetViewModel = SheetViewModel(locator: mockLocator, id: "id1")

        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) The design view is shown with same sheet ID.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockDesignSheetViewModel else { return false }
            return viewModel.id == "id1"
        }
        
        sheetViewModel.message
            .bindTo(messageObserver)
            .addDisposableTo(disposeBag)
        
        // (1) User taps design button.
        sheetViewModel.onTapDesignButton.onNext(())

        waitForExpectations(timeout: 3.0)
    }
}
