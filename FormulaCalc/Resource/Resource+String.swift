//
// Resource+String.swift
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

public extension Resource {
    public struct String {
        private init() { }
        
        public static let ok = "FormulaCalc.ok"
        public static let cancel = "FormulaCalc.cancel"
        public static let newSheetTitle = "FormulaCalc.newSheetTitle"
        public static let newSheetPlaceholder = "FormulaCalc.newSheetPlaceholder"
        public static let newSheetDone = "FormulaCalc.newSheetDone"
        public static let newItemNameFormat = "FormulaCalc.newItemNameFormat"
        public static let sheetItemTypeNumeric = "FormulaCalc.sheetItemTypeNumeric"
        public static let sheetItemTypeString = "FormulaCalc.sheetItemTypeString"
        public static let sheetItemTypeFormula = "FormulaCalc.sheetItemTypeFormula"
        public static let thousandSeparatorOn = "FormulaCalc.thousandSeparatorOn"
        public static let fractionDigitsAuto = "FormulaCalc.fractionDigitsAuto"
        public static let fractionDigitsFormat = "FormulaCalc.fractionDigitsFormat"
    }
}
