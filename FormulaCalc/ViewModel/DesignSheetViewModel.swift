//
// DesignSheetViewModel.swift
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

public protocol IDesignSheetElementViewModel: IViewModel {
    var id: String { get }
    var name: Observable<String?> { get }
    var type: Observable<String?> { get }
    var invisibleMarkHidden: Observable<Bool> { get }
}

public protocol IDesignSheetViewModel: IViewModel {
    var title: Observable<String?> { get }
    var itemList: Observable<[IDesignSheetElementViewModel]> { get }
    var message: Observable<Message> { get }
    
    var onNewItem: AnyObserver<Void> { get }
    var onSelectItem: AnyObserver<IDesignSheetElementViewModel> { get }
    var onDeleteItem: AnyObserver<IDesignSheetElementViewModel> { get }
    var onDone: AnyObserver<Void> { get }
}

public protocol IDesignSheetViewModelLocator {
    func resolveDesignSheetViewModel(id: String) -> IDesignSheetViewModel
}
extension DefaultLocator: IDesignSheetViewModelLocator {
    public func resolveDesignSheetViewModel(id: String) -> IDesignSheetViewModel {
        return DesignSheetViewModel(locator: self, id: id)
    }
}

class DesignSheetElementViewModel: IDesignSheetElementViewModel {
    public typealias Locator = ISheetItemStoreLocator

    public let id: String
    public let name: Observable<String?>
    public let type: Observable<String?>
    public let invisibleMarkHidden: Observable<Bool>
    
    private let _locator: Locator
    private let _sheetItemStore: ISheetItemStore
    
    public init(locator: Locator, id: String) {
        _locator = locator
        self.id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)

        name = _sheetItemStore.update
            .distinctUntilChanged({ $0?.name }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.name ?? ""
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()

        type = _sheetItemStore.update
            .distinctUntilChanged({ $0?.type }, comparer: { $0 == $1 })
            .map { sheetItem in
                guard let sheetItem = sheetItem else { return "" }
                
                switch sheetItem.type {
                case .numeric:
                    return ResourceUtils.getString(R.String.sheetItemTypeNumeric)
                case .string:
                    return ResourceUtils.getString(R.String.sheetItemTypeString)
                case .formula:
                    return ResourceUtils.getString(R.String.sheetItemTypeFormula)
                    
                }
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        invisibleMarkHidden = _sheetItemStore.update
            .distinctUntilChanged({ $0?.visible }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.visible ?? true
            }
            .asDriver(onErrorJustReturn: true)
            .asObservable()
    }
}

public class DesignSheetViewModel: IDesignSheetViewModel {
    public typealias Locator = ISheetStoreLocator & ISheetItemStoreLocator & IItemViewModelLocator
    
    public let message: Observable<Message>
    public let title: Observable<String?>
    public let itemList: Observable<[IDesignSheetElementViewModel]>
    
    public let onNewItem: AnyObserver<Void>
    public let onSelectItem: AnyObserver<IDesignSheetElementViewModel>
    public let onDeleteItem: AnyObserver<IDesignSheetElementViewModel>
    public let onDone: AnyObserver<Void>

    private let _locator: Locator
    private let _id: String
    private let _sheetStore: ISheetStore
    private let _messageSlot = MessageSlot()
    private let _onSelectItem = ActionObserver<IDesignSheetElementViewModel>()
    private let _onDone = ActionObserver<Void>()
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetStore = _locator.resolveSheetStore(id: id)
        
        title = _sheetStore.update
            .distinctUntilChanged({ $0?.name }, comparer: { $0 == $1 })
            .map { sheet in
                return sheet?.name ?? ""
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        itemList = _sheetStore.itemListUpdate
            .map { update in
                return update.itemList.map { item in
                    return DesignSheetElementViewModel(locator: locator, id: item.id)
                }
            }
            .asDriver(onErrorJustReturn: [])
            .asObservable()

        onNewItem = _sheetStore.onNewItem
        onDeleteItem = _sheetStore.onDeleteItem
            .mapObserver { sheetElementViewModel in
                return sheetElementViewModel.id
            }
        onSelectItem = _onSelectItem.asObserver()
        onDone = _onDone.asObserver()

        message = _messageSlot.message
        
        _onDone.handler = { [weak self] in self?.handleOnDone() }
        _onSelectItem.handler = { [weak self] in self?.handleOnSelect($0) }
    }
    
    private func handleOnDone() {
        _messageSlot.send(DismissingMessage(type: .dismiss, animated: true))
    }
    
    private func handleOnSelect(_ sheetElementViewModel: IDesignSheetElementViewModel) {
        let itemViewModel = _locator.resolveItemViewModel(id: sheetElementViewModel.id)
        _messageSlot.send(TransitionMessage(viewModel: itemViewModel, type: .push, animated: true))
    }
}
