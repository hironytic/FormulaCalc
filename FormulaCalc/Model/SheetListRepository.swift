//
// SheetListRepository.swift
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

public struct SheetListRepositoryChange {
    let sheetList: AnyRandomAccessCollection<Sheet>
    let deletions: [Int]
    let insertions: [Int]
    let modifications: [Int]
}

public protocol ISheetListRepository: class {
    var error: Observable<Error> { get }
    var change: Observable<SheetListRepositoryChange> { get }
    
    var onCreateNewSheet: AnyObserver</* name: */ String> { get }
    var onDeleteSheet: AnyObserver</* id: */ String> { get }
}

public class SheetListRepository: ISheetListRepository {
    public let error: Observable<Error>
    public let change: Observable<SheetListRepositoryChange>
    
    public let onCreateNewSheet: AnyObserver</* name: */ String>
    public let onDeleteSheet: AnyObserver</* id: */ String>
    
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken
    private let _errorSubject = PublishSubject<Error>()
    private let _changeSubject: BehaviorSubject<SheetListRepositoryChange>
    
    private let _onCreateNewSheet = ActionObserver</* name: */ String>()
    private let _onDeleteSheet = ActionObserver</* id: */ String>()
    
    public init(context: IContext) throws {
        _sheetDatabase = (context as! ISheetListRepositoryContext).sheetDatabase

        let realm = try _sheetDatabase.createRealm()
        let results = realm.objects(Sheet.self).sorted(byProperty: "name")
        let changeSubject = BehaviorSubject(value: SheetListRepositoryChange(sheetList: AnyRandomAccessCollection(results),
                                                                          deletions: [],
                                                                          insertions: (0 ..< results.count).map { $0 },
                                                                          modifications: []))
        _changeSubject = changeSubject
        _notificationToken = results.addNotificationBlock { changes in
            switch changes {
            case .update(let results, let deletions, let insertions, let modifications):
                changeSubject.onNext(SheetListRepositoryChange(sheetList: AnyRandomAccessCollection(results),
                                                               deletions: deletions,
                                                               insertions: insertions,
                                                               modifications: modifications))
            default:
                break
            }
        }

        error = _errorSubject.asObservable()
        change = _changeSubject.asObservable()
        
        onCreateNewSheet = _onCreateNewSheet.asObserver()
        onDeleteSheet = _onDeleteSheet.asObserver()
        
        _onCreateNewSheet.handler = { [weak self] name in self?.createNewSheet(name: name) }
        _onDeleteSheet.handler = { [weak self] id in self?.deleteSheet(id: id) }
    }
    
    deinit {
        self._notificationToken.stop()
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
            _errorSubject.onNext(error)
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
            _errorSubject.onNext(error)
        }
    }
}

public protocol ISheetListRepositoryContext: IContext, ISheetDatabaseGetter {
}
