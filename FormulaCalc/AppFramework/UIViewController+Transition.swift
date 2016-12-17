//
// UIViewController+Transition.swift
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

public func createViewController(for viewModel: IViewModel) -> UIViewController {
    fatalError()
}

public extension UIViewController {
    public func transitioner(_ observable: Observable<Message>) -> Disposable {
        return observable
            .subscribe(onNext: { [unowned self] message in
                switch message {
                case let message as TransitionMessage:
                    let viewController = createViewController(for: message.viewModel)
                    switch message.type {
                    case .present:
                        self.present(viewController, animated: message.animated, completion: nil)
                    case .push:
                        self.navigationController?.pushViewController(viewController, animated: message.animated)
                    }
                
                case let message as DismissingMessage:
                    switch message.type {
                    case .dismiss:
                        self.dismiss(animated: message.animated, completion: nil)
                    case .pop:
                        _ = self.navigationController?.popViewController(animated: message.animated)
                    }
                    
                default:
                    break
                }
            })
    }
}
