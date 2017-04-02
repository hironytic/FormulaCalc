//
// ItemViewModelTests.swift
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

class ItemViewModelTests: XCTestCase {
    
    class MockItemNameViewModel: IItemNameViewModel {
        let id: String
        
        let name = Observable<String?>.never()
        let onNameChanged = ActionObserver<String?>().asObserver()
        let onNameEditingDidEnd = ActionObserver<Void>().asObserver()

        init(id: String) {
            self.id = id
        }
    }

    class MockItemTypeViewModel: IItemTypeViewModel {
        let id: String
        
        let typeList = Observable<[IItemTypeElementViewModel]>.never()
        let onSelect = ActionObserver<IItemTypeElementViewModel>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockFormulaViewModel: IFormulaViewModel {
        let id: String
        
        let formula = Observable<String?>.never()
        let onFormulaChanged = ActionObserver<String?>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockItemFormatViewModel: IItemFormatViewModel {
        let id: String
        
        let items = Observable<ItemFormatElementViewModels>.never()
        let onSelectFractionDigits = ActionObserver<IFractionsDigitsElementViewModel>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockLocator: ItemViewModel.Locator {
        var _sheetItemStores: [String: ISheetItemStore] = [:]
        
        func resolveSheetItemStore(id: String) -> ISheetItemStore {
            if let sheetItemStore = _sheetItemStores[id] {
                return sheetItemStore
            }
            
            let result = MockSheetItemStore(item: nil)
            _sheetItemStores[id] = result
            return result            
        }
        
        func resolveItemNameViewModel(id: String) -> IItemNameViewModel {
            return MockItemNameViewModel(id: id)
        }
        
        func resolveItemTypeViewModel(id: String) -> IItemTypeViewModel {
            return MockItemTypeViewModel(id: id)
        }
        
        func resolveFormulaViewModel(id: String) -> IFormulaViewModel  {
            return MockFormulaViewModel(id: id)
        }
        
        func resolveItemFormatViewModel(id: String) -> IItemFormatViewModel {
            return MockItemFormatViewModel(id: id)
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

        let sheetItem1 = SheetItem()
        sheetItem1.id = "sheet_item_one"
        sheetItem1.name = "Item 1"
        sheetItem1.type = .formula
        sheetItem1.numberValue = 0
        sheetItem1.stringValue = ""
        sheetItem1.formula = "10+20"
        sheetItem1.thousandSeparator = false
        sheetItem1.fractionDigits = -1
        sheetItem1.visible = false
        
        let sheetItemStore1 = mockLocator.resolveSheetItemStore(id: sheetItem1.id) as! MockSheetItemStore
        sheetItemStore1.update(item: sheetItem1)
    }
    
    override func tearDown() {
        mockLocator = nil
        disposeBag = nil
        
        super.tearDown()
    }

    func testTitle() {
        // SCENARIO:
        // (1) Check the title of the view.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let titleObserver = FulfillObserver(expectation(description: "The item title becomes 'Item 0'")) { (title: String?) in
            guard let title = title else { return false }
            return title == "Item 0"
        }
        
        viewModel.title
            .bindTo(titleObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testName() {
        // SCENARIO:
        // (1) Check the name of the item.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let nameObserver = FulfillObserver(expectation(description: "The item name becomes 'Item 0'")) { (name: String?) in
            guard let name = name else { return false }
            return name == "Item 0"
        }
        
        viewModel.name
            .bindTo(nameObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testType() {
        // SCENARIO:
        // (1) Check the type of the item.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let typeObserver = FulfillObserver(expectation(description: "The item type becomes string")) { (type: String?) in
            guard let type = type else { return false }
            return type == ResourceUtils.getString(R.String.sheetItemTypeString)
        }
        
        viewModel.type
            .bindTo(typeObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testFormulaEmpty() {
        // SCENARIO:
        // (1) Check the formula of the item. (Empty)
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let formulaObserver = FulfillObserver(expectation(description: "The item has no formula")) { (formula: String?) in
            guard let formula = formula else { return false }
            return formula == ""
        }
        
        viewModel.formula
            .bindTo(formulaObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testFormula() {
        // SCENARIO:
        // (1) Check the formula of the item.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let formulaObserver = FulfillObserver(expectation(description: "The formula of item becomes 10+20")) { (formula: String?) in
            guard let formula = formula else { return false }
            return formula == "10+20"
        }
        
        viewModel.formula
            .bindTo(formulaObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testVisible() {
        // SCENARIO:
        // (1) Check the visibility of the item.

        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let visibleObserver = FulfillObserver(expectation(description: "The item is visible")) { (visible: Bool) in
            return visible
        }
        
        viewModel.visible
            .bindTo(visibleObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testHidden() {
        // SCENARIO:
        // (1) Check the visibility of the item.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let visibleObserver = FulfillObserver(expectation(description: "The item is not visible")) { (visible: Bool) in
            return !visible
        }
        
        viewModel.visible
            .bindTo(visibleObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testFormat0() {
        // SCENARIO:
        // (1) Check the format of the item.

        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let formatObserver = FulfillObserver(expectation(description: "The format is 3桁区切り,2桁")) { (format: String?) in
            guard let format = format else { return false }
            return format == ResourceUtils.getString(R.String.thousandSeparatorOn) + ", " + ResourceUtils.getString(format: R.String.fractionDigitsFormat, 2)
        }
        
        viewModel.format
            .bindTo(formatObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }

    func testFormat1() {
        // SCENARIO:
        // (1) Check the format of the item.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let formatObserver = FulfillObserver(expectation(description: "The format is 自動")) { (format: String?) in
            guard let format = format else { return false }
            return format == ResourceUtils.getString(R.String.fractionDigitsAuto)
        }
        
        viewModel.format
            .bindTo(formatObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testSelectName() {
        // SCENARIO:
        // (1) User selects the name.
        // (2) It transit to the scene whose view model is IItemNameViewModel.

        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemNameViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            return transitionMessage.viewModel is IItemNameViewModel
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User selects the name.
        viewModel.onSelectName.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testSelectType() {
        // SCENARIO:
        // (1) User selects the type.
        // (2) It transit to the scene whose view model is IItemTypeViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemTypeViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            return transitionMessage.viewModel is IItemTypeViewModel
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User selects the type.
        viewModel.onSelectType.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testSelectFormula() {
        // SCENARIO:
        // (1) User selects the formula.
        // (2) It transit to the scene whose view model is IFormulaViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IFormulaViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            return transitionMessage.viewModel is IFormulaViewModel
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User selects the formula.
        viewModel.onSelectFormula.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }

    func testChangeVisible() {
        // SCENARIO:
        // (1) User changes the visibility.
        // (2) The item store is notified.

        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let exp = expectation(description: "Visibility changed to false")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        sheetItemStore0.updateVisibleHandler = { (visible) in
            // (2) The item store is notified.
            if (!visible) {
                exp.fulfill()
            }
        }
        
        // (1) User changes the visibility.
        viewModel.onChangeVisible.onNext(false)

        waitForExpectations(timeout: 3.0)
    }
    
    func testSelectFormat() {
        // SCENARIO:
        // (1) User selects the format.
        // (2) It transit to the scene whose view model is IItemFormatViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_one")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemFormatViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            return transitionMessage.viewModel is IItemFormatViewModel
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User selects the format.
        viewModel.onSelectFormat.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnSelectName() {
        // SCENARIO:
        // (1) User taps "Name"
        // (2) It transit to the scene whose view model is IItemNameViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemNameViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockItemNameViewModel else { return false }
            return viewModel.id == "sheet_item_zero"
        }

        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User taps "Name"
        viewModel.onSelectName.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnSelectType() {
        // SCENARIO:
        // (1) User taps "Type"
        // (2) It transit to the scene whose view model is IItemTypeViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemTypeViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockItemTypeViewModel else { return false }
            return viewModel.id == "sheet_item_zero"
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User taps "Type"
        viewModel.onSelectType.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }

    func testOnSelectFormula() {
        // SCENARIO:
        // (1) User taps "Formula"
        // (2) It transit to the scene whose view model is IFormulaViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IFormulaViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockFormulaViewModel else { return false }
            return viewModel.id == "sheet_item_zero"
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User taps "Formula"
        viewModel.onSelectFormula.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }

    func testOnChangeVisible() {
        // SCENARIO:
        // (1) User changes "Visible"
        // (2) The visibility is changed by SheetItemStore
        // (3) It is refrected to UI

        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")

        let expectUpdateVisible = expectation(description: "OnUpdateVisible is fired")
        let sheetItemStore0 = mockLocator.resolveSheetItemStore(id: "sheet_item_zero") as! MockSheetItemStore
        sheetItemStore0.updateVisibleHandler = { visible in
            // (2) The visibility is changed by SheetItemStore
            if (!visible) {
                expectUpdateVisible.fulfill()
            }
            if let sheetItem = sheetItemStore0.item {
                sheetItem.visible = visible
                sheetItemStore0.update(item: sheetItem)
            }
        }

        let onChangeVisibleObserver = FulfillObserver(expectation(description: "Update of visibility")) { (visible: Bool) in
            // (3) It is refrected to UI
            return !visible
        }
        
        viewModel.visible
            .bindTo(onChangeVisibleObserver)
            .disposed(by: disposeBag)
        
        // (1) User changes "Visible"
        viewModel.onChangeVisible.onNext(false)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnSelectFormat() {
        // SCENARIO:
        // (1) User taps "Format"
        // (2) It transit to the scene whose view model is IItemFormatViewModel.
        
        let viewModel = ItemViewModel(locator: mockLocator, id: "sheet_item_zero")
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (2) It transit to the scene whose view model is IItemFormatViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockItemFormatViewModel else { return false }
            return viewModel.id == "sheet_item_zero"
        }
        
        viewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (1) User taps "Format"
        viewModel.onSelectFormat.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
}
