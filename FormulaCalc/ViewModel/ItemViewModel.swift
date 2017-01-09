//
// ItemViewModel.swift
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

public protocol IItemViewModel: IViewModel {
    var title: Observable<String?> { get }
    var name: Observable<String?> { get }
    var type: Observable<String?> { get }
    var formula: Observable<String?> { get }
    var visible: Observable<Bool> { get }
    var format: Observable<String?> { get }
    
    var onSelectName: AnyObserver<Void> { get }
    var onSelectType: AnyObserver<Void> { get }
    var onSelectFormula: AnyObserver<Void> { get }
    var onChangeVisible: AnyObserver<Bool> { get }
    var onSelectFormat: AnyObserver<Void> { get }
}

public protocol IItemViewModelFactory {
    func newItemViewModel(context: IContext) -> IItemViewModel
}

extension DefaultContext: IItemViewModelFactory {
    public func newItemViewModel(context: IContext) -> IItemViewModel {
        return ItemViewModel(context: context)
    }
}

public class ItemViewModel: ViewModel, IItemViewModel {
    public let title: Observable<String?>
    public let name: Observable<String?>
    public let type: Observable<String?>
    public let formula: Observable<String?>
    public let visible: Observable<Bool>
    public let format: Observable<String?>

    public let onSelectName: AnyObserver<Void>
    public let onSelectType: AnyObserver<Void>
    public let onSelectFormula: AnyObserver<Void>
    public let onChangeVisible: AnyObserver<Bool>
    public let onSelectFormat: AnyObserver<Void>

    private let _onSelectName = ActionObserver<Void>()
    private let _onSelectType = ActionObserver<Void>()
    private let _onSelectFormula = ActionObserver<Void>()
    private let _onChangeVisible = ActionObserver<Bool>()
    private let _onSelectFormat = ActionObserver<Void>()
    
    public override init(context: IContext) {
        title = Observable.just("タイトル")
        name = Observable.just("項目名")
        type = Observable.just("計算式")
        formula = Observable.just("{身長(cm)}/100")
        visible = Observable.just(true)
        format = Observable.just("自動")
        
        onSelectName = _onSelectName.asObserver()
        onSelectType = _onSelectType.asObserver()
        onSelectFormula = _onSelectFormula.asObserver()
        onChangeVisible = _onChangeVisible.asObserver()
        onSelectFormat = _onSelectFormat.asObserver()
        
        super.init(context: context)
        
        _onSelectName.handler = { print("onSelectName") }
        _onSelectType.handler = { print("onSelectType") }
        _onSelectFormula.handler = { print("onSelectFormula") }
        _onChangeVisible.handler = { _ in print("onChangeVisible") }
        _onSelectFormat.handler = { print("onSelectFormat") }
    }
}
