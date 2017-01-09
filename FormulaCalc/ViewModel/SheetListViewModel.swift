//
// SheetListViewModel.swift
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

private typealias R = Resource

public protocol ISheetListElementViewModel: IViewModel {
    var title: Observable<String?> { get }
}

public protocol ISheetListViewModel: IViewModel {
    var sheetList: Observable<[ISheetListElementViewModel]> { get }
    
    var onNew: AnyObserver<Void> { get }
    var onDelete: AnyObserver<ISheetListElementViewModel> { get }
    var onSelect: AnyObserver<ISheetListElementViewModel> { get }
}

public protocol ISheetListViewModelFactory {
    func newSheetListViewModel(context: IContext) -> ISheetListViewModel
}

extension DefaultContext: ISheetListViewModelFactory {
    public func newSheetListViewModel(context: IContext) -> ISheetListViewModel {
        return SheetListViewModel(context: context)
    }
}

public protocol ISheetListViewModelContext: IContext, ISheetListStoreFactory {
}

extension DefaultContext: ISheetListViewModelContext {
}

public class SheetListElementViewModel: ViewModel, ISheetListElementViewModel {
    public let id: String
    public let title: Observable<String?>
    
    public init(context: IContext, id: String, title: String) {
        self.id = id
        self.title = Observable.just(title)
        
        super.init(context: context)
    }
}

public class SheetListViewModel: ViewModel, ISheetListViewModel {
    public let sheetList: Observable<[ISheetListElementViewModel]>
    public private(set) var onNew: AnyObserver<Void>
    public private(set) var onDelete: AnyObserver<ISheetListElementViewModel>
    public private(set) var onSelect: AnyObserver<ISheetListElementViewModel>
    
    private var _context: ISheetListViewModelContext { get { return super.context as! ISheetListViewModelContext } }
    private let _disposeBag = DisposeBag()
    private let _sheetListStore: ISheetListStore
    private let _onNew = ActionObserver<Void>()
    private let _onDelete = ActionObserver<ISheetListElementViewModel>()
    private let _onSelect = ActionObserver<ISheetListElementViewModel>()
    
    public override init(context: IContext) {
        let context = context as! ISheetListViewModelContext

        _sheetListStore = context.newSheetListStore(context: context)
        sheetList = _sheetListStore.update
            .map { update in
                return update.sheetList
                    .map { sheet in
                        return SheetListElementViewModel(context: context, id: sheet.id, title: sheet.name)
                    }
            }
            .asDriver(onErrorJustReturn: [])
            .asObservable()
        
        onNew = _onNew.asObserver()
        onDelete = _onDelete.asObserver()
        onSelect = _onSelect.asObserver()
        
        super.init(context: context)
        
        _onNew.handler = { [weak self] in self?.handleOnNew() }
        _onSelect.handler = { item in print("onSelect - \((item as! SheetListElementViewModel).id)") }
        _onDelete.handler = { item in print("onDelete - \((item as! SheetListElementViewModel).id)") }
    }
    
    private func handleOnNew() {
        class InputNameViewModel: ViewModel, IInputOneTextViewModel {
            let title: String? = ResourceUtils.getString(R.String.newSheetTitle)
            let detailMessage: String? = nil
            let placeholder: String? = ResourceUtils.getString(R.String.newSheetPlaceholder)
            let initialText = ""
            let cancelButtonTitle = ResourceUtils.getString(R.String.cancel)
            let doneButtonTitle = ResourceUtils.getString(R.String.newMessageDone)
            
            let onDone: AnyObserver<String>
            let onCancel = ActionObserver<Void>().asObserver()

            init(context: IContext, onDone: @escaping (String) -> Void) {
                self.onDone = ActionObserver(handler: onDone).asObserver()
                super.init(context: context)
            }
        }
        
        let viewModel = InputNameViewModel(context: context) { [weak self] name in
            self?._sheetListStore.onCreateNewSheet.onNext(name)
        }
        sendMessage(TransitionMessage(viewModel: viewModel, type: .present, animated: true))
    }
}
