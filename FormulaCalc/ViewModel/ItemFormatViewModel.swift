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
        return ItemFormatViewModel(id: id)
    }
}

class ThousandSeparatorElementViewModel: ViewModel, IThousandSeparatorElementViewModel {
    let thousandSeparator: Observable<Bool>
    let onChangeThousandSeparator: AnyObserver<Bool>
    
    init(thousandSeparator: Observable<Bool>, onChangeThousandSeparator: AnyObserver<Bool>) {
        self.thousandSeparator = thousandSeparator
        self.onChangeThousandSeparator = onChangeThousandSeparator
        super.init()
    }
}

class FractionDigitsElementViewModel: ViewModel, IFractionsDigitsElementViewModel {
    let name: Observable<String?>
    let accessoryType: Observable<UITableViewCellAccessoryType>
    
    override init() {
        name = Observable.just("自動")
        accessoryType = Observable.just(.checkmark)
        
        super.init()
    }
}

public class ItemFormatViewModel: ViewModel, IItemFormatViewModel {
    private let _thousandSeparator: Observable<Bool>
    private let _fractionDigits: [IFractionsDigitsElementViewModel]
    
    public let onSelectFractionDigits: AnyObserver<IFractionsDigitsElementViewModel>

    public let items: Observable<ItemFormatElementViewModels>
    
    private let _onChangeThousandSeparator = ActionObserver<Bool>()
    private let _onSelectFractionDigits = ActionObserver<IFractionsDigitsElementViewModel>()
    
    public init(id: String) {
        _thousandSeparator = Observable.just(true)
        _fractionDigits = [FractionDigitsElementViewModel(), FractionDigitsElementViewModel()]
        
        onSelectFractionDigits = _onSelectFractionDigits.asObserver()

        let thousandSeparatorElementViewModel = ThousandSeparatorElementViewModel(thousandSeparator: _thousandSeparator, onChangeThousandSeparator: _onChangeThousandSeparator.asObserver())
        
        items = Observable.just(ItemFormatElementViewModels(thousandSeparator: [thousandSeparatorElementViewModel], fractionDigits: _fractionDigits))
        
        super.init()
    }
}
