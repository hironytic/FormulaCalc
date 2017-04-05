//
// FormulaViewModel.swift
// FormulaCalc
//
// Copyright (c) 2017 Hironori Ichimiya <hiron@hironytic.com>
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

public protocol IFormulaViewModel: IViewModel {
    var formula: Observable<String?> { get }
    
    var onFormulaChanged: AnyObserver<String?> { get }
    var onFormulaEditingDidEnd: AnyObserver<Void> { get }
}

public protocol IFormulaViewModelLocator {
    func resolveFormulaViewModel(id: String) -> IFormulaViewModel
}
extension DefaultLocator: IFormulaViewModelLocator {
    public func resolveFormulaViewModel(id: String) -> IFormulaViewModel {
        return FormulaViewModel(locator: self, id: id)
    }
}

public class FormulaViewModel: IFormulaViewModel {
    public typealias Locator = ISheetItemStoreLocator
    
    public let formula: Observable<String?>
    public let onFormulaChanged: AnyObserver<String?>
    public let onFormulaEditingDidEnd: AnyObserver<Void>
    
    private let _onFormulaChanged = ActionObserver<String?>()
    private let _onFormulaEditingDidEnd = ActionObserver<Void>()
    
    private let _locator: Locator
    private let _id: String
    private let _sheetItemStore: ISheetItemStore
    private let _disposeBag = DisposeBag()
    private let _formula = Variable<String?>("")
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)
        
        _sheetItemStore.update
            .distinctUntilChanged({ $0?.formula }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.formula ?? ""
            }
            .bindTo(_formula)
            .disposed(by: _disposeBag)
        
        formula = _formula
            .asDriver()
            .asObservable()
        
        onFormulaChanged = _onFormulaChanged.asObserver()
        onFormulaEditingDidEnd = _onFormulaEditingDidEnd.asObserver()
        
        _onFormulaChanged.handler = { [weak self] (formula: String?) in self?.handleOnFormulaChanged(formula) }
        _onFormulaEditingDidEnd.handler = { [weak self] in self?.handleOnFormulaEditingDidEnd() }
    }
    
    private func handleOnFormulaChanged(_ formula: String?) {
        _formula.value = formula
    }
    
    private func handleOnFormulaEditingDidEnd() {
        _sheetItemStore.onUpdateFormula.onNext(_formula.value ?? "")
    }
}
