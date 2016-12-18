//
// TextEntryViewModel.swift
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

import Foundation
import RxSwift

public protocol ITextEntryViewModel: IViewModel {
    var title: Observable<String> { get }
    var placeholder: Observable<String?> { get }
    var text: Observable<String?> { get }
    
    var onTextChanged: AnyObserver<String?> { get }
    var onDone: AnyObserver<Void> { get }
    var onCancel: AnyObserver<Void> { get }
}

public class TextEntryViewModel: ViewModel, ITextEntryViewModel {
    public let title: Observable<String>
    public let placeholder: Observable<String?>
    public let text: Observable<String?>
    public let onTextChanged: AnyObserver<String?>
    public let onDone: AnyObserver<Void>
    public let onCancel: AnyObserver<Void>
    
    public init(title: String,
                placeholder: String,
                text: Observable<String?>,
                onTextChanged: AnyObserver<String?>,
                onDone: AnyObserver<Void>,
                onCancel: AnyObserver<Void>) {
        self.title = Observable
            .just(title)
        
        self.placeholder = Observable
            .just(placeholder)
        
        self.text = text
            .asDriver(onErrorJustReturn: "")
            .asObservable()

        self.onTextChanged = onTextChanged
        self.onDone = onDone
        self.onCancel = onCancel
        
        super.init()
    }
}
