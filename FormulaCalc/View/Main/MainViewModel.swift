//
// MainViewModel.swift
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

public protocol IMainViewModel: IViewModel {
    var onViewDidAppear: AnyObserver<[Any]> { get }
}

public class MainViewModel: IMainViewModel {
    public typealias Locator = ISheetListViewModelLocator
    
    public let message: Observable<Message>

    public let onViewDidAppear: AnyObserver<[Any]>
    
    private let _locator: Locator
    private var _startupDidEnd: Bool = false
    private let _onViewDidAppear = ActionObserver<[Any]>()
    private let _messageSlot = MessageSlot()
    
    public init(locator: Locator) {
        _locator = locator
        onViewDidAppear = _onViewDidAppear.asObserver()

        message = _messageSlot.message
        
        _onViewDidAppear.handler = { [weak self] _ in self?.handleViewDidAppear() }
    }
    
    private func handleViewDidAppear() {
        if !_startupDidEnd {
            let sheetListViewModel = _locator.resolveSheetListViewModel()
            _messageSlot.send(TransitionMessage(viewModel: sheetListViewModel, type: .present, animated: false))
            _startupDidEnd = true
        }
    }
}
