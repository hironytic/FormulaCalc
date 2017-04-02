//
// SheetViewController.swift
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

public class SheetElementCell: UITableViewCell {
    private var _disposeBag: DisposeBag?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    public var viewModel: ISheetElementViewModel? {
        didSet {
            _disposeBag = nil
            guard let viewModel = viewModel else { return }
            
            let disposeBag = DisposeBag()
            
            viewModel.name
                .bindTo(nameLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.value
                .bindTo(valueLabel.rx.text)
                .disposed(by: disposeBag)
            
            _disposeBag = disposeBag
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.viewModel = nil
    }
}

public class SheetViewController: UITableViewController {
    private var _disposeBag: DisposeBag?
    public var viewModel: ISheetViewModel?

    @IBOutlet weak var designButton: UIBarButtonItem!
    
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

        viewModel.message
            .bindTo(transitioner)
            .disposed(by: disposeBag)
        
        viewModel.itemList
            .bindTo(tableView.rx.items(cellIdentifier: R.Id.cell, cellType: SheetElementCell.self)) { (row, element, cell) in
                cell.viewModel = element
            }
            .disposed(by: disposeBag)
        
        viewModel.title
            .bindTo(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        designButton.rx.tap
            .bindTo(viewModel.onTapDesignButton)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }
}
