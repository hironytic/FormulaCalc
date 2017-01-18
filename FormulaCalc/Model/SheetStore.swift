//
// SheetStore.swift
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

public enum SheetStoreError: Error {
    case sheetNotFound
    case itemNotFound
}

public struct SheetStoreItemListUpdate {
    let itemList: AnyRandomAccessCollection<SheetItem>
    let deletions: [Int]
    let insertions: [Int]
    let modifications: [Int]
}

public protocol ISheetStore: class {
    var update: Observable<Sheet?> { get }
    var itemListUpdate: Observable<SheetStoreItemListUpdate> { get }
    
    var onUpdateName: AnyObserver</* newName: */ String> { get }
    var onNewItem: AnyObserver<Void> { get }
    var onDeleteItem: AnyObserver</* id: */ String> { get }
}

public protocol ISheetStoreFactory {
    func newSheetStore(context: IContext, id: String) -> ISheetStore
}

extension ISheetStoreFactory {
    public func newSheetStore(context: IContext, id: String) -> ISheetStore {
        return SheetStore(context: context, id: id)
    }
}

public protocol ISheetStoreContext: IContext, IErrorStoreGetter, ISheetDatabaseGetter {}
extension DefaultContext: ISheetStoreContext {}
public class SheetStore: ISheetStore {
    public let update: Observable<Sheet?>
    public let itemListUpdate: Observable<SheetStoreItemListUpdate>

    public let onUpdateName: AnyObserver</* newName: */ String>
    public let onNewItem: AnyObserver<Void>
    public let onDeleteItem: AnyObserver</* id: */ String>
    
    private let _context: ISheetStoreContext
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken?
    private let _notificationTokenItemList: NotificationToken?
    private var _lastNewItemNumber = 0
    private let _updateSubject: BehaviorSubject<Sheet?>
    private let _itemListUpdateSubject: BehaviorSubject<SheetStoreItemListUpdate>
    
    private let _onUpdateName = ActionObserver</* newName: */ String>()
    private let _onNewItem = ActionObserver<Void>()
    private let _onDeleteItem = ActionObserver</* id: */ String>()
    
    public init(context: IContext, id: String) {
        _context = context as! ISheetStoreContext
        _sheetDatabase = _context.sheetDatabase
        
        do {
            let realm = try _sheetDatabase.createRealm()
            
            let results = realm.objects(Sheet.self).filter("id = %@", id)
            let sheet = results.first
            let updateSubject = BehaviorSubject(value: sheet)
            _updateSubject = updateSubject

            _notificationToken = results.addNotificationBlock { changes in
                switch changes {
                case .update(let results, _, _, _):
                    updateSubject.onNext(results.first)
                default:
                    break
                }
            }

            if let sheet = sheet {
                let itemListResults = sheet.items
                let itemListUpdateSubject = BehaviorSubject(value: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(itemListResults),
                                                                                            deletions: [],
                                                                                            insertions: (0 ..< results.count).map { $0 },
                                                                                            modifications: []))
                _itemListUpdateSubject = itemListUpdateSubject
                
                _notificationTokenItemList = itemListResults.addNotificationBlock { changes in
                    switch changes {
                    case .update(let results, let deletions, let insertions, let modifications):
                        itemListUpdateSubject.onNext(SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection(results),
                                                                              deletions: deletions,
                                                                              insertions: insertions,
                                                                              modifications: modifications))
                    default:
                        break
                    }
                }
            } else {
                _itemListUpdateSubject = BehaviorSubject(value: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection([]), deletions: [], insertions: [], modifications: []))
                _notificationTokenItemList = nil
            }
        } catch let error {
            _updateSubject = BehaviorSubject(value: nil)
            _notificationToken = nil
            _itemListUpdateSubject = BehaviorSubject(value: SheetStoreItemListUpdate(itemList: AnyRandomAccessCollection([]), deletions: [], insertions: [], modifications: []))
            _notificationTokenItemList = nil

            _context.errorStore.onPostError.onNext(error)
        }

        update = _updateSubject.asObservable()
        itemListUpdate = _itemListUpdateSubject.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        onNewItem = _onNewItem.asObserver()
        onDeleteItem = _onDeleteItem.asObserver()
        
        _onUpdateName.handler = { [weak self] newName in self?.updateName(newName) }
        _onNewItem.handler = { [weak self] in self?.newItem() }
        _onDeleteItem.handler = { [weak self] id in self?.deleteItem(id: id) }
    }
    
    deinit {
        self._notificationToken?.stop()
        self._notificationTokenItemList?.stop()
    }
    
    private func updateName(_ newName: String) {
        do {
            guard let sheet = try _updateSubject.value() else { throw SheetStoreError.sheetNotFound }
            
            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                sheet.name = newName
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
    
    private func newItem() {
        do {
            guard let sheet = try _updateSubject.value() else { throw SheetStoreError.sheetNotFound }
            
            let newItem = SheetItem()
            newItem.id = UUID().uuidString
            
            var newName: String
            repeat {
                _lastNewItemNumber += 1
                newName = "項目 \(_lastNewItemNumber)"
            } while sheet.items.contains(where: { $0.name == newName })
            newItem.name = newName
            
            newItem.type = .numeric
            
            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                sheet.items.append(newItem)
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
    
    private func deleteItem(id: String) {
        do {
            guard let sheet = try _updateSubject.value() else { throw SheetStoreError.sheetNotFound }
            guard let index = sheet.items.index(where: { $0.id == id }) else { throw SheetStoreError.itemNotFound }

            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                sheet.items.remove(objectAtIndex: index)
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
}
