//
// SheetRepository.swift
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

public enum SheetRepositoryError: Error {
    case sheetNotFound
    case itemNotFound
}

public protocol ISheetRepository: class {
    var change: Observable<Sheet?> { get }
    
    var onUpdateName: AnyObserver</* newName: */ String> { get }
    var onNewItem: AnyObserver<Void> { get }
    var onDeleteItem: AnyObserver</* id: */ String> { get }
}

public protocol ISheetRepositoryFactory {
    func newSheetRepository(context: IContext, id: String) -> ISheetRepository
}

extension DefaultContext: ISheetRepositoryFactory {
    public func newSheetRepository(context: IContext, id: String) -> ISheetRepository {
        return SheetRepository(context: context, id: id)
    }
}

public protocol ISheetRepositoryContext: IContext, IErrorStoreGetter, ISheetDatabaseGetter {
}

extension DefaultContext: ISheetRepositoryContext {
}

public class SheetRepository: ISheetRepository {
    public let change: Observable<Sheet?>

    public let onUpdateName: AnyObserver</* newName: */ String>
    public let onNewItem: AnyObserver<Void>
    public let onDeleteItem: AnyObserver</* id: */ String>
    
    private let _context: ISheetRepositoryContext
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken?
    private var _lastNewItemNumber = 0
    private let _changeSubject: BehaviorSubject<Sheet?>
    
    private let _onUpdateName = ActionObserver</* newName: */ String>()
    private let _onNewItem = ActionObserver<Void>()
    private let _onDeleteItem = ActionObserver</* id: */ String>()
    
    public init(context: IContext, id: String) {
        _context = context as! ISheetRepositoryContext
        _sheetDatabase = _context.sheetDatabase
        
        do {
            let realm = try _sheetDatabase.createRealm()
            let results = realm.objects(Sheet.self).filter("id = %@", id)
            let changeSubject = BehaviorSubject(value: results.first)
            _changeSubject = changeSubject

            _notificationToken = results.addNotificationBlock { changes in
                switch changes {
                case .update(let results, _, _, _):
                    changeSubject.onNext(results.first)
                default:
                    break
                }
            }
        } catch let error {
            _changeSubject = BehaviorSubject(value: nil)
            _notificationToken = nil

            _context.errorStore.onPostError.onNext(error)
        }

        change = _changeSubject.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        onNewItem = _onNewItem.asObserver()
        onDeleteItem = _onDeleteItem.asObserver()
        
        _onUpdateName.handler = { [weak self] newName in self?.updateName(newName) }
        _onNewItem.handler = { [weak self] in self?.newItem() }
        _onDeleteItem.handler = { [weak self] id in self?.deleteItem(id: id) }
    }
    
    deinit {
        self._notificationToken?.stop()
    }
    
    private func updateName(_ newName: String) {
        do {
            guard let sheet = try _changeSubject.value() else { throw SheetRepositoryError.sheetNotFound }
            
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
            guard let sheet = try _changeSubject.value() else { throw SheetRepositoryError.sheetNotFound }
            
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
            guard let sheet = try _changeSubject.value() else { throw SheetRepositoryError.sheetNotFound }
            guard let index = sheet.items.index(where: { $0.id == id }) else { throw SheetRepositoryError.itemNotFound }

            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                sheet.items.remove(objectAtIndex: index)
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
}
