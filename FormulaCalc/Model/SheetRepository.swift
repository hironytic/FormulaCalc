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
}

public protocol ISheetRepository: class {
    var error: Observable<Error> { get }
    var change: Observable<Sheet?> { get }
    
    var onUpdateName: AnyObserver</* newName: */ String> { get }
}

public class SheetRepository: ISheetRepository {
    public let error: Observable<Error>
    public let change: Observable<Sheet?>

    public let onUpdateName: AnyObserver</* newName: */ String>
    
    private let _sheetDatabase: ISheetDatabase
    private let _notificationToken: NotificationToken
    private let _errorSubject = PublishSubject<Error>()
    private let _changeSubject: BehaviorSubject<Sheet?>
    
    private let _onUpdateName = ActionObserver</* newName: */ String>()
    
    public init(context: IContext, id: String) throws {
        _sheetDatabase = (context as! ISheetRepositoryContext).sheetDatabase
        
        let realm = try _sheetDatabase.createRealm()
        let results = realm.objects(Sheet.self).filter("id = %@", id)
        let changeSubject = BehaviorSubject<Sheet?>(value: results.first)
        _changeSubject = changeSubject

        _notificationToken = results.addNotificationBlock { changes in
            switch changes {
            case .update(let results, _, _, _):
                changeSubject.onNext(results.first)
            default:
                break
            }
        }

        error = _errorSubject.asObservable()
        change = _changeSubject.asObservable()
        
        onUpdateName = _onUpdateName.asObserver()
        
        _onUpdateName.handler = { [weak self] newName in self?.updateName(newName) }
    }
    
    deinit {
        self._notificationToken.stop()
    }
    
    private func updateName(_ newName: String) {
        do {
            guard let sheet = try _changeSubject.value() else { throw SheetRepositoryError.sheetNotFound }
            
            let realm = try _sheetDatabase.createRealm()
            try realm.write {
                sheet.name = newName
            }
        } catch let error {
            _errorSubject.onNext(error)
        }
    }
}

public protocol ISheetRepositoryContext: IContext, ISheetDatabaseGetter {
}
