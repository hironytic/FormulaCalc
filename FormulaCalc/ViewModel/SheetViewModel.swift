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
    
    var onTapValue: AnyObserver<Void> { get }
}

public protocol ISheetViewModel: IViewModel {
    var title: Observable<String?> { get }
    var itemList: Observable<[ISheetElementViewModel]> { get }
    
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

class SheetElementViewModel: ViewModel, ISheetElementViewModel {
    public typealias Locator = ISheetItemStoreLocator
    
    public let id: String
    public let name: Observable<String?>
    public let value: Observable<String?>

    private let _locator: Locator
    private let _sheetItemStore: ISheetItemStore
    
    public let onTapValue: AnyObserver<Void>
    
    public init(locator: Locator, id: String, editingItemId: Observable<String?>, onChangeEditingItemId: AnyObserver<String?>) {
        _locator = locator
        self.id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)
        
        name = _sheetItemStore.update
            .map { sheetItem in
                return sheetItem?.name ?? ""
            }
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        value = _sheetItemStore.update
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
        
        onTapValue = onChangeEditingItemId
            .mapObserver { _ in
                return id
            }
        
        super.init()
    }
}

public class SheetViewModel: ViewModel, ISheetViewModel {
    public typealias Locator =  ISheetStoreLocator & ISheetItemStoreLocator & IDesignSheetViewModelLocator
    
    public let title: Observable<String?>
    public let itemList: Observable<[ISheetElementViewModel]>
    public let onTapDesignButton: AnyObserver<Void>
    
    private let _locator: Locator
    private let _id: String
    private let _sheetStore: ISheetStore
    private let _editingItemIdSubject = BehaviorSubject<String?>(value: nil)
    private let _onTapDesignButton = ActionObserver<Void>()
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetStore = locator.resolveSheetStore(id: id)

        title = _sheetStore.update
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
        
        super.init()
        
        _onTapDesignButton.handler = { [weak self] in self?.handleOnTapDesignButton() }
    }
    
    private func handleOnTapDesignButton() {
        let designSheetViewModel = _locator.resolveDesignSheetViewModel(id: _id)
        sendMessage(TransitionMessage(viewModel: designSheetViewModel, type: .present, animated: true, modalTransitionStyle: .flipHorizontal))
    }
}
