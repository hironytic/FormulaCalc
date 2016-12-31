//
// Resource+Id.swift
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

import Foundation

public extension Resource {
    public struct Id {
        private init() { }
        
        /// General cell identifier
        public static let cell = "Cell"
        
        /// Cell identifier for thousand separator
        public static let thousandSeparator = "ThousandSeparator"
        
        // Cell identifier for fraction digits
        public static let fractionDigits = "FractionDigits"
        
        
        /// Name of the storyboard "DesignSheet"
        public static let designSheet = "DesignSheet"

        /// Name of the storyboard "Item"
        public static let item = "Item"
        
        /// Nmae of the storyboard "ItemFormat"
        public static let itemFormat = "ItemFormat"
        
        /// Name of the storyboard "ItemName"
        public static let itemName = "ItemName"

        /// Name of the storyboard "ItemType"
        public static let itemType = "ItemType"
        
        /// Name of the storyboard "Sheet"
        public static let sheet = "Sheet"

        /// Name of the storyboard "SheetList"
        public static let sheetList = "SheetList"
    }
}
