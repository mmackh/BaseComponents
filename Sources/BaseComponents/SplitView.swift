//
//  PCSplitView.swift
//  BaseComponents
//
//  Created by mmackh on 11.12.18.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public enum SplitViewDirection: Int {
    case horizontal
    case vertical
}

public enum SplitViewLayoutType: Int {
    case automatic
    case equal
    case fixed
    case percentage
}

private class SplitViewHandler {
    var layoutType: SplitViewLayoutType = .fixed
    var valueHandler: ((CGRect) -> SplitViewLayoutInstruction)?
    var staticValue: CGFloat = 0.0
    var staticEdgeInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    func getLayoutInstruction(_ superviewBounds: CGRect) -> SplitViewLayoutInstruction {
        return (valueHandler == nil) ? SplitViewLayoutInstruction(layoutType: layoutType, value: staticValue, edgeInsets: staticEdgeInsets) : valueHandler!(superviewBounds)
    }
}

private struct SizeThatFitsCache {
    let largestSubview: UIView?
    var limitingSize: CGSize
    var forSize: CGSize
    var largestValue: CGFloat
    var additionalPadding: CGFloat
}

public class SplitViewLayoutInstruction {
    var value: CGFloat = 0
    var layoutType: SplitViewLayoutType = .equal
    var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    public convenience init(layoutType: SplitViewLayoutType, value: CGFloat) {
        self.init()
        
        self.value = value
        self.layoutType = layoutType
    }
    
    public convenience init(layoutType: SplitViewLayoutType, value: CGFloat, edgeInsets: UIEdgeInsets) {
        self.init()
        
        self.value = value
        self.edgeInsets = edgeInsets
        self.layoutType = layoutType
    }
}

public class SplitView: UIView {
    public static let ExcludeLayoutTag = 102
    public static let onePixelHeight: CGFloat = 1 / UIScreen.main.scale
    
    public var direction: SplitViewDirection = .vertical
    
    public var subviewPadding: CGFloat = 0.0
    public var preventAnimations: Bool = false
    public var clipsAllSubviews: Bool = false
    
    private var willLayoutSubviews: (() -> Void)?
    public func willLayoutSubviews(_ willLayoutSubviews: @escaping () -> Void) {
        self.willLayoutSubviews = willLayoutSubviews
    }
    
    private var didLayoutSubviews: (() -> Void)?
    public func didLayoutSubviews(_ didLayoutSubviews: @escaping () -> Void) {
        self.didLayoutSubviews = didLayoutSubviews
    }
    
    private var handlerContainer: Dictionary<UIView, SplitViewHandler> = Dictionary()
    
    private var boundsCache: CGRect?
    private var observingSuperviewSafeAreaInsets = false
    
    private var sizeThatFitsCache: SizeThatFitsCache?
    
    
    public var layoutPass: Bool = false
    
    @discardableResult
    public convenience init(superview: UIView, configurationHandler: (_ splitView: SplitView) -> Void) {
        self.init()
        
        if (superview.isKind(of: SplitView.self))
        {
            print("use 'superSplitView' and valueHandler to add childSplitViews, this will most likely crash your app otherwise - no way to deterministically lay out this SplitView instance")
        }
        
        configurationHandler(self)
        
        superview.addSubview(self)
        snapToSuperview()
    }
    
    
    @discardableResult
    public convenience init(superSplitView: SplitView, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction, configurationHandler: (_ splitView: SplitView) -> Void) {
        self.init()
        
        configurationHandler(self)
        
        superSplitView.addSubview(self, valueHandler: valueHandler)
    }
    
    @available(*, unavailable)
    public override func addSubview(_ view: UIView) {
        super.addSubview(view)
    }
    
    public static func suggestedSuperviewInsets() -> UIEdgeInsets {
        let defaultInset: CGFloat = 15.0
        var suggestedInsets = UIEdgeInsets(top: defaultInset, left: defaultInset, bottom: defaultInset, right: defaultInset)
        if #available(iOS 11.0, *) {
            if let keyWindow = UIApplication.shared.keyWindow {
                suggestedInsets = keyWindow.safeAreaInsets
            }
        }
        return suggestedInsets
    }
    
    public func addSubview(_ view: UIView, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) {
        let handler = SplitViewHandler()
        handler.valueHandler = valueHandler
        
        handlerContainer[view] = handler
        
        (self as UIView).addSubview(view)
    }
    
    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType) {
        addSubview(view, layoutType: layoutType, value: 0, edgeInsets: UIEdgeInsets.zero)
    }
    
    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, edgeInsets: UIEdgeInsets) {
        addSubview(view, layoutType: layoutType, value: 0, edgeInsets: edgeInsets)
    }
    
    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat) {
        addSubview(view, layoutType: layoutType, value: value, edgeInsets: UIEdgeInsets.zero)
    }
    
    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat, edgeInsets: UIEdgeInsets) {
        let handler = SplitViewHandler()
        handler.staticValue = value
        handler.staticEdgeInsets = edgeInsets
        handler.layoutType = layoutType
        
        handlerContainer[view] = handler
        
        (self as UIView).addSubview(view)
    }
    
    private func snapToSuperview() {
        if superview != nil {
            frame = superview!.frame
        }
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    /// Force layout of subviews, can be animated inside an animation block
    public func invalidateLayout() {
        boundsCache = nil
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

/// UIView functions that have to be overwritten
extension SplitView {
    public override func willRemoveSubview(_ subview: UIView) {
        handlerContainer.removeValue(forKey: subview)
    }
    
    public override func layoutIfNeeded() {
        if preventAnimations {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            super.layoutIfNeeded()
            CATransaction.commit()
            
            return
        }
        
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        willLayoutSubviews?()
        
        if preventAnimations {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        if boundsCache?.equalTo(bounds) ?? false || bounds.equalTo(.zero) {
            if preventAnimations {
                CATransaction.commit()
            }
            return
        }
        boundsCache = bounds
        
        if subviews.count == 0 {
            return
        }
        
        let horizontalLayout = (direction == .horizontal)
        
        let padding = subviewPadding
        
        var offsetTracker: CGFloat = 0.0
        var fixedValuesSum: CGFloat = 0.0
        var percentageLossSum: CGFloat = 0.0
        var numberOfLayoutTypeEqualSubviews: CGFloat = 0.0
        
        for subview in subviews {
            let layoutHandler = handlerContainer[subview]!
            let instruction = layoutHandler.getLayoutInstruction(bounds)
            
            if instruction.layoutType == .percentage {
                percentageLossSum += (instruction.value / 100)
                continue
            }
            
            if instruction.layoutType == .equal {
                numberOfLayoutTypeEqualSubviews += 1
                continue
            }
            
            var fixedValueFloat = instruction.value
            
            if layoutHandler.layoutType == .automatic {
                
                var additionalPadding: CGFloat = 0.0
                if subview is UIButton {
                    let button = subview as! UIButton
                    additionalPadding += horizontalLayout ? (button.titleEdgeInsets.left + button.titleEdgeInsets.right) : (button.titleEdgeInsets.bottom + button.titleEdgeInsets.top)
                }
                
                let edgeInsets = instruction.edgeInsets
                additionalPadding += horizontalLayout ? (edgeInsets.left + edgeInsets.right + subviewPadding * 2) : (edgeInsets.top + edgeInsets.bottom + subviewPadding * 2)
                
                let max = CGFloat.greatestFiniteMagnitude
                let subviewDimensions = subview.sizeThatFits(CGSize(width: bounds.size.width - (edgeInsets.left + edgeInsets.right + subviewPadding*2), height: horizontalLayout ? bounds.size.height - (edgeInsets.top + edgeInsets.bottom + subviewPadding*2) : max))
                fixedValueFloat = horizontalLayout ? subviewDimensions.width : subviewDimensions.height
                fixedValueFloat += additionalPadding
                layoutHandler.staticValue = fixedValueFloat
            }
            
            if fixedValueFloat < 1.0 && fixedValueFloat > 0.0 {
                fixedValueFloat = SplitView.onePixelHeight
                instruction.value = fixedValueFloat
            }
            
            fixedValuesSum += fixedValueFloat
        }
        
        let width = bounds.size.width - (horizontalLayout ? fixedValuesSum : 0.0)
        let height = bounds.size.height - (horizontalLayout ? 0.0 : fixedValuesSum)
        
        for childView in subviews {
            let layoutHandler = handlerContainer[childView]!
            let instruction = layoutHandler.getLayoutInstruction(bounds)
            
            let edgeInsets = instruction.edgeInsets
            
            var ratio: CGFloat = 1
            var layoutValue: CGFloat = horizontalLayout ? width : height
            
            if instruction.layoutType == .percentage {
                ratio = instruction.value / 100
            }
            
            if instruction.layoutType == .equal {
                ratio = (1.0 - percentageLossSum) / numberOfLayoutTypeEqualSubviews
            }
            
            if instruction.layoutType == .fixed {
                layoutValue = instruction.value
            }
            
            if instruction.layoutType == .automatic {
                layoutValue = layoutHandler.staticValue
            }
            
            let childFrame = CGRect(x: horizontalLayout ? offsetTracker : 0.0, y: horizontalLayout ? 0.0 : offsetTracker, width: horizontalLayout ? layoutValue * ratio : width, height: horizontalLayout ? height : layoutValue * ratio)
            
            offsetTracker += horizontalLayout ? childFrame.size.width : childFrame.size.height
            
            var targetFrame = childFrame.insetBy(dx: padding, dy: padding)
            targetFrame = targetFrame.inset(by: edgeInsets)
            childView.frame = targetFrame
            
            if (clipsAllSubviews) {
                childView.clipsToBounds = true
            }
        }
        
        if preventAnimations {
            CATransaction.commit()
        }
        
        didLayoutSubviews?()
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        if !layoutPass {
            return super.sizeThatFits(size)
        }
        
        if sizeThatFitsCache == nil {
            layoutSubviews()
            
            var largestValue: CGFloat = 0
            var largestSubview: UIView?
            var largestLimitingSize: CGSize = .zero
            
            for subview in subviews {
                if (!subview.isKind(of: UILabel.self) && !subview.isKind(of: PerformLabel.self) ) {
                    continue
                }
                let limitingSize: CGSize = .init(width: direction == .horizontal ? subview.frame.size.width : .infinity, height: direction == .horizontal ? .infinity : subview.bounds.size.height)
                let size = subview.sizeThatFits(limitingSize)
                let relevantValue = direction == .vertical ? size.height : size.width
                if (largestValue < relevantValue) {
                    largestValue = relevantValue
                    largestSubview = subview
                    largestLimitingSize = limitingSize
                }
            }
            
            let edgeInstets = handlerContainer[largestSubview!]!.getLayoutInstruction(bounds).edgeInsets
            var additionalPadding: CGFloat = 0
            if direction == .vertical {
                additionalPadding += (edgeInstets.top + edgeInstets.bottom)
            } else {
                additionalPadding += (edgeInstets.left + edgeInstets.right)
            }
            sizeThatFitsCache = SizeThatFitsCache(largestSubview: largestSubview, limitingSize: largestLimitingSize, forSize: size, largestValue: largestValue, additionalPadding: additionalPadding)
        }
        
        if sizeThatFitsCache?.largestValue ?? 0 > (0 as CGFloat) {
            let largestValue = sizeThatFitsCache!.largestSubview!.sizeThatFits(sizeThatFitsCache!.limitingSize).height + sizeThatFitsCache!.additionalPadding
            return .init(width: 0, height: largestValue)
        }
        
        return .init(width: 300, height: 300)
    }
}

/// Convenience functions to add margins around a specific root splitView

public enum SplitViewPaddingDirection: Int {
    case top
    case left
    case bottom
    case right
}

public extension SplitView {
    func insertSafeAreaInsetsPadding(form parentView: UIView, paddingDirection: SplitViewPaddingDirection) {
        
        observingSuperviewSafeAreaInsets = true
        
        unowned let weakParentView = parentView
        let padding = UIView()
        self.addSubview(padding) { (parentRect) -> SplitViewLayoutInstruction in
            var insetValue: CGFloat = 0.0;
            if #available(iOS 11.0, *) {
                let insets = weakParentView.safeAreaInsets
                switch paddingDirection {
                case .top:
                    insetValue = insets.top
                case .left:
                    insetValue = insets.left
                case .bottom:
                    insetValue = insets.bottom
                case .right:
                    insetValue = insets.right
                }
            }
            return SplitViewLayoutInstruction(layoutType: .fixed, value: insetValue)
        }
    }
    
    override func safeAreaInsetsDidChange() {
        if observingSuperviewSafeAreaInsets {
            invalidateLayout()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 10.0, *) {
            if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
                DispatchQueue.main.async {
                    self.invalidateLayout()
                }
            }
        }
    }
}
