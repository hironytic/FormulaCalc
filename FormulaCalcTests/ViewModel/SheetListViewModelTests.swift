//
// SheetListViewModelTests.swift
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

class SheetListViewModelTests: XCTestCase {
    class MockListStore: ISheetListStore {
        let update: Observable<SheetListStoreUpdate>
        let onCreateNewSheet: AnyObserver<String>
        let onDeleteSheet: AnyObserver<String>
        
        var _sheetList: [Sheet]
        var _newIDCount = 0
        var _update: Variable<SheetListStoreUpdate>
        var _onCreateNewSheet = ActionObserver<String>()
        var _onDeleteSheet = ActionObserver<String>()
        
        init() {
            let sheet0 = Sheet()
            sheet0.id = "zero"
            sheet0.name = "Sheet 0"
            let sheet1 = Sheet()
            sheet1.id = "one"
            sheet1.name = "Sheet 1"
            
            _sheetList = [sheet0, sheet1]
            _update = Variable(SheetListStoreUpdate(sheetList: AnyRandomAccessCollection(_sheetList),
                                                    deletions: [],
                                                    insertions: [0, 1],
                                                    modifications: []))

            update = _update.asObservable()
            onCreateNewSheet = _onCreateNewSheet.asObserver()
            onDeleteSheet = _onDeleteSheet.asObserver()
            
            _onCreateNewSheet.handler = { [weak self] name in self?.handleCreateNewSheet(name: name) }
            _onDeleteSheet.handler = { [weak self] id in self?.handleDeleteSheet(id: id) }
        }
        
        func handleCreateNewSheet(name: String) {
            let newSheet = Sheet()
            _newIDCount += 1
            newSheet.id = "new_sheet_\(_newIDCount)"
            newSheet.name = name
            
            _sheetList.append(newSheet)
            _update.value = SheetListStoreUpdate(sheetList: AnyRandomAccessCollection(_sheetList),
                                                 deletions: [],
                                                 insertions: [_sheetList.count - 1],
                                                 modifications: [])
        }
        
        func handleDeleteSheet(id: String) {
            if let index = _sheetList.index(where: { $0.id == id }) {
                _sheetList.remove(at: index)
                _update.value = SheetListStoreUpdate(sheetList: AnyRandomAccessCollection(_sheetList),
                                                     deletions: [index],
                                                     insertions: [],
                                                     modifications: [])
            }
        }
    }
    
    class MockSheetViewModel: ISheetViewModel {
        let id: String
        let title = Observable<String?>.never()
        let itemList = Observable<[ISheetElementViewModel]>.never()
        var message = Observable<Message>.never()
        let onTapDesignButton = ActionObserver<Void>().asObserver()
        
        init(id: String) {
            self.id = id
        }
    }
    
    class MockLocator: SheetListViewModel.Locator {
        func resolveSheetListStore() -> ISheetListStore {
            return MockListStore()
        }
        
        func resolveSheetViewModel(id: String) -> ISheetViewModel {
            return MockSheetViewModel(id: id)
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

    func testSheetList() {
        // SCENARIO:
        // (1) A list of the sheets is shown and it contains two sheets.
        // (2) The name of the first sheet is "Sheet 0".

        let sheetListViewModel = SheetListViewModel(locator: MockLocator())
        
        let sheetListObserver = FulfillObserver(expectation(description: "The sheet list contains two items.")) { (elementViewModels: [ISheetListElementViewModel]) in
            // (1) A list of the sheets is shown and it contains two sheets.
            guard elementViewModels.count == 2 else { return false }

            let elementViewModel0 = elementViewModels[0]
            guard elementViewModel0.id == "zero" else { return false }

            let sheetTitleObserver = FulfillObserver(self.expectation(description: "Title of the sheet becomes 'Sheet 0'.")) { (title: String?) in
                // (2) The name of the first sheet is "Sheet 0".
                guard let title = title else { return false }
                return title == "Sheet 0"
            }
            
            elementViewModel0.title
                .bindTo(sheetTitleObserver)
                .disposed(by: self.disposeBag)
            return true
        }
        
        sheetListViewModel.sheetList
            .bindTo(sheetListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnNew() {
        // SCENARIO:
        // (1) New sheet button is tapped.
        // (2) It asks user to input a name of new sheet.
        // (3) User inputs "New Name".
        // (4) New sheet is created with that name.
        
        let sheetListViewModel = SheetListViewModel(locator: MockLocator())

        sheetListViewModel.message
            .subscribe(onNext: { message in
                switch message {
                case let transitionMessage as TransitionMessage:
                    guard let inputViewModel = transitionMessage.viewModel as? IInputOneTextViewModel else { break }
                    
                    // (2) It asks user to input a name of new sheet.
                    // (3) User inputs "New Name".
                    inputViewModel.onDone.onNext("New Name")
                    inputViewModel.onDone.onCompleted()
                    inputViewModel.onCancel.onCompleted()
                    
                default:
                    break
                }
            }).disposed(by: disposeBag)
        
        var sheetListDisposeBag: DisposeBag!
        let expectNewSheet = expectation(description: "The new sheet name is 'New Name'")
        sheetListViewModel.sheetList
            .subscribe(onNext: { elementViewModels in
                sheetListDisposeBag = DisposeBag()
                for elementViewModel in elementViewModels {
                    elementViewModel.title
                        .subscribe(onNext: { title in
                            if let title = title {
                                if title == "New Name" {
                                    // (4) New sheet is created with that name.
                                    expectNewSheet.fulfill()
                                }
                            }
                        })
                        .disposed(by: sheetListDisposeBag)
                }
            }, onDisposed: {
                sheetListDisposeBag = nil
            })
            .disposed(by: disposeBag)
        
        // (1) New sheet button is tapped.
        sheetListViewModel.onNew.onNext(())
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testOnDelete() {
        // SCENARIO:
        // (1) The list contains two sheets.
        // (2) User deletes the first sheet.
        // (3) The sheet is deleted and removed from the list.
        
        let sheetListViewModel = SheetListViewModel(locator: MockLocator())
        
        var sheetToBeRemoved: ISheetListElementViewModel?
        
        let sheetListObserver = FulfillObserver(expectation(description: "The sheet list contains two items.")) { (elementViewModels: [ISheetListElementViewModel]) in
            // (1) The list contains two sheets.
            guard elementViewModels.count == 2 else { return false }
            
            let elementViewModel0 = elementViewModels[0]
            guard elementViewModel0.id == "zero" else { return false }
            sheetToBeRemoved = elementViewModel0
            
            return true
        }
        
        sheetListViewModel.sheetList
            .bindTo(sheetListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
        
        sheetListObserver.reset(expectation(description: "The sheet doesn't contains Sheet 0")) { (elementViewModels: [ISheetListElementViewModel]) in
            // (3) The sheet is deleted and removed from the list.
            guard elementViewModels.count == 1 else { return false }
            let elementViewModel0 = elementViewModels[0]
            sheetToBeRemoved = elementViewModel0
            guard elementViewModel0.id != "zero" else { return false }
            
            return true
        }
        
        // (2) User deletes the first sheet.
        guard let toBeRemoved = sheetToBeRemoved else { XCTFail(); return }
        sheetListViewModel.onDelete.onNext(toBeRemoved)

        waitForExpectations(timeout: 3.0)
    }
    
    func testOnSelect() {
        // SCENARIO:
        // (1) The list contains two sheets.
        // (2) User selects the first sheet.
        // (3) It transit to the scene whose view model is ISheetViewModel.
        
        let sheetListViewModel = SheetListViewModel(locator: MockLocator())

        var sheetToBeSelected: ISheetListElementViewModel?
        
        let sheetListObserver = FulfillObserver(expectation(description: "The sheet list contains two items.")) { (elementViewModels: [ISheetListElementViewModel]) in
            // (1) The list contains two sheets.
            guard elementViewModels.count == 2 else { return false }
            
            let elementViewModel0 = elementViewModels[0]
            guard elementViewModel0.id == "zero" else { return false }
            sheetToBeSelected = elementViewModel0

            return true
        }
        
        sheetListViewModel.sheetList
            .bindTo(sheetListObserver)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
        
        let messageObserver = FulfillObserver(expectation(description: "Scene transition")) { (message: Message) in
            // (3) It transit to the scene whose view model is ISheetViewModel.
            guard let transitionMessage = message as? TransitionMessage else { return false }
            guard let viewModel = transitionMessage.viewModel as? MockSheetViewModel else { return false }
            return viewModel.id == "zero"
        }
        
        sheetListViewModel.message
            .bindTo(messageObserver)
            .disposed(by: disposeBag)
        
        // (2) User selects the first sheet.
        guard let toBeSelected = sheetToBeSelected else { XCTFail(); return }
        sheetListViewModel.onSelect.onNext(toBeSelected)
        
        waitForExpectations(timeout: 3.0)
    }
}
