//
// ItemViewController.swift
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

public class ItemViewController: UITableViewController {
    private var _disposeBag: DisposeBag?
    public var viewModel: IItemViewModel?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var visibleSwitch: UISwitch!
    @IBOutlet weak var formatLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        viewModel.name
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.type
            .bindTo(typeLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.formula
            .bindTo(formulaLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.visible
            .bindTo(visibleSwitch.rx.value)
            .addDisposableTo(disposeBag)
        
        viewModel.format
            .bindTo(formatLabel.rx.text)
            .addDisposableTo(disposeBag)

        itemSelectedAt(section: 0, row: 0)
            .bindTo(viewModel.onSelectName)
            .addDisposableTo(disposeBag)

        itemSelectedAt(section: 0, row: 1)
            .bindTo(viewModel.onSelectType)
            .addDisposableTo(disposeBag)

        itemSelectedAt(section: 1, row: 0)
            .bindTo(viewModel.onSelectFormula)
            .addDisposableTo(disposeBag)

        visibleSwitch.rx.value
            .bindTo(viewModel.onChangeVisible)
            .addDisposableTo(disposeBag)
        
        itemSelectedAt(section: 2, row: 1)
            .bindTo(viewModel.onSelectFormat)
            .addDisposableTo(disposeBag)
        
        _disposeBag = disposeBag
    }

    private func itemSelectedAt(section: Int, row: Int) -> Observable<Void> {
        return tableView.rx.itemSelected
            .filter { $0.section == section && $0.row == row }
            .map { _ -> Void in }
    }
}
