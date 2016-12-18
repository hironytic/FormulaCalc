//
// RxCocoaComplement.swift
// FormulaCalc
//
// Copyright (c) 2016 Hironori Ichimiya <hiron@hironytic.com>
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
import RxCocoa

extension Reactive where Base: UITableView {
    public func modelDeleted<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source: Observable<T> = self.itemDeleted.flatMap { [weak view = self.base as UITableView] indexPath -> Observable<T> in
            guard let view = view else {
                return Observable.empty()
            }
            
            return Observable.just(try view.rx.model(at: indexPath))
        }
        
        return ControlEvent(events: source)
    }
}

extension Reactive where Base: UIBarButtonItem {
    /**
     Bindable sink for `title` property.
     */
    public var title: AnyObserver<String?> {
        return UIBindingObserver(UIElement: self.base) { UIElement, title in
            UIElement.title = title
        }.asObserver()
    }
}
