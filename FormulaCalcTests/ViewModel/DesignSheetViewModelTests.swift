//
// DesignSheetViewModelTests.swift
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

class DesignSheetViewModelTests: XCTestCase {
    class MockItemViewModel: ViewModel, IItemViewModel {
        let id: String
        
        let title = Observable<String?>.never()
        let name = Observable<String?>.never()
        let type = Observable<String?>.never()
        let formula = Observable<String?>.never()
        let visible = Observable<Bool>.never()
        let format = Observable<String?>.never()
        
        let onSelectName = ActionObserver<Void>().asObserver()
        let onSelectType = ActionObserver<Void>().asObserver()
        let onSelectFormula = ActionObserver<Void>().asObserver()
        let onChangeVisible = ActionObserver<Bool>().asObserver()
        let onSelectFormat = ActionObserver<Void>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockLocator: DesignSheetViewModel.Locator {
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
        
        func resolveItemViewModel(id: String) -> IItemViewModel {
            return MockItemViewModel(id: id)
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
        
        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")

        let titleObserver = FulfillObserver(expectation(description: "The sheet title becomes 'The sheet'")) { (title: String?) in
            guard let title = title else { return false }
            return title == "The sheet"
        }
        
        viewModel.title
            .bindTo(titleObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testItemList() {
        // SCENARIO:
        // (1) Two items are shown on list.
        // (2) The name of the first item is 'Item 0'.
        // (3) The type of the first item is string.
        // (4) The invisible mark of the first item is hidden.

        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")
        
        let itemListObserver = FulfillObserver(expectation(description: "There are two items")) { (elementViewModels: [IDesignSheetElementViewModel]) in
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
                .disposed(by: self.disposeBag)
            
            // (3) The value of the first item is 'foobar'.
            let itemTypeObserver = FulfillObserver(self.expectation(description: "The type of the first item is string.")) { (type: String?) in
                guard let type = type else { return false }
                return type == ResourceUtils.getString(R.String.sheetItemTypeString)
            }
            elementViewModel0.type
                .bindTo(itemTypeObserver)
                .disposed(by: self.disposeBag)
            
            // (4) The invisible mark of the first item is hidden.
            let invisibleMarkObserver = FulfillObserver(self.expectation(description: "The invisible mark of the first item is hidden")) { (hidden: Bool) in
                return hidden
            }
            elementViewModel0.invisibleMarkHidden
                .bindTo(invisibleMarkObserver)
                .disposed(by: self.disposeBag)
            
            return true
        }
        
        viewModel.itemList
            .bindTo(itemListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnNewItem() {
        // SCENARIO:
        // (1) Two items are shown on list.
        // (2) User taps "new item" button.
        // (3) The new item is added and appears on list
        
        let sheetStore1 = mockLocator.resolveSheetStore(id: "id1") as! MockSheetStore
        sheetStore1.newItemHandler = {
            if let sheet = sheetStore1.sheet {
                let newSheetItem = SheetItem()
                newSheetItem.id = "sheet_item_two"
                newSheetItem.name = "Item 2"
                newSheetItem.type = .numeric
                newSheetItem.numberValue = 200
                newSheetItem.stringValue = ""
                newSheetItem.formula = ""
                newSheetItem.thousandSeparator = true
                newSheetItem.fractionDigits = 0
                newSheetItem.visible = false
            
                let sheetItemStore2 = self.mockLocator.resolveSheetItemStore(id: "sheet_item_two") as! MockSheetItemStore
                sheetItemStore2.update(item: newSheetItem)
                
                sheet.items.append(newSheetItem)
                sheetStore1.update(sheet: sheet)
                sheetStore1.updateItemList(sheetStoreItemListUpdate: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(sheet.items),
                                                                                              deletions: [],
                                                                                              insertions: [2],
                                                                                              modifications: []))
                
                sheetStore1.newItemHandler = {
                    XCTFail("New Item is called twice")
                }
            }
        }
        
        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")
        
        let itemListObserver = FulfillObserver(expectation(description: "There are two items")) { (elementViewModels: [IDesignSheetElementViewModel]) in
            // (1) Two items are shown on list.
            return elementViewModels.count == 2
        }

        viewModel.itemList
            .bindTo(itemListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)

        itemListObserver.reset(expectation(description: "The new item is added")) { (elementViewModels: [IDesignSheetElementViewModel]) in
            // (3) The new item is added and appears on list
            return elementViewModels.count == 3
        }

        // (2) User taps "new item" button.
        viewModel.onNewItem.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnSelectItem() {
        // SCENARIO:
        // (1) Two items are shown on list.
        // (2) User selects the first item.
        // (3) It transit to the scene whose view model is IItemViewModel.
        
        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")
        
        var itemToSelect: IDesignSheetElementViewModel! = nil
        let itemListObserver = FulfillObserver(expectation(description: "There are two items")) { (elementViewModels: [IDesignSheetElementViewModel]) in
            // (1) Two items are shown on list.
            guard elementViewModels.count == 2 else { return false }
            itemToSelect = elementViewModels[0]
            return true
        }
        
        viewModel.itemList
            .bindTo(itemListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (3) It transit to the scene whose view model is IItemViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockItemViewModel else { return false }
            return viewModel.id == "sheet_item_zero"
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (2) User selects the first item.
        XCTAssertNotNil(itemToSelect)
        viewModel.onSelectItem.onNext(itemToSelect!)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnDeleteItem() {
        // SCENARIO:
        // (1) Two items are shown on list.
        // (2) User taps "delete" button.
        // (3) The item is deleted and disappears from list
     
        let sheetStore1 = mockLocator.resolveSheetStore(id: "id1") as! MockSheetStore
        sheetStore1.deleteItemHandler = { id in
            XCTAssertEqual(id, "sheet_item_zero")
            
            let sheet = sheetStore1.sheet!
            sheet.items.remove(objectAtIndex: 0)

            sheetStore1.update(sheet: sheet)
            sheetStore1.updateItemList(sheetStoreItemListUpdate: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(sheet.items),
                                                                                          deletions: [0],
                                                                                          insertions: [],
                                                                                          modifications: []))

            sheetStore1.deleteItemHandler = { _ in
                XCTFail("Delete Item is called twice")
            }
        }
        
        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")

        var itemToDelete: IDesignSheetElementViewModel! = nil
        let itemListObserver = FulfillObserver(expectation(description: "There are two items")) { (elementViewModels: [IDesignSheetElementViewModel]) in
            // (1) Two items are shown on list.
            guard elementViewModels.count == 2 else { return false }
            itemToDelete = elementViewModels[0]
            return true
        }
        
        viewModel.itemList
            .bindTo(itemListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
        
        itemListObserver.reset(expectation(description: "The item is deleted")) { (elementViewModels: [IDesignSheetElementViewModel]) in
            // (3) The item is deleted and disappears from list
            guard elementViewModels.count == 1 else { return false }
            return elementViewModels[0].id == "sheet_item_one"
        }
        
        // (2) User taps "delete" button.
        XCTAssertNotNil(itemToDelete)
        viewModel.onDeleteItem.onNext(itemToDelete!)

        waitForExpectations(timeout: 3.0)
    }
    
    func testOnDone() {
        // SCENARIO:
        // (1) User taps done button.
        // (2) The design sheet view is dismissed.

        let viewModel = DesignSheetViewModel(locator: mockLocator, id: "id1")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) The design sheet view is dismissed.
            guard let dismissingMessage = message as? DismissingMessage else { return false }
            return dismissingMessage.type == .dismiss
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User taps done button.
        viewModel.onDone.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
}
