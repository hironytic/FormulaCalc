//
// SheetItemStore.swift
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
import RealmSwift

public enum SheetItemStoreError: Error {
    case itemNotFound
}

public protocol ISheetItemStore: class {
    var update: Observable<SheetItem?> { get }

    var onUpdateName: AnyObserver</* name: */ String> { get }
    var onUpdateType: AnyObserver</* type: */ SheetItemType> { get }
    var onUpdateNumberValue: AnyObserver</* numberValue: */ Double> { get }
    var onUpdateStringValue: AnyObserver</* stringValue: */ String> { get }
    var onUpdateFormula: AnyObserver</* formula: */ String> { get }
    var onUpdateThousandSeparator: AnyObserver</* thousandSeparator: */ Bool> { get }
    var onUpdateFractionDigits: AnyObserver</* fractionDigits: */ Int> { get }
    var onUpdateVisible: AnyObserver</* visible: */ Bool> { get }
}

public protocol ISheetItemStoreLocator {
    func resolveSheetItemStore(id: String) -> ISheetItemStore
}

extension DefaultLocator: ISheetItemStoreLocator {
    public func resolveSheetItemStore(id: String) -> ISheetItemStore {
        return SheetItemStore(locator: self, id: id)
    }
}

public class SheetItemStore: ISheetItemStore {
    public typealias Locator = IErrorStoreLocator & ISheetDatabaseLocator
    
    public let update: Observable<SheetItem?>
    
    public let onUpdateName: AnyObserver</* name: */ String>
    public let onUpdateType: AnyObserver</* type: */ SheetItemType>
    public let onUpdateNumberValue: AnyObserver</* numberValue: */ Double>
    public let onUpdateStringValue: AnyObserver</* stringValue: */ String>
    public let onUpdateFormula: AnyObserver</* formula: */ String>
    public let onUpdateThousandSeparator: AnyObserver</* thousandSeparator: */ Bool>
    public let onUpdateFractionDigits: AnyObserver</* fractionDigits: */ Int>
    public let onUpdateVisible: AnyObserver</* visible: */ Bool>
    
    private let _locator: Locator
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken?
    private var _lastNewItemNumber = 0
    private let _updateSubject: BehaviorSubject<SheetItem?>

    private let _onUpdateName = ActionObserver</* newName: */ String>()
    private let _onUpdateType = ActionObserver</* type: */ SheetItemType>()
    private let _onUpdateNumberValue = ActionObserver</* numberValue: */ Double>()
    private let _onUpdateStringValue = ActionObserver</* stringValue: */ String>()
    private let _onUpdateFormula = ActionObserver</* formula: */ String>()
    private let _onUpdateThousandSeparator = ActionObserver</* thousandSeparator: */ Bool>()
    private let _onUpdateFractionDigits = ActionObserver</* fractionDigits: */ Int>()
    private let _onUpdateVisible = ActionObserver</* visible: */ Bool>()
    
    public init(locator: Locator, id: String) {
        _locator = locator
        _sheetDatabase = _locator.resolveSheetDatabase()
        
        do {
            let realm = try _sheetDatabase.createRealm()
            
            let results = realm.objects(SheetItem.self).filter("id = %@", id)
            let sheetItem = results.first
            let updateSubject = BehaviorSubject(value: sheetItem)
            _updateSubject = updateSubject
            
            _notificationToken = results.addNotificationBlock { changes in
                switch changes {
                case .update(let results, _, _, _):
                    updateSubject.onNext(results.first)
                default:
                    break
                }
            }
        } catch let error {
            _updateSubject = BehaviorSubject(value: nil)
            _notificationToken = nil
            
            _locator.resolveErrorStore().onPostError.onNext(error)
        }
        
        update = _updateSubject.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        onUpdateType = _onUpdateType.asObserver()
        onUpdateNumberValue = _onUpdateNumberValue.asObserver()
        onUpdateStringValue = _onUpdateStringValue.asObserver()
        onUpdateFormula = _onUpdateFormula.asObserver()
        onUpdateThousandSeparator = _onUpdateThousandSeparator.asObserver()
        onUpdateFractionDigits = _onUpdateFractionDigits.asObserver()
        onUpdateVisible = _onUpdateVisible.asObserver()

        _onUpdateName.handler = { [weak self] name in self?.updateValue({ $0.name = name }) }
        _onUpdateType.handler = { [weak self] type in self?.updateValue({ $0.type = type }) }
        _onUpdateNumberValue.handler = { [weak self] numberValue in self?.updateValue({ $0.numberValue = numberValue }) }
        _onUpdateStringValue.handler = { [weak self] stringValue in self?.updateValue({ $0.stringValue = stringValue }) }
        _onUpdateFormula.handler = { [weak self] formula in self?.updateValue({ $0.formula = formula }) }
        _onUpdateThousandSeparator.handler = { [weak self] thousandSeparator in self?.updateValue({ $0.thousandSeparator = thousandSeparator }) }
        _onUpdateFractionDigits.handler = { [weak self] fractionDigits in self?.updateValue({ $0.fractionDigits = fractionDigits }) }
        _onUpdateVisible.handler = { [weak self] visible in self?.updateValue({ $0.visible = visible }) }
    }
    
    deinit {
        self._notificationToken?.stop()
    }
    
    private func updateValue(_ updater: @escaping (SheetItem) -> Void) {
        do {
            guard let sheetItem = try _updateSubject.value() else { throw SheetItemStoreError.itemNotFound }
            
            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                updater(sheetItem)
            }
        } catch let error {
            _locator.resolveErrorStore().onPostError.onNext(error)
        }
    }
}

