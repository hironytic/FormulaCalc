//
// ItemTypeViewModel.swift
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

import UIKit
import RxSwift

fileprivate typealias R = Resource

public protocol IItemTypeElementViewModel: IViewModel {
    var name: Observable<String?> { get }
    var accessoryType: Observable<UITableViewCellAccessoryType> { get }
}

public protocol IItemTypeViewModel: IViewModel {
    var typeList: Observable<[IItemTypeElementViewModel]> { get }
    
    var onSelect: AnyObserver<IItemTypeElementViewModel> { get }
}

public protocol IItemTypeViewModelLocator {
    func resolveItemTypeViewModel(id: String) -> IItemTypeViewModel
}
extension DefaultLocator: IItemTypeViewModelLocator {
    public func resolveItemTypeViewModel(id: String) -> IItemTypeViewModel {
        return ItemTypeViewModel(locator: self, id: id)
    }
}

class ItemTypeElementViewModel: ViewModel, IItemTypeElementViewModel {
    public let name: Observable<String?>
    public let accessoryType: Observable<UITableViewCellAccessoryType>
    
    public let sheetItemType: SheetItemType
    
    public init(sheetItemType: SheetItemType, currentItemType: Observable<SheetItemType?>) {
        self.sheetItemType = sheetItemType
        
        let nameKey: String
        switch sheetItemType {
        case .numeric:
            nameKey = R.String.sheetItemTypeNumeric
        case .string:
            nameKey = R.String.sheetItemTypeString
        case .formula:
            nameKey = R.String.sheetItemTypeFormula
        }
        
        name = Observable.just(ResourceUtils.getString(nameKey))
        accessoryType = currentItemType
            .map { type in
                if let type = type {
                    return (type == sheetItemType) ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
                } else {
                    return UITableViewCellAccessoryType.none
                }
            }
            .asDriver(onErrorJustReturn: UITableViewCellAccessoryType.none)
            .asObservable()
        
        super.init()
    }
}

public class ItemTypeViewModel: ViewModel, IItemTypeViewModel {
    public typealias Locator = ISheetItemStoreLocator
    
    public let typeList: Observable<[IItemTypeElementViewModel]>
    
    public let onSelect: AnyObserver<IItemTypeElementViewModel>
    
    private let _locator: Locator
    private let _id: String
    private let _sheetItemStore: ISheetItemStore
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)

        let currentItemType = _sheetItemStore.update
            .distinctUntilChanged({ $0?.type }, comparer: { $0 == $1 })
            .map { $0?.type }
        
        typeList = Observable.just([
            ItemTypeElementViewModel(sheetItemType: .numeric, currentItemType: currentItemType),
            ItemTypeElementViewModel(sheetItemType: .string, currentItemType: currentItemType),
            ItemTypeElementViewModel(sheetItemType: .formula, currentItemType: currentItemType)
        ])
        onSelect = _sheetItemStore.onUpdateType
            .mapObserver { (elementViewModel: IItemTypeElementViewModel) in
                return (elementViewModel as! ItemTypeElementViewModel).sheetItemType
            }
        
        super.init()
    }
}
