//
// SheetListViewController.swift
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

import UIKit
import RxSwift
import RxCocoa

private typealias R = Resource

public class SheetListElementCell: UITableViewCell {
    private var _disposeBag: DisposeBag?

    public var viewModel: ISheetListElementViewModel? {
        didSet {
            _disposeBag = nil
            guard let viewModel = viewModel else { return }
            
            let disposeBag = DisposeBag()
            
            if let textLabel = textLabel {
                viewModel.title
                    .bindTo(textLabel.rx.text)
                    .addDisposableTo(disposeBag)
            }
            
            _disposeBag = disposeBag
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.viewModel = nil
    }
}

public class SheetListViewController: UITableViewController {
    private var _disposeBag: DisposeBag?
    public var viewModel: ISheetListViewModel?
    
    @IBOutlet weak var newButton: UIBarButtonItem!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        bindViewModel()
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        let dataSource = SheetListDataSource()
        viewModel.sheetList
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(disposeBag)

        viewModel.message
            .bindTo(transitioner)
            .addDisposableTo(disposeBag)
        
        newButton.rx.tap
            .bindTo(viewModel.onNew)
            .addDisposableTo(disposeBag)
        
        tableView.rx.modelSelected(ISheetListElementViewModel.self)
            .bindTo(viewModel.onSelect)
            .addDisposableTo(disposeBag)
        
        tableView.rx.modelDeleted(ISheetListElementViewModel.self)
            .bindTo(viewModel.onDelete)
            .addDisposableTo(disposeBag)
        
        _disposeBag = disposeBag
    }
}

public class SheetListDataSource: NSObject {
    fileprivate var _itemModels: Element = []
}

extension SheetListDataSource: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.Id.cell, for: indexPath) as! SheetListElementCell
        let element = _itemModels[(indexPath as NSIndexPath).row]
        cell.viewModel = element
        return cell
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension SheetListDataSource: RxTableViewDataSourceType {
    public typealias Element = [ISheetListElementViewModel]
    
    public func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        UIBindingObserver(UIElement: self) { (dataSource, element) in
            dataSource._itemModels = element
            tableView.reloadData()
        }
        .on(observedEvent)
    }
}

extension SheetListDataSource: SectionedViewDataSourceType {
    public func model(at indexPath: IndexPath) throws -> Any {
        precondition(indexPath.section == 0)
        return _itemModels[indexPath.row]
    }
}
