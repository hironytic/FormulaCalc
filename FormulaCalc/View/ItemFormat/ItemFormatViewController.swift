//
// ItemFormatViewController.swift
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

public class ThousandSeparatorElementCell: UITableViewCell {
    private var _disposeBag: DisposeBag?
    
    @IBOutlet weak var thousandSeparatorSwitch: UISwitch!
    
    public var viewModel: IThousandSeparatorElementViewModel? {
        didSet {
            _disposeBag = nil
            guard let viewModel = viewModel else { return }
            
            let disposeBag = DisposeBag()
            
            viewModel.thousandSeparator
                .bind(to: thousandSeparatorSwitch.rx.isOn)
                .disposed(by: disposeBag)

            thousandSeparatorSwitch.rx.isOn
                .bind(to: viewModel.onChangeThousandSeparator)
                .disposed(by: disposeBag)
            
            _disposeBag = disposeBag
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.viewModel = nil
    }
}

public class FractionDigitsElementCell: UITableViewCell {
    private var _disposeBag: DisposeBag?
    
    public var viewModel: IFractionsDigitsElementViewModel? {
        didSet {
            _disposeBag = nil
            guard let viewModel = viewModel else { return }
            
            let disposeBag = DisposeBag()
            
            if let textLabel = textLabel {
                viewModel.name
                    .bind(to: textLabel.rx.text)
                    .disposed(by: disposeBag)
            }
            
            viewModel.accessoryType
                .bind(to: self.rx.accessoryType)
                .disposed(by: disposeBag)
            
            _disposeBag = disposeBag
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.viewModel = nil
    }
}

public class ItemFormatViewController: UITableViewController {
    private var _disposeBag: DisposeBag?
    public var viewModel: IItemFormatViewModel?

    public override func viewWillAppear(_ animated: Bool) {
        bindViewModel()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        _disposeBag = nil
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        let dataSource = ItemFormatDataSource()
        viewModel.items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(IFractionsDigitsElementViewModel.self)
            .bind(to: viewModel.onSelectFractionDigits)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }
}

public class ItemFormatDataSource: NSObject {
    fileprivate var _itemModels: Element = ItemFormatElementViewModels(thousandSeparator: [], fractionDigits: [])
}

extension ItemFormatDataSource: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return _itemModels.thousandSeparator.count
        case 1:
            return _itemModels.fractionDigits.count
        default:
            fatalError()
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.Id.thousandSeparator, for: indexPath) as! ThousandSeparatorElementCell
            let element = _itemModels.thousandSeparator[indexPath.row]
            cell.viewModel = element
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.Id.fractionDigits, for: indexPath) as! FractionDigitsElementCell
            let element = _itemModels.fractionDigits[indexPath.row]
            cell.viewModel = element
            return cell
        default:
            fatalError()
        }
    }
}

extension ItemFormatDataSource: RxTableViewDataSourceType {
    public typealias Element = ItemFormatElementViewModels
    
    public func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        UIBindingObserver(UIElement: self) { (dataSource, element) in
            dataSource._itemModels = element
            tableView.reloadData()
        }
        .on(observedEvent)
    }
}

extension ItemFormatDataSource: SectionedViewDataSourceType {
    public func model(at indexPath: IndexPath) throws -> Any {
        precondition(indexPath.section == 1)
        return _itemModels.fractionDigits[indexPath.row]
    }
}
