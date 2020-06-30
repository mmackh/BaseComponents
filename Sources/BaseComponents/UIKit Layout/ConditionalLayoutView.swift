//
//  ConditionalLayoutView.swift
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
    private var conditionalTargetViews: [ConditionalSplitView] = []
    private var boundsCache: CGRect = .zero
    private var splitView: SplitView? = nil
    
    private class ConditionalSplitView: SplitView {
        struct Subview {
            let view: UIView
            let handler: SplitViewHandler
        }
        
        let conditionHandler: (_ traitCollection: UITraitCollection)->Bool
        var targetSubviews: [Subview] = []
        
        init(conditionHandler: @escaping (_ traitCollection: UITraitCollection)->Bool) {
            self.conditionHandler = conditionHandler
            
            super.init(frame: .zero)
        }
        
        override func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat, edgeInsets: UIEdgeInsets) {
            let handler = SplitViewHandler()
            handler.layoutType = layoutType
            handler.staticValue = value
            handler.staticEdgeInsets = edgeInsets
            
            let subview = Subview(view: view, handler: handler)
            targetSubviews.append(subview)
        }
        
        override func addSubview(_ view: UIView, valueHandler: @escaping (CGRect) -> SplitViewLayoutInstruction) {
            let handler = SplitViewHandler()
            handler.valueHandler = valueHandler
            
            let subview = Subview(view: view, handler: handler)
            targetSubviews.append(subview)
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
    
    @available(*, unavailable)
    public override func addSplitView(configurationHandler: (SplitView) -> Void) -> SplitView {
        super.addSplitView(configurationHandler: configurationHandler)
    }
    
    @available(*, unavailable)
    public override func addScrollingView(configurationHandler: (ScrollingView) -> Void) -> ScrollingView {
        super.addScrollingView(configurationHandler: configurationHandler)
    }
    
    public func addSubviews(_ configurationHandler: (_ targetView: SplitView)->Void, conditionHandler: @escaping (_ traitCollection: UITraitCollection) -> Bool) {
        let targetView = ConditionalSplitView(conditionHandler: conditionHandler)
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
        
        if boundsCache.equalTo(bounds) { return }
        boundsCache = bounds
        
        for targetView in conditionalTargetViews {
            for targetSubview in targetView.targetSubviews {
                targetSubview.view.removeFromSuperview()
            }
        }
        
        self.splitView?.removeFromSuperview()
        let splitView = SplitView()
        self.splitView = splitView
        
        for targetView in conditionalTargetViews {
            if targetView.matches(traitCollection) {
                for targetSubview in targetView.targetSubviews {
                    if let valueHandler = targetSubview.handler.valueHandler {
                        splitView.addSubview(targetSubview.view, valueHandler: valueHandler)
                    } else {
                        splitView.addSubview(targetSubview.view, layoutType: targetSubview.handler.layoutType, value: targetSubview.handler.staticValue, edgeInsets: targetSubview.handler.staticEdgeInsets)
                    }
                }
                break
            }
        }
        super.addSubview(splitView)
        splitView.frame = bounds
    }
    
    public func invalidateLayout() {
        boundsCache = .zero
        setNeedsLayout()
        layoutIfNeeded()
    }
}
