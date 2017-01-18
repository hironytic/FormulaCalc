//
// ItemNameViewModel.swift
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

public protocol IItemNameViewModel: IViewModel {
    var name: Observable<String?> { get }
    
    var onNameChanged: AnyObserver<String?> { get }
}

public protocol IItemNameViewModelFactory {
    func newItemNameViewModel(context: IContext) -> IItemNameViewModel
}
extension IItemNameViewModelFactory {
    public func newItemNameViewModel(context: IContext) -> IItemNameViewModel {
        return ItemNameViewModel(context: context)
    }
}

public class ItemNameViewModel: ViewModel, IItemNameViewModel {
    public let name: Observable<String?>
    public let onNameChanged: AnyObserver<String?>
    
    private let _onNameChanged = ActionObserver<String?>()
    
    public override init(context: IContext) {
        self.name = Observable
            .just("なまえ")
        
        self.onNameChanged = _onNameChanged.asObserver()
        
        super.init(context: context)
    }
}
