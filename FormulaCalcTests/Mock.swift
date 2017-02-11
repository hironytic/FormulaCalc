//
// Mock.swift
// FormulaCalcTests
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
@testable import FormulaCalc

class MockSheetStore: ISheetStore {
    let update: Observable<Sheet?>
    let itemListUpdate: Observable<SheetStoreItemListUpdate>

    let onUpdateName: AnyObserver</* newName: */ String>
    let onNewItem: AnyObserver<Void>
    let onDeleteItem: AnyObserver</* id: */ String>
    
    private let _update: Variable<Sheet?>
    private let _itemListUpdate: Variable<SheetStoreItemListUpdate>
    private let _onUpdateName = ActionObserver</* newName: */ String>()
    private let _onNewItem = ActionObserver<Void>()
    private let _onDeleteItem = ActionObserver</* id: */ String>()
    
    var sheet: Sheet? {
        get { return _update.value }
    }
    var updateNameHandler: ActionObserver</* newName: */ String>.Handler {
        get { return _onUpdateName.handler }
        set { _onUpdateName.handler = newValue }
    }
    var newItemHandler: ActionObserver<Void>.Handler {
        get { return _onNewItem.handler }
        set { _onNewItem.handler = newValue }
    }
    var deleteItemHandler: ActionObserver</* id: */ String>.Handler {
        get { return _onDeleteItem.handler }
        set { _onDeleteItem.handler = newValue }
    }
    
    init(sheet: Sheet?) {
        _update = Variable(sheet)
        update = _update.asObservable()
        
        let sheetStoreItemListUpdate: SheetStoreItemListUpdate
        if let sheet = sheet {
            sheetStoreItemListUpdate = SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(sheet.items),
                                                                deletions: [],
                                                                insertions: Array(0 ..< sheet.items.count),
                                                                modifications: [])
        } else {
            sheetStoreItemListUpdate = SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection([]),
                                                                deletions: [],
                                                                insertions: [],
                                                                modifications: [])
        }
        _itemListUpdate = Variable(sheetStoreItemListUpdate)
        itemListUpdate = _itemListUpdate.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        onNewItem = _onNewItem.asObserver()
        onDeleteItem = _onDeleteItem.asObserver()
    }
    
    func update(sheet: Sheet?) {
        _update.value = sheet
    }
    
    func updateItemList(sheetStoreItemListUpdate: SheetStoreItemListUpdate) {
        _itemListUpdate.value = sheetStoreItemListUpdate
    }
}

class MockSheetItemStore: ISheetItemStore {
    var update: Observable<SheetItem?>
    
    var onUpdateName: AnyObserver</* name: */ String>
    var onUpdateType: AnyObserver</* type: */ SheetItemType>
    var onUpdateNumberValue: AnyObserver</* numberValue: */ Double>
    var onUpdateStringValue: AnyObserver</* stringValue: */ String>
    var onUpdateFormula: AnyObserver</* formula: */ String>
    var onUpdateThousandSeparator: AnyObserver</* thousandSeparator: */ Bool>
    var onUpdateFractionDigits: AnyObserver</* fractionDigits: */ Int>
    
    let _update: Variable<SheetItem?>
    private let _onUpdateName = ActionObserver</* name: */ String>()
    private let _onUpdateType = ActionObserver</* type: */ SheetItemType>()
    private let _onUpdateNumberValue = ActionObserver</* numberValue: */ Double>()
    private let _onUpdateStringValue = ActionObserver</* stringValue: */ String>()
    private let _onUpdateFormula = ActionObserver</* formula: */ String>()
    private let _onUpdateThousandSeparator = ActionObserver</* thousandSeparator: */ Bool>()
    private let _onUpdateFractionDigits = ActionObserver</* fractionDigits: */ Int>()
    
    var item: SheetItem? {
        get { return _update.value }
    }
    var updateNameHandler: ActionObserver</* name: */ String>.Handler {
        get { return _onUpdateName.handler }
        set { _onUpdateName.handler = newValue }
    }
    var updateTypeHandler: ActionObserver</* type: */ SheetItemType>.Handler {
        get { return _onUpdateType.handler }
        set { _onUpdateType.handler = newValue }
    }
    var updateNumberValueHandler: ActionObserver</* numberValue: */ Double>.Handler {
        get { return _onUpdateNumberValue.handler }
        set { _onUpdateNumberValue.handler = newValue }
    }
    var updateStringValueHandler: ActionObserver</* stringValue: */ String>.Handler {
        get { return _onUpdateStringValue.handler }
        set { _onUpdateStringValue.handler = newValue }
    }
    var updateFormulaHandler: ActionObserver</* formula: */ String>.Handler {
        get { return _onUpdateFormula.handler }
        set { _onUpdateFormula.handler = newValue }
    }
    var updateThousandSeparatorHandler: ActionObserver</* thousandSeparator: */ Bool>.Handler {
        get { return _onUpdateThousandSeparator.handler }
        set { _onUpdateThousandSeparator.handler = newValue }
    }
    var updateFractionDigitsHandler: ActionObserver</* fractionDigits: */ Int>.Handler {
        get { return _onUpdateFractionDigits.handler }
        set { _onUpdateFractionDigits.handler = newValue }
    }
    
    init(item: SheetItem?) {
        _update = Variable(item)
        update = _update.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        onUpdateType = _onUpdateType.asObserver()
        onUpdateNumberValue = _onUpdateNumberValue.asObserver()
        onUpdateStringValue = _onUpdateStringValue.asObserver()
        onUpdateFormula = _onUpdateFormula.asObserver()
        onUpdateThousandSeparator = _onUpdateThousandSeparator.asObserver()
        onUpdateFractionDigits = _onUpdateFractionDigits.asObserver()
    }
    
    func update(item: SheetItem?) {
        _update.value = item
    }
}
