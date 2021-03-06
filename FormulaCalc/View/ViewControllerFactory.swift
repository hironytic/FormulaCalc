//
// ViewControllerFactory.swift
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

public func createViewController(for viewModel: IViewModel) -> UIViewController {
    switch viewModel {
    case let viewModel as IDesignSheetViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.designSheet, DesignSheetViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as IFormulaViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.formula, FormulaViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as IItemViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.item, ItemViewController.self)
        view.viewModel = viewModel
        return viewController
    
    case let viewModel as IItemFormatViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.itemFormat, ItemFormatViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as IItemNameViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.itemName, ItemNameViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as IItemTypeViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.itemType, ItemTypeViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as ISheetViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.sheet, SheetViewController.self)
        view.viewModel = viewModel
        return viewController
        
    case let viewModel as ISheetListViewModel:
        let (viewController, view) = instantiateFromStoryboard(R.Id.sheetList, SheetListViewController.self)
        view.viewModel = viewModel
        return viewController
    
    case let viewModel as IInputOneTextViewModel:
        return createInputOneTextViewController(viewModel: viewModel)
        
    default:
        fatalError()
    }
}

private func instantiateFromStoryboard<View>(_ storyboardName: String, _ type: View.Type) -> (UIViewController, View) {
    let storyboard: UIStoryboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
    let viewController = storyboard.instantiateInitialViewController()!
    return (
        viewController,
        ((viewController as? UINavigationController)?.viewControllers[0] ?? viewController) as! View
    )
}

private func createInputOneTextViewController(viewModel: IInputOneTextViewModel) -> UIViewController {
    let alertController = UIAlertController(title: viewModel.title, message: viewModel.detailMessage, preferredStyle: .alert)
    alertController.addTextField { textField in
        textField.placeholder = viewModel.placeholder
        textField.text = viewModel.initialText
    }
    alertController.addAction(UIAlertAction(title: viewModel.cancelButtonTitle, style: .cancel, handler: { _ in
        alertController.dismiss(animated: true, completion: nil)
        viewModel.onCancel.onNext(())
        viewModel.onDone.onCompleted()
        viewModel.onCancel.onCompleted()
    }))
    alertController.addAction(UIAlertAction(title: viewModel.doneButtonTitle, style: .default, handler: { _ in
        let resultText = alertController.textFields![0].text ?? ""
        alertController.dismiss(animated: true, completion: nil)
        viewModel.onDone.onNext(resultText)
        viewModel.onDone.onCompleted()
        viewModel.onCancel.onCompleted()
    }))    
    return alertController
}
