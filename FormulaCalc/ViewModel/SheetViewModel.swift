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
}

public protocol ISheetViewModelFactory {
    func newSheetViewModel(context: IContext, id: String) -> ISheetViewModel
}

extension DefaultContext: ISheetViewModelFactory {
    public func newSheetViewModel(context: IContext, id: String) -> ISheetViewModel {
        return SheetViewModel(context: context, id: id)
    }
}

public protocol ISheetViewModelContext: IContext, ISheetStoreFactory {
}

extension DefaultContext: ISheetViewModelContext {
}

public class SheetElementViewModel: ViewModel, ISheetElementViewModel {
    public let id: String
    public let name: Observable<String?>
    public let value: Observable<String?>

    public let onTapValue: AnyObserver<Void>
    
    public init(context: IContext, id: String, editingItemId: Observable<String?>, onChangeEditingItemId: AnyObserver<String?>) {
        self.id = id
        name = Observable.just("項目名")
        value = Observable.just("12345.6")
        
        onTapValue = onChangeEditingItemId
            .mapObserver { _ in
                return id
            }
        
        super.init(context: context)
    }
}

public class SheetViewModel: ViewModel, ISheetViewModel {
    public let title: Observable<String?>
    public let itemList: Observable<[ISheetElementViewModel]>
    
    private var _context: ISheetViewModelContext { get { return context as! ISheetViewModelContext } }
    private let _sheetStore: ISheetStore
    private let _editingItemIdSubject = BehaviorSubject<String?>(value: nil)
    
    public init(context: IContext, id: String) {
        let context = context as! ISheetViewModelContext
        
        _sheetStore = context.newSheetStore(context: context, id: id)

        title = _sheetStore.update
            .map { sheet in
                return sheet?.name ?? ""
            }
        
        let editingItemId = _editingItemIdSubject.asObservable()
        let onChangeEditingItemId: AnyObserver<String?> = _editingItemIdSubject.asObserver()
        itemList = _sheetStore.update
            .map { sheet in
                guard let sheet = sheet else { return [] }
                return sheet.items.map { item in
                    return SheetElementViewModel(context: context,
                                                 id: item.id,
                                                 editingItemId: editingItemId,
                                                 onChangeEditingItemId: onChangeEditingItemId)
                }
            }
        
        super.init(context: context)
    }
}
