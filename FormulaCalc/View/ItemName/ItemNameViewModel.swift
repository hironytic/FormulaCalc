//
// ItemNameViewModel.swift
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

public protocol IItemNameViewModel: IViewModel {
    var name: Observable<String?> { get }
    
    var onNameChanged: AnyObserver<String?> { get }
    var onNameEditingDidEnd: AnyObserver<Void> { get }
}

public protocol IItemNameViewModelLocator {
    func resolveItemNameViewModel(id: String) -> IItemNameViewModel
}
extension DefaultLocator: IItemNameViewModelLocator {
    public func resolveItemNameViewModel(id: String) -> IItemNameViewModel {
        return ItemNameViewModel(locator: self, id: id)
    }
}

public class ItemNameViewModel: IItemNameViewModel {
    public typealias Locator = ISheetItemStoreLocator
    
    public let name: Observable<String?>
    public let onNameChanged: AnyObserver<String?>
    public let onNameEditingDidEnd: AnyObserver<Void>
    
    private let _onNameChanged = ActionObserver<String?>()
    private let _onNameEditingDidEnd = ActionObserver<Void>()
    
    private let _locator: Locator
    private let _id: String
    private let _sheetItemStore: ISheetItemStore
    private let _disposeBag = DisposeBag()
    private let _name = Variable<String?>("")

    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)

        _sheetItemStore.update
            .distinctUntilChanged({ $0?.name }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.name ?? ""
            }
            .bind(to: _name)
            .disposed(by: _disposeBag)
        
        name = _name
            .asDriver()
            .asObservable()

        onNameChanged = _onNameChanged.asObserver()
        onNameEditingDidEnd = _onNameEditingDidEnd.asObserver()

        _onNameChanged.handler = { [weak self] (name: String?) in self?.handleOnNameChanged(name) }
        _onNameEditingDidEnd.handler = { [weak self] in self?.handleOnNameEditingDidEnd() }
    }
    
    private func handleOnNameChanged(_ name: String?) {
        _name.value = name
    }
    
    private func handleOnNameEditingDidEnd() {
        _sheetItemStore.onUpdateName.onNext(_name.value ?? "")
    }
}
