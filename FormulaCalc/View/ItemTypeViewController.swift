//
// ItemTypeViewController.swift
// FormulaCalc
//
// Copyright (c) 2016 Hironori Ichimiya <hiron@hironytic.com>
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

public class ItemTypeElementCell: UITableViewCell {
    private var _disposeBag: DisposeBag?
    
    public var viewModel: IItemTypeElementViewModel? {
        didSet {
            _disposeBag = nil
            guard let viewModel = viewModel else { return }
            
            let disposeBag = DisposeBag()

            if let textLabel = textLabel {
                viewModel.name
                    .bindTo(textLabel.rx.text)
                    .addDisposableTo(disposeBag)
            }

            viewModel.accessoryType
                .bindTo(self.rx.accessoryType)
                .addDisposableTo(disposeBag)
            
            _disposeBag = disposeBag
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.viewModel = nil
    }
    
}

public class ItemTypeViewController: UITableViewController {
    private var _disposeBag: DisposeBag?
    public var viewModel: IItemTypeViewModel?

    public override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        let dataSource = ItemTypeDataSource()
        viewModel.typeList
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(disposeBag)
        
        tableView.rx.modelSelected(IItemTypeElementViewModel.self)
            .bindTo(viewModel.onSelect)
            .addDisposableTo(disposeBag)
        
        _disposeBag = disposeBag
    }
    
}

public class ItemTypeDataSource: NSObject {
    fileprivate var _itemModels: Element = []
}

extension ItemTypeDataSource: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.Id.cell, for: indexPath) as! ItemTypeElementCell
        let element = _itemModels[(indexPath as NSIndexPath).row]
        cell.viewModel = element
        return cell
    }
}

extension ItemTypeDataSource: RxTableViewDataSourceType {
    public typealias Element = [IItemTypeElementViewModel]
    
    public func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        UIBindingObserver(UIElement: self) { (dataSource, element) in
            dataSource._itemModels = element
            tableView.reloadData()
            }
            .on(observedEvent)
    }
}

extension ItemTypeDataSource: SectionedViewDataSourceType {
    public func model(at indexPath: IndexPath) throws -> Any {
        precondition(indexPath.section == 0)
        return _itemModels[indexPath.row]
    }
}
