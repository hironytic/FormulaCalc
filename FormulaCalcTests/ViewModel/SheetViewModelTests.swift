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
    
    class MockSheetStore: ISheetStore {
        let update: Observable<Sheet?>
        let itemListUpdate: Observable<SheetStoreItemListUpdate>
        
        let onUpdateName = ActionObserver</* newName: */ String>().asObserver()
        var onNewItem = ActionObserver<Void>().asObserver()
        var onDeleteItem = ActionObserver</* id: */ String>().asObserver()
        
        init(id: String) {
            let sheet = Sheet()
            sheet.id = id
            sheet.name = "The sheet"
            
            let sheetItem0 = SheetItem()
            sheetItem0.id = "sheet_item_zero"
            sheetItem0.name = "Item 0"
            
            let sheetItem1 = SheetItem()
            sheetItem1.id = "sheet_item_one"
            sheetItem1.name = "Item 1"
            
            let sheetItems = [sheetItem0, sheetItem1]
            
            sheet.items.append(objectsIn: sheetItems)
            
            update = Observable.just(sheet)
            itemListUpdate = Observable.just(SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(sheetItems),
                                                                      deletions: [],
                                                                      insertions: [0, 1],
                                                                      modifications: []))
        }
    }
    
    class MockSheetItemStore: ISheetItemStore {
        var update: Observable<SheetItem?>
        
        var onUpdateName: AnyObserver</* name: */ String>
        var onUpdateType: AnyObserver</* type: */ SheetItemType>
        var onUpdateNumberValue: AnyObserver</* numberValue: */ Double>
        var onUpdateStringValue: AnyObserver</* stringValue: */ String>
        var onUpdateFormula: AnyObserver</* formula: */ String>
        var onUpdateThousandSeparator: AnyObserver</* thousandSeparator: */ Bool>
        var onUpdateFractionDigits: AnyObserver</* fractionDigits: */ Int>

        var _update: Variable<SheetItem?>
        var _onUpdateName = ActionObserver</* name: */ String>()
        var _onUpdateType = ActionObserver</* type: */ SheetItemType>()
        var _onUpdateNumberValue = ActionObserver</* numberValue: */ Double>()
        var _onUpdateStringValue = ActionObserver</* stringValue: */ String>()
        var _onUpdateFormula = ActionObserver</* formula: */ String>()
        var _onUpdateThousandSeparator = ActionObserver</* thousandSeparator: */ Bool>()
        var _onUpdateFractionDigits = ActionObserver</* fractionDigits: */ Int>()
        
        init(item: SheetItem?) {
            _update = Variable(item)
            update = _update.asObservable()
            
            onUpdateName = _onUpdateName.asObserver()
            onUpdateType = _onUpdateType.asObserver()
            onUpdateNumberValue = _onUpdateNumberValue.asObserver()
            onUpdateStringValue = _onUpdateStringValue.asObserver()
            onUpdateFormula = _onUpdateFormula.asObserver()
            onUpdateThousandSeparator = _onUpdateThousandSeparator.asObserver()
            onUpdateFractionDigits = _onUpdateFractionDigits.asObserver()
        }
        
        func notify(item: SheetItem?) {
            _update.value = item
        }
    }
    
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
        func resolveSheetStore(id: String) -> ISheetStore {
            return MockSheetStore(id: id)
        }
        
        func resolveSheetItemStore(id: String) -> ISheetItemStore {
            let item = SheetItem()
            item.id = id
            switch id {
            case "sheet_item_zero":
                item.name = "Item 0"
                item.type = .string
                item.numberValue = 0
                item.stringValue = "foobar"
                item.formula = ""
                item.thousandSeparator = true
                item.fractionDigits = 2
            case "sheet_item_one":
                item.name = "Item 1"
                item.type = .numeric
                item.numberValue = 100
                item.stringValue = ""
                item.formula = ""
                item.thousandSeparator = false
                item.fractionDigits = 0
            default:
                break
            }
            
            return MockSheetItemStore(item: item)
        }
        
        func resolveDesignSheetViewModel(id: String) -> IDesignSheetViewModel {
            return MockDesignSheetViewModel(id: id)
        }
    }
    
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        
        super.tearDown()
    }

    func testTitle() {
        // SCENARIO:
        // (1) Check the title of the sheet.
        
        let sheetViewModel = SheetViewModel(locator: MockLocator(), id: "id1")

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
        
        let sheetViewModel = SheetViewModel(locator: MockLocator(), id: "id1")

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
        
        let sheetViewModel = SheetViewModel(locator: MockLocator(), id: "id1")

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
