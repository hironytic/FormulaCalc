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
}

public protocol IFormulaViewModelLocator {
    func resolveFormulaViewModel(id: String) -> IFormulaViewModel
}
extension DefaultLocator: IFormulaViewModelLocator {
    public func resolveFormulaViewModel(id: String) -> IFormulaViewModel {
        return FormulaViewModel(id: id)
    }
}

public class FormulaViewModel: IFormulaViewModel {
    public let formula: Observable<String?>
    public let onFormulaChanged: AnyObserver<String?>
    
    private let _onFormulaChanged = ActionObserver<String?>()
    
    public init(id: String) {
        self.formula = Observable
            .just("{身長(cm)}/100")
        
        self.onFormulaChanged = _onFormulaChanged.asObserver()
    }
}
