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
    var name: Observable<String?> { get }
    var value: Observable<String?> { get }
}

public protocol ISheetViewModel: IViewModel {
    var title: Observable<String?> { get }
    var itemList: Observable<[ISheetElementViewModel]> { get }
}

public protocol ISheetViewModelFactory {
    func newSheetViewModel(context: IContext) throws -> ISheetViewModel
}

extension DefaultContext: ISheetViewModelFactory {
    public func newSheetViewModel(context: IContext) throws -> ISheetViewModel {
        return SheetViewModel(context: context)
    }
}

public class SheetElementViewModel: ViewModel, ISheetElementViewModel {
    public let name: Observable<String?>
    public let value: Observable<String?>
    
    public override init(context: IContext) {
        name = Observable.just("項目名")
        value = Observable.just("12345.6")
        
        super.init(context: context)
    }
}

public class SheetViewModel: ViewModel, ISheetViewModel {
    public let title: Observable<String?>
    public let itemList: Observable<[ISheetElementViewModel]>
    
    public override init(context: IContext) {
        title = Observable.just("シート名")
        itemList = Observable.just([SheetElementViewModel(context: context), SheetElementViewModel(context: context)])
        
        super.init(context: context)
    }
}
