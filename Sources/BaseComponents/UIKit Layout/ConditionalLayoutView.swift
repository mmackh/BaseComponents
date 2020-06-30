//
//  ScrollingView.swift
//  BaseComponents
//
//  Created by mmackh on 30.06.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public extension UIView {
    @discardableResult
    func addConditionalLayoutView(configurationHandler: (_ conditionalLayoutView: ConditionalLayoutView) -> Void) -> ConditionalLayoutView {
        let conditionalLayoutView = ConditionalLayoutView()
        unowned let weakConditionalLayoutView = conditionalLayoutView
        configurationHandler(weakConditionalLayoutView)
        self.addSubview(conditionalLayoutView)
        return conditionalLayoutView
    }
}

public class ConditionalLayoutView: UIView {
    private var conditionalTargetViews: [TargetView] = []
    
    private class TargetView: UIView {
        let conditionHandler: (_ traitCollection: UITraitCollection)->Bool
        var targetSubviews: [UIView] = []
        
        init(conditionHandler: @escaping (_ traitCollection: UITraitCollection)->Bool) {
            self.conditionHandler = conditionHandler
            
            super.init(frame: .zero)
        }
        
        override func addSubview(_ view: UIView) {
            targetSubviews.append(view)
        }
        
        override func insertSubview(_ view: UIView, at index: Int) {
            targetSubviews.insert(view, at: index)
        }
        
        func matches(_ traitCollection: UITraitCollection) -> Bool {
            return conditionHandler(traitCollection)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
    
    @available(*, unavailable)
    public override func addSubview(_ view: UIView) {
        super.addSubview(view)
    }
    
    public func addSubviews(_ configurationHandler: (_ targetView: UIView)->Void, conditionHandler: @escaping (_ traitCollection: UITraitCollection) -> Bool) {
        let targetView = TargetView(conditionHandler: conditionHandler)
        configurationHandler(targetView)
        self.conditionalTargetViews.append(targetView)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        guard let newSuperview = newSuperview else { return }
        frame = newSuperview.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        for targetView in conditionalTargetViews {
            for targetSubview in targetView.targetSubviews {
                targetSubview.removeFromSuperview()
            }
        }
        
        for targetView in conditionalTargetViews {
            if targetView.matches(traitCollection) {
                for targetSubview in targetView.targetSubviews {
                    super.addSubview(targetSubview)
                }
                break
            }
        }
    }
}
