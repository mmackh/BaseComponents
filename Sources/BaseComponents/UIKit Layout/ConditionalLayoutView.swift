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
    @objc func addConditionalLayoutView(configurationHandler: (_ conditionalLayoutView: ConditionalLayoutView) -> Void) -> ConditionalLayoutView {
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
    private var frameCacheMap: Dictionary<NSValue, CGRect> = [:]
    
    public class ConditionalSplitView {
        class Subview {
            let view: UIView
            let handler: SplitViewHandler
            let conditionalSplitView: ConditionalSplitView?
            
            init(view: UIView, handler: SplitViewHandler, conditionalSplitView: ConditionalSplitView? = nil) {
                self.view = view
                self.handler = handler
                self.conditionalSplitView = conditionalSplitView
            }
        }
        
        public var direction: SplitViewDirection = .vertical
        public var preventAnimations: Bool = false
        public var backgroundColor: UIColor? = nil
        
        fileprivate var initialLayout: Bool = true
        private var didLayoutSubviews: (() -> Void)?
        public func didLayoutSubviews(_ willLayoutSubviews: @escaping () -> Void) {
            self.didLayoutSubviews = willLayoutSubviews
        }
        
        var conditionHandler: ((_ traitCollection: UITraitCollection)->Bool)? = nil
        var subviews: [Subview] = []
        
        init(conditionHandler: ((_ traitCollection: UITraitCollection)->Bool)? = nil) {
            self.conditionHandler = conditionHandler
        }
        
        public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat = 0, edgeInsets: UIEdgeInsets = .zero) {
            let handler = SplitViewHandler()
            handler.layoutType = layoutType
            handler.staticValue = value
            handler.staticEdgeInsets = edgeInsets
            
            let subview = Subview(view: view, handler: handler, conditionalSplitView: nil)
            subviews.append(subview)
        }
        
        public func addSubview(_ view: UIView, valueHandler: @escaping (CGRect) -> SplitViewLayoutInstruction) {
            let handler = SplitViewHandler()
            handler.valueHandler = valueHandler
            
            let subview = Subview(view: view, handler: handler, conditionalSplitView: nil)
            subviews.append(subview)
        }
        
        @discardableResult
        public func addSplitView(configurationHandler: (_ splitView: ConditionalSplitView) -> Void, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) -> ConditionalSplitView {
            let conditionalSplitView = ConditionalSplitView()
            unowned let weakConditionalSplitView = conditionalSplitView
            configurationHandler(weakConditionalSplitView)
            
            let handler = SplitViewHandler()
            handler.valueHandler = valueHandler
            let subview = Subview(view: UIView(), handler: handler, conditionalSplitView: conditionalSplitView)
            subviews.append(subview)
            
            return conditionalSplitView
        }
        
        public func addPadding(_ value: CGFloat) {
            addSubview(UIView(), layoutType: .fixed, value: value)
        }
        
        public func addPadding(layoutType: SplitViewLayoutType, value: CGFloat = 0.0) {
            addSubview(UIView(), layoutType: layoutType, value: value)
        }
        
        func matches(_ traitCollection: UITraitCollection) -> Bool {
            if let conditionHandler = conditionHandler {
                return conditionHandler(traitCollection)
            }
            return false
        }
        
        func build(frameCacheMap: Dictionary<NSValue, CGRect>) -> SplitView {
            let splitView = SplitView()
            splitView.direction = direction
            splitView.preventAnimations = preventAnimations
            if backgroundColor != nil {
                splitView.backgroundColor = backgroundColor
            }
            
            for targetSubview in subviews {               
                if let valueHandler = targetSubview.handler.valueHandler {
                    if let conditionalSplitView = targetSubview.conditionalSplitView {
                        splitView.addSubview(conditionalSplitView.build(frameCacheMap: frameCacheMap), valueHandler: valueHandler)
                    } else {
                        targetSubview.view.removeFromSuperview()
                        splitView.addSubview(targetSubview.view, valueHandler: valueHandler)
                    }
                } else {
                    targetSubview.view.removeFromSuperview()
                    splitView.addSubview(targetSubview.view, layoutType: targetSubview.handler.layoutType, value: targetSubview.handler.staticValue, edgeInsets: targetSubview.handler.staticEdgeInsets)
                }
                
                UIView.performWithoutAnimation {
                    let value = NSValue(nonretainedObject: targetSubview.view)
                    if let frameCache = frameCacheMap[value] {
                        targetSubview.view.frame = frameCache
                    }
                }
            }
            
            if let didLayoutSubviews = didLayoutSubviews {
                didLayoutSubviews()
            }
            
            return splitView
        }
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
    
    @available(*, unavailable)
    public override func addConditionalLayoutView(configurationHandler: (ConditionalLayoutView) -> Void) -> ConditionalLayoutView {
        super.addConditionalLayoutView(configurationHandler: configurationHandler)
    }
    
    public func addSubviews(_ configurationHandler: (_ targetView: ConditionalSplitView)->Void, conditionHandler: @escaping (_ traitCollection: UITraitCollection) -> Bool) {
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
            if targetView.initialLayout {
                targetView.initialLayout = false
                
                let splitView = targetView.build(frameCacheMap: frameCacheMap)
                splitView.frame = bounds
                splitView.layoutSubviews()
                for subview in splitView.subviews {
                    let value = NSValue(nonretainedObject: subview)
                    frameCacheMap[value] = self.convert(subview.bounds, from: subview)
                }
            } else {
                for subview in targetView.subviews {
                    if (subview.view.superview == nil) {
                        continue
                    }
                    
                    let value = NSValue(nonretainedObject: subview.view)
                    frameCacheMap[value] = self.convert(subview.view.bounds, from: subview.view)
                }
            }
        }
        
        self.splitView?.removeFromSuperview()
        self.splitView = nil
        
        for targetView in conditionalTargetViews {
            if targetView.matches(traitCollection) {
                let splitView = targetView.build(frameCacheMap: frameCacheMap)
                splitView.frame = bounds
                super.addSubview(splitView)
                self.splitView = splitView
                break
            }
        }
    }
    
    public func invalidateLayout() {
        boundsCache = .zero
        setNeedsLayout()
        layoutIfNeeded()
    }
}
