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

private typealias R = Resource

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

public protocol IItemViewModelLocator {
    func resolveItemViewModel(id: String) -> IItemViewModel
}
extension DefaultLocator: IItemViewModelLocator {
    public func resolveItemViewModel(id: String) -> IItemViewModel {
        return ItemViewModel(locator: self, id: id)
    }
}

public class ItemViewModel: ViewModel, IItemViewModel {
    public typealias Locator = ISheetItemStoreLocator & IItemNameViewModelLocator
                                & IItemTypeViewModelLocator & IFormulaViewModelLocator
                                & IItemFormatViewModelLocator
    
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

    private let _locator: Locator
    private let _id: String
    private let _sheetItemStore: ISheetItemStore
    private let _onSelectName = ActionObserver<Void>()
    private let _onSelectType = ActionObserver<Void>()
    private let _onSelectFormula = ActionObserver<Void>()
    private let _onChangeVisible = ActionObserver<Bool>()
    private let _onSelectFormat = ActionObserver<Void>()
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _id = id
        _sheetItemStore = _locator.resolveSheetItemStore(id: id)

        name = _sheetItemStore.update
            .distinctUntilChanged({ $0?.name }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.name ?? ""
            }
            .startWith("")
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        title = name

        type = _sheetItemStore.update
            .distinctUntilChanged({ $0?.type }, comparer: { $0 == $1 })
            .map { sheetItem in
                guard let sheetItem = sheetItem else { return "" }
                
                let type: String
                switch sheetItem.type {
                case .numeric:
                    type = ResourceUtils.getString(R.String.sheetItemTypeNumeric)
                case .string:
                    type = ResourceUtils.getString(R.String.sheetItemTypeString)
                case .formula:
                    type = ResourceUtils.getString(R.String.sheetItemTypeFormula)
                }
                return type
            }
            .startWith("")
            .asDriver(onErrorJustReturn: "")
            .asObservable()

        formula = _sheetItemStore.update
            .filter { $0?.type == .formula }
            .distinctUntilChanged({ $0?.formula }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.formula ?? ""
            }
            .startWith("")
            .asDriver(onErrorJustReturn: "")
            .asObservable()

        visible = _sheetItemStore.update
            .distinctUntilChanged({ $0?.visible }, comparer: { $0 == $1 })
            .map { sheetItem in
                return sheetItem?.visible ?? true
            }
            .startWith(true)
            .asDriver(onErrorJustReturn: true)
            .asObservable()
        
        format = _sheetItemStore.update
            .distinctUntilChanged({ ($0?.thousandSeparator, $0?.fractionDigits) }, comparer: { $0.0 == $1.0 && $0.1 == $1.1 })
            .map { sheetItem in
                guard let sheetItem = sheetItem else { return "" }
                
                var values: [String] = []
                if sheetItem.thousandSeparator {
                    values.append(ResourceUtils.getString(R.String.thousandSeparatorOn))
                }
                switch sheetItem.fractionDigits {
                case -1:
                    values.append(ResourceUtils.getString(R.String.fractionDigitsAuto))
                default:
                    values.append(ResourceUtils.getString(format: R.String.fractionDigitsFormat, sheetItem.fractionDigits))
                }
                return values.joined(separator: ", ")
            }
            .startWith("")
            .asDriver(onErrorJustReturn: "")
            .asObservable()
        
        onSelectName = _onSelectName.asObserver()
        onSelectType = _onSelectType.asObserver()
        onSelectFormula = _onSelectFormula.asObserver()
        onChangeVisible = _sheetItemStore.onUpdateVisible
        onSelectFormat = _onSelectFormat.asObserver()
        
        super.init()
        
        _onSelectName.handler = { [weak self] in self?.handleSelectName() }
        _onSelectType.handler = { [weak self] in self?.handleSelectType() }
        _onSelectFormula.handler = { [weak self] in self?.handleSelectFormula() }
        _onSelectFormat.handler = { [weak self] in self?.handleSelectFormat() }
    }
    
    private func handleSelectName() {
        let itemNameViewModel = _locator.resolveItemNameViewModel()
        sendMessage(TransitionMessage(viewModel: itemNameViewModel, type: .push, animated: true))
    }
    
    private func handleSelectType() {
        let itemTypeViewModel = _locator.resolveItemTypeViewModel()
        sendMessage(TransitionMessage(viewModel: itemTypeViewModel, type: .push, animated: true))
    }
    
    private func handleSelectFormula() {
        let formulaViewModel = _locator.resolveFormulaViewModel()
        sendMessage(TransitionMessage(viewModel: formulaViewModel, type: .push, animated: true))
    }

    private func handleSelectFormat() {
        let itemFormatViewModel = _locator.resolveItemFormatViewModel()
        sendMessage(TransitionMessage(viewModel: itemFormatViewModel, type: .push, animated: true))
    }
}
