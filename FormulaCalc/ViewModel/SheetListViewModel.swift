//
// SheetListViewModel.swift
// FormulaCalc
//
// Copyright (c) 2016, 2017 Hironori Ichimiya <hiron@hironytic.com>
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

import Foundation
import RxSwift

private typealias R = Resource

public protocol ISheetListElementViewModel: IViewModel {
    var id: String { get }
    var title: Observable<String?> { get }
}

public protocol ISheetListViewModel: IViewModel {
    var sheetList: Observable<[ISheetListElementViewModel]> { get }
    
    var onNew: AnyObserver<Void> { get }
    var onDelete: AnyObserver<ISheetListElementViewModel> { get }
    var onSelect: AnyObserver<ISheetListElementViewModel> { get }
}

public protocol ISheetListViewModelLocator {
    func resolveSheetListViewModel() -> ISheetListViewModel
}
extension DefaultLocator: ISheetListViewModelLocator {
    public func resolveSheetListViewModel() -> ISheetListViewModel {
        return SheetListViewModel(locator: self)
    }
}

class SheetListElementViewModel: ViewModel, ISheetListElementViewModel {
    public let id: String
    public let title: Observable<String?>
    
    public init(id: String, title: String) {
        self.id = id
        self.title = Observable.just(title)
        
        super.init()
    }
}

public class SheetListViewModel: ViewModel, ISheetListViewModel {
    public typealias Locator = ISheetListStoreLocator & ISheetViewModelLocator
    
    public let sheetList: Observable<[ISheetListElementViewModel]>
    public private(set) var onNew: AnyObserver<Void>
    public private(set) var onDelete: AnyObserver<ISheetListElementViewModel>
    public private(set) var onSelect: AnyObserver<ISheetListElementViewModel>
    
    private let _locator: Locator
    private let _sheetListStore: ISheetListStore
    private let _onNew = ActionObserver<Void>()
    private let _onDelete = ActionObserver<ISheetListElementViewModel>()
    private let _onSelect = ActionObserver<ISheetListElementViewModel>()
    
    public init(locator: Locator) {
        _locator = locator

        _sheetListStore = _locator.resolveSheetListStore()
        sheetList = _sheetListStore.update
            .map { update in
                return update.sheetList
                    .map { sheet in
                        return SheetListElementViewModel(id: sheet.id, title: sheet.name)
                    }
            }
            .asDriver(onErrorJustReturn: [])
            .asObservable()
        
        onNew = _onNew.asObserver()
        onDelete = _onDelete.asObserver()
        onSelect = _onSelect.asObserver()
        
        super.init()
        
        _onNew.handler = { [weak self] in self?.handleOnNew() }
        _onSelect.handler = { [weak self] item in self?.handleOnSelect(item) }
        _onDelete.handler = { [weak self] item in self?.handleOnDelete(item) }
    }
    
    private func handleOnNew() {
        class InputNameViewModel: ViewModel, IInputOneTextViewModel {
            let title: String? = ResourceUtils.getString(R.String.newSheetTitle)
            let detailMessage: String? = nil
            let placeholder: String? = ResourceUtils.getString(R.String.newSheetPlaceholder)
            let initialText = ""
            let cancelButtonTitle = ResourceUtils.getString(R.String.cancel)
            let doneButtonTitle = ResourceUtils.getString(R.String.newSheetDone)
            
            let onDone: AnyObserver<String>
            let onCancel = ActionObserver<Void>().asObserver()

            init(onDone: @escaping (String) -> Void) {
                self.onDone = ActionObserver(handler: onDone).asObserver()
                super.init()
            }
        }
        
        let viewModel = InputNameViewModel() { [weak self] name in
            self?._sheetListStore.onCreateNewSheet.onNext(name)
        }
        sendMessage(TransitionMessage(viewModel: viewModel, type: .present, animated: true))
    }
    
    private func handleOnSelect(_ item: ISheetListElementViewModel) {
        let id = item.id
        let sheetViewModel = _locator.resolveSheetViewModel(id: id)
        sendMessage(TransitionMessage(viewModel: sheetViewModel, type: .push, animated: true))
    }
    
    private func handleOnDelete(_ item: ISheetListElementViewModel) {
        _sheetListStore.onDeleteSheet.onNext(item.id)
    }
}
