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
    var name: Observable<String?> { get }
    var type: Observable<String?> { get }
    var invisibleMarkHidden: Observable<Bool> { get }
}

public protocol IDesignSheetViewModel: IViewModel {
    var title: Observable<String?> { get }
    var itemList: Observable<[IDesignSheetElementViewModel]> { get }
    
    var onNewItem: AnyObserver<Void> { get }
    var onSelectItem: AnyObserver<IDesignSheetElementViewModel> { get }
    var onDone: AnyObserver<Void> { get }
}

public protocol IDesignSheetViewModelFactory {
    func newDesignSheetViewModel(context: IContext, id: String) -> IDesignSheetViewModel
}

extension DefaultContext: IDesignSheetViewModelFactory {
    public func newDesignSheetViewModel(context: IContext, id: String) -> IDesignSheetViewModel {
        return DesignSheetViewModel(context: context, id: id)
    }
}

public class DesignSheetElementViewModel: ViewModel, IDesignSheetElementViewModel {
    public let name: Observable<String?>
    public let type: Observable<String?>
    public let invisibleMarkHidden: Observable<Bool>
    
    public override init(context: IContext) {
        name = Observable.just("項目名")
        type = Observable.just("数値入力")
        invisibleMarkHidden = Observable.just(false)
        
        super.init(context: context)
    }
}

public class DesignSheetViewModel: ViewModel, IDesignSheetViewModel {
    public let title: Observable<String?>
    public let itemList: Observable<[IDesignSheetElementViewModel]>
    
    public let onNewItem: AnyObserver<Void>
    public let onSelectItem: AnyObserver<IDesignSheetElementViewModel>
    public let onDone: AnyObserver<Void>
    
    private let _onNewItem = ActionObserver<Void>()
    private let _onSelectItem = ActionObserver<IDesignSheetElementViewModel>()
    private let _onDone = ActionObserver<Void>()
    
    public init(context: IContext, id: String) {
        title = Observable.just("シート名")
        itemList = Observable.just([DesignSheetElementViewModel(context: context), DesignSheetElementViewModel(context: context)])
        onNewItem = _onNewItem.asObserver()
        onSelectItem = _onSelectItem.asObserver()
        onDone = _onDone.asObserver()
        
        super.init(context: context)
    }
}
