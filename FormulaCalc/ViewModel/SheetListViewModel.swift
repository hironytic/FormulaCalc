//
// SheetListViewModel.swift
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

public protocol ISheetListElementViewModel: IViewModel {
    var title: Observable<String?> { get }
}

public protocol ISheetListViewModel: IViewModel {
    var sheetList: Observable<[ISheetListElementViewModel]> { get }
    
    var onNew: AnyObserver<Void> { get }
    var onDelete: AnyObserver<ISheetListElementViewModel> { get }
    var onSelect: AnyObserver<ISheetListElementViewModel> { get }
}

public class SheetListElementViewModel: ViewModel, ISheetListElementViewModel {
    public let id: String
    public let title: Observable<String?>
    
    public init(id: String, title: String) {
        self.id = id
        self.title = Observable.just(title)
    }
}

public class SheetListViewModel: ViewModel, ISheetListViewModel {
    public let sheetList: Observable<[ISheetListElementViewModel]>
    public private(set) var onNew: AnyObserver<Void>
    public private(set) var onDelete: AnyObserver<ISheetListElementViewModel>
    public private(set) var onSelect: AnyObserver<ISheetListElementViewModel>
    
    private let _disposeBag = DisposeBag()
    private let _onNew = ActionObserver<Void>()
    private let _onDelete = ActionObserver<ISheetListElementViewModel>()
    private let _onSelect = ActionObserver<ISheetListElementViewModel>()

    public override init() {
        sheetList = Observable.just([
            SheetListElementViewModel(id: "test1", title: "Test1"),
            SheetListElementViewModel(id: "test2", title: "Test2"),
        ])
        
        onNew = _onNew.asObserver()
        onDelete = _onDelete.asObserver()
        onSelect = _onSelect.asObserver()
        
        super.init()
        
        _onNew.handler = { [weak self] in self?.handleOnNew() }
        _onSelect.handler = { item in print("onSelect - \((item as! SheetListElementViewModel).id)") }
        _onDelete.handler = { item in print("onDelete - \((item as! SheetListElementViewModel).id)") }
    }
    
    private func handleOnNew() {
        let itemNameViewModel = ItemNameViewModel()
        sendMessage(TransitionMessage(viewModel: itemNameViewModel, type: .push, animated: true))
    }
}

