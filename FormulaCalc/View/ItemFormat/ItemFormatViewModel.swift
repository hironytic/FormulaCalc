//
// ItemFormatViewModel.swift
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

public protocol IThousandSeparatorElementViewModel: IViewModel {
    var thousandSeparator: Observable<Bool> { get }
    
    var onChangeThousandSeparator: AnyObserver<Bool> { get }
}

public protocol IFractionsDigitsElementViewModel: IViewModel {
    var name: Observable<String?> { get }
    var accessoryType: Observable<UITableViewCellAccessoryType> { get }
}

public struct ItemFormatElementViewModels {
    let thousandSeparator: [IThousandSeparatorElementViewModel]
    let fractionDigits: [IFractionsDigitsElementViewModel]
}

public protocol IItemFormatViewModel: IViewModel {
    var items: Observable<ItemFormatElementViewModels> { get }
    
    var onSelectFractionDigits: AnyObserver<IFractionsDigitsElementViewModel> { get }
}

public protocol IItemFormatViewModelLocator {
    func resolveItemFormatViewModel(id: String) -> IItemFormatViewModel
}
extension DefaultLocator: IItemFormatViewModelLocator {
    public func resolveItemFormatViewModel(id: String) -> IItemFormatViewModel {
        return ItemFormatViewModel(locator: self, id: id)
    }
}

class ThousandSeparatorElementViewModel: IThousandSeparatorElementViewModel {
    let thousandSeparator: Observable<Bool>
    let onChangeThousandSeparator: AnyObserver<Bool>
    
    init(thousandSeparator: Observable<Bool>, onChangeThousandSeparator: AnyObserver<Bool>) {
        self.thousandSeparator = thousandSeparator
        self.onChangeThousandSeparator = onChangeThousandSeparator
    }
}

class FractionDigitsElementViewModel: IFractionsDigitsElementViewModel {
    public let name: Observable<String?>
    public let accessoryType: Observable<UITableViewCellAccessoryType>

    public let value: Int
    
    init(value: Int, name: String, fractionDigits: Observable<Int?>) {
        self.value = value
        self.name = Observable.just(name)
        accessoryType = fractionDigits
            .map { fdOrNil in
                guard let fd = fdOrNil else { return .none }
                return (fd == value) ? .checkmark : .none
            }
    }
}

public class ItemFormatViewModel: IItemFormatViewModel {
    public typealias Locator = ISheetItemStoreLocator

    public let items: Observable<ItemFormatElementViewModels>

    public let onSelectFractionDigits: AnyObserver<IFractionsDigitsElementViewModel>
    
    private let _locator: Locator
    private let _id: String
    private let _sheetItemStore: ISheetItemStore
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)

        let thousandSeparator = _sheetItemStore.update
            .distinctUntilChanged({ $0?.thousandSeparator }, comparer: { $0 == $1 })
            .map { $0?.thousandSeparator ?? false }
            .asDriver(onErrorJustReturn: false)
            .asObservable()

        let onChangeThousandSeparator = _sheetItemStore.onUpdateThousandSeparator
        
        let fractionDigits = _sheetItemStore.update
            .distinctUntilChanged({ $0?.fractionDigits }, comparer: { $0 == $1 })
            .map { $0?.fractionDigits }
        
        let fractionDigitsList = [
            FractionDigitsElementViewModel(value: -1, name: ResourceUtils.getString(R.String.fractionDigitsAuto), fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 0, name: "0", fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 1, name: "1", fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 2, name: "2", fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 3, name: "3", fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 4, name: "4", fractionDigits: fractionDigits),
            FractionDigitsElementViewModel(value: 5, name: "5", fractionDigits: fractionDigits),
        ]
        
        onSelectFractionDigits = _sheetItemStore.onUpdateFractionDigits
            .mapObserver { ($0 as! FractionDigitsElementViewModel).value }

        let thousandSeparatorElementViewModel = ThousandSeparatorElementViewModel(thousandSeparator: thousandSeparator, onChangeThousandSeparator: onChangeThousandSeparator)
        
        items = Observable.just(ItemFormatElementViewModels(thousandSeparator: [thousandSeparatorElementViewModel], fractionDigits: fractionDigitsList))
    }
}
