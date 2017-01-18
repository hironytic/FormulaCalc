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

public protocol ISheetViewModelFactory {
    func newSheetViewModel(context: IContext, id: String) -> ISheetViewModel
}
extension ISheetViewModelFactory {
    public func newSheetViewModel(context: IContext, id: String) -> ISheetViewModel {
        return SheetViewModel(context: context, id: id)
    }
}

public protocol ISheetElementViewModelContext: IContext, ISheetItemStoreFactory {}
extension DefaultContext: ISheetElementViewModelContext {}
public class SheetElementViewModel: ViewModel, ISheetElementViewModel {
    public let id: String
    public let name: Observable<String?>
    public let value: Observable<String?>

    private var _context: ISheetElementViewModelContext { get { return context as! ISheetElementViewModelContext } }
    private let _sheetItemStore: ISheetItemStore
    
    public let onTapValue: AnyObserver<Void>
    
    public init(context: IContext, id: String, editingItemId: Observable<String?>, onChangeEditingItemId: AnyObserver<String?>) {
        let context = context as! ISheetElementViewModelContext
        
        self.id = id
        _sheetItemStore = context.newSheetItemStore(context: context, id: id)
        
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
        
        super.init(context: context)
    }
}

public protocol ISheetViewModelContext: IContext, ISheetStoreFactory, IDesignSheetViewModelFactory {}
extension DefaultContext: ISheetViewModelContext {}
public class SheetViewModel: ViewModel, ISheetViewModel {
    public let title: Observable<String?>
    public let itemList: Observable<[ISheetElementViewModel]>
    public let onTapDesignButton: AnyObserver<Void>
    
    private var _context: ISheetViewModelContext { get { return context as! ISheetViewModelContext } }
    private let _id: String
    private let _sheetStore: ISheetStore
    private let _editingItemIdSubject = BehaviorSubject<String?>(value: nil)
    private let _onTapDesignButton = ActionObserver<Void>()
    
    public init(context: IContext, id: String) {
        let context = context as! ISheetViewModelContext
        
        _id = id
        _sheetStore = context.newSheetStore(context: context, id: id)

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
                return update.itemList.map { item in
                    return SheetElementViewModel(context: context,
                                                 id: item.id,
                                                 editingItemId: editingItemId,
                                                 onChangeEditingItemId: onChangeEditingItemId)
                }
            }
            .asDriver(onErrorJustReturn: [])
            .asObservable()

        onTapDesignButton = _onTapDesignButton.asObserver()
        
        super.init(context: context)
        
        _onTapDesignButton.handler = { [weak self] in self?.handleOnTapDesignButton() }
    }
    
    private func handleOnTapDesignButton() {
        let designSheetViewModel = _context.newDesignSheetViewModel(context: context, id: _id)
        sendMessage(TransitionMessage(viewModel: designSheetViewModel, type: .present, animated: true, modalTransitionStyle: .flipHorizontal))
    }
}
