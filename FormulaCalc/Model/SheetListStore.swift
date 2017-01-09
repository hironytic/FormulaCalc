//
// SheetListStore.swift
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

public struct SheetListStoreUpdate {
    let sheetList: AnyRandomAccessCollection<Sheet>
    let deletions: [Int]
    let insertions: [Int]
    let modifications: [Int]
}

public protocol ISheetListStore: class {
    var update: Observable<SheetListStoreUpdate> { get }
    
    var onCreateNewSheet: AnyObserver</* name: */ String> { get }
    var onDeleteSheet: AnyObserver</* id: */ String> { get }
}

public protocol ISheetListStoreFactory {
    func newSheetListStore(context: IContext) -> ISheetListStore
}

extension DefaultContext: ISheetListStoreFactory {
    public func newSheetListStore(context: IContext) -> ISheetListStore {
        return SheetListStore(context: context)
    }
}

public protocol ISheetListStoreContext: IContext, IErrorStoreGetter, ISheetDatabaseGetter {
}

extension DefaultContext: ISheetListStoreContext {
}

public class SheetListStore: ISheetListStore {
    public let update: Observable<SheetListStoreUpdate>
    
    public let onCreateNewSheet: AnyObserver</* name: */ String>
    public let onDeleteSheet: AnyObserver</* id: */ String>
    
    private let _context: ISheetListStoreContext
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken?
    private let _updateSubject: BehaviorSubject<SheetListStoreUpdate>
    
    private let _onCreateNewSheet = ActionObserver</* name: */ String>()
    private let _onDeleteSheet = ActionObserver</* id: */ String>()
    
    public init(context: IContext) {
        _context = context as! ISheetListStoreContext

        _sheetDatabase = _context.sheetDatabase

        do {
            let realm = try _sheetDatabase.createRealm()
            let results = realm.objects(Sheet.self).sorted(byProperty: "name")
            let updateSubject = BehaviorSubject(value: SheetListStoreUpdate(sheetList: AnyRandomAccessCollection(results),
                                                                              deletions: [],
                                                                              insertions: (0 ..< results.count).map { $0 },
                                                                              modifications: []))
            _updateSubject = updateSubject
            _notificationToken = results.addNotificationBlock { changes in
                switch changes {
                case .update(let results, let deletions, let insertions, let modifications):
                    updateSubject.onNext(SheetListStoreUpdate(sheetList: AnyRandomAccessCollection(results),
                                                                   deletions: deletions,
                                                                   insertions: insertions,
                                                                   modifications: modifications))
                default:
                    break
                }
            }
        } catch let error {
            _updateSubject = BehaviorSubject(value: SheetListStoreUpdate(sheetList: AnyRandomAccessCollection([]), deletions: [], insertions: [], modifications: []))
            _notificationToken = nil
            
            _context.errorStore.onPostError.onNext(error)
        }

        update = _updateSubject.asObservable()
        
        onCreateNewSheet = _onCreateNewSheet.asObserver()
        onDeleteSheet = _onDeleteSheet.asObserver()
        
        _onCreateNewSheet.handler = { [weak self] name in self?.createNewSheet(name: name) }
        _onDeleteSheet.handler = { [weak self] id in self?.deleteSheet(id: id) }
    }
    
    deinit {
        self._notificationToken?.stop()
    }
    
    private func createNewSheet(name: String) {
        let newSheet = Sheet()
        newSheet.id = UUID().uuidString
        newSheet.name = name
        
        do {
            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                realm.add(newSheet)
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
    
    private func deleteSheet(id: String) {
        do {
            let realm = try _sheetDatabase.createRealm()
            if let sheet = realm.objects(Sheet.self).filter("id = %@", id).first {
                try realm.write {
                    realm.delete(sheet)
                }
            }
        } catch let error {
            _context.errorStore.onPostError.onNext(error)
        }
    }
}
