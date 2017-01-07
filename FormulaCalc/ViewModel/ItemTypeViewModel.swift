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

public protocol IItemTypeElementViewModel: IViewModel {
    var name: Observable<String?> { get }
    var accessoryType: Observable<UITableViewCellAccessoryType> { get }
}

public protocol IItemTypeViewModel: IViewModel {
    var typeList: Observable<[IItemTypeElementViewModel]> { get }
    
    var onSelect: AnyObserver<IItemTypeElementViewModel> { get }
}

public class ItemTypeElementViewModel: ViewModel, IItemTypeElementViewModel {
    public let name: Observable<String?>
    public let accessoryType: Observable<UITableViewCellAccessoryType>
    
    public override init(context: IContext) {
        name = Observable.just("数値入力")
        accessoryType = Observable.just(UITableViewCellAccessoryType.checkmark)
        
        super.init(context: context)
    }
}

public class ItemTypeViewModel: ViewModel, IItemTypeViewModel {
    public let typeList: Observable<[IItemTypeElementViewModel]>
    
    public let onSelect: AnyObserver<IItemTypeElementViewModel>
    
    public let _onSelect = ActionObserver<IItemTypeElementViewModel>()
    
    public override init(context: IContext) {
        typeList = Observable.just([ItemTypeElementViewModel(context: context), ItemTypeElementViewModel(context: context)])
        onSelect = _onSelect.asObserver()
        
        super.init(context: context)
    }
}
