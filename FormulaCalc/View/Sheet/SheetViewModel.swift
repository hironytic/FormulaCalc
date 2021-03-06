//
// SheetViewModel.swift
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

public protocol ISheetElementViewModel: IViewModel {
    var id: String { get }
    var name: Observable<String?> { get }
    var value: Observable<String?> { get }
    var editingValue: Observable<String?> { get }
    var valueLabelHidden: Observable<Bool> { get }
    var valueEditHidden: Observable<Bool> { get }
    
    var onTapValue: AnyObserver<Void> { get }
    var onValueChanged: AnyObserver<String?> { get }
    var onValueEditingDidEnd: AnyObserver<Void> { get }
}

public protocol ISheetViewModel: IViewModel {
    var title: Observable<String?> { get }
    var itemList: Observable<[ISheetElementViewModel]> { get }
    var message: Observable<Message> { get }
    
    var onTapDesignButton: AnyObserver<Void> { get }
}

public protocol ISheetViewModelLocator {
    func resolveSheetViewModel(id: String) -> ISheetViewModel
}
extension DefaultLocator: ISheetViewModelLocator {
    public func resolveSheetViewModel(id: String) -> ISheetViewModel {
        return SheetViewModel(locator: self, id: id)
    }
}

class SheetElementViewModel: ISheetElementViewModel {
    public typealias Locator = ISheetItemStoreLocator
    
    public let id: String
    public let name: Observable<String?>
    public let value: Observable<String?>
    public let editingValue: Observable<String?>
    public let valueLabelHidden: Observable<Bool>
    public let valueEditHidden: Observable<Bool>

    private let _locator: Locator
    private let _sheetItemStore: ISheetItemStore
    
    public let onTapValue: AnyObserver<Void>
    public let onValueChanged: AnyObserver<String?>
    public let onValueEditingDidEnd: AnyObserver<Void>

    private let _onValueChanged = ActionObserver<String?>()
    private let _onValueEditingDidEnd = ActionObserver<Void>()
    private let _disposeBag = DisposeBag()
    private let _editingValue = Variable<String?>("")
    
    public init(locator: Locator, id: String, editingItemId: Observable<String?>, onChangeEditingItemId: AnyObserver<String?>) {
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
        
        value = _sheetItemStore.update
            .distinctUntilChanged({ $0?.type }, comparer: { $0 == $1 })
            .map { sheetItem in
                guard let sheetItem = sheetItem else { return "" }
                
                switch sheetItem.type {
                case .numeric:
                    return "\(sheetItem.numberValue)"   // FIXME: format
                case .string:
                    return sheetItem.stringValue
                case .formula:
                    return "数式の結果"  // FIXME: calculate
                }
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()

        _sheetItemStore.update
            .distinctUntilChanged({ $0?.type }, comparer: { $0 == $1 })
            .map { sheetItem in
                guard let sheetItem = sheetItem else { return "" }
                
                switch sheetItem.type {
                case .numeric:
                    return "\(sheetItem.numberValue)"
                case .string:
                    return sheetItem.stringValue
                default:
                    return ""
                }
            }
            .bind(to: _editingValue)
            .disposed(by: _disposeBag)

        editingValue = _editingValue
            .asDriver()
            .asObservable()
        
        valueLabelHidden = editingItemId
            .map { editingId in
                if let  editingId = editingId {
                    return editingId == id
                } else {
                    return false
                }
            }
            .asDriver(onErrorJustReturn: false)
            .asObservable()
        
        valueEditHidden = valueLabelHidden
            .map { !$0 }
        
        onTapValue = onChangeEditingItemId
            .mapObserver { _ in
                return id
            }
        
        onValueChanged = _onValueChanged.asObserver()
        onValueEditingDidEnd = _onValueEditingDidEnd.asObserver()
        
        _onValueChanged.handler = { [weak self] (name: String?) in self?.handleOnValueChanged(name) }
        _onValueEditingDidEnd.handler = { [weak self] in self?.handleOnValueEditingDidEnd() }
    }
    
    private func handleOnValueChanged(_ value: String?) {
        _editingValue.value = value
    }
    
    private func handleOnValueEditingDidEnd() {
        // TODO:
//        _sheetItemStore.onUpdateName.onNext(_name.value ?? "")
    }
    
}

public class SheetViewModel: ISheetViewModel {
    public typealias Locator =  ISheetStoreLocator & ISheetItemStoreLocator & IDesignSheetViewModelLocator
    
    public let title: Observable<String?>
    public let itemList: Observable<[ISheetElementViewModel]>
    public let onTapDesignButton: AnyObserver<Void>
    public let message: Observable<Message>
    
    private let _locator: Locator
    private let _id: String
    private let _sheetStore: ISheetStore
    private let _editingItemIdSubject = BehaviorSubject<String?>(value: nil)
    private let _onTapDesignButton = ActionObserver<Void>()
    private let _messageSlot = MessageSlot()
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetStore = locator.resolveSheetStore(id: id)

        title = _sheetStore.update
            .distinctUntilChanged({ $0?.name }, comparer: { $0 == $1 })
            .map { sheet in
                return sheet?.name ?? ""
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        let editingItemId = _editingItemIdSubject.asObservable()
        let onChangeEditingItemId: AnyObserver<String?> = _editingItemIdSubject.asObserver()
        itemList = _sheetStore.itemListUpdate
            .map { update in
                return update.itemList
                    .filter { $0.visible }
                    .map { item in
                        SheetElementViewModel(locator: locator,
                                              id: item.id,
                                              editingItemId: editingItemId,
                                              onChangeEditingItemId: onChangeEditingItemId)
                    }
            }
            .asDriver(onErrorJustReturn: [])
            .asObservable()

        onTapDesignButton = _onTapDesignButton.asObserver()

        message = _messageSlot.message
        
        _onTapDesignButton.handler = { [weak self] in self?.handleOnTapDesignButton() }
    }
    
    private func handleOnTapDesignButton() {
        let designSheetViewModel = _locator.resolveDesignSheetViewModel(id: _id)
        _messageSlot.send(TransitionMessage(viewModel: designSheetViewModel, type: .present, animated: true, modalTransitionStyle: .flipHorizontal))
    }
}
