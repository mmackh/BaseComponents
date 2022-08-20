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

#if os(iOS)

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

public extension UIView {
    @discardableResult
    @objc func addSplitView(configurationHandler: (_ splitView: SplitView) -> Void) -> SplitView {
        return SplitView(superview: self, configurationHandler: configurationHandler)
    }
}

public extension SplitView {
    @available(*, unavailable)
    override func addSplitView(configurationHandler: (_ splitView: SplitView) -> Void) -> SplitView {
        return super.addSplitView(configurationHandler: configurationHandler)
    }
    
    @discardableResult
    func addSplitView(configurationHandler: (_ splitView: SplitView) -> Void, layoutType: SplitViewLayoutType, value: CGFloat = 0, edgeInsets: UIEdgeInsets = .zero) -> SplitView {
        return self.addSplitView(configurationHandler: configurationHandler) { (parentRect) -> SplitViewLayoutInstruction in
            return .init(layoutType: layoutType, value: value, edgeInsets: edgeInsets)
        }
    }
    
    @discardableResult
    func addSplitView(configurationHandler: (_ splitView: SplitView) -> Void, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) -> SplitView {
        return SplitView(superSplitView: self, configurationHandler: configurationHandler, valueHandler: valueHandler)
    }
    
    @available(*, unavailable)
    override func addConditionalLayoutView(configurationHandler: (ConditionalLayoutView) -> Void) -> ConditionalLayoutView {
        return super.addConditionalLayoutView(configurationHandler: configurationHandler)
    }
    
    @discardableResult
    func addConditionalLayoutView(configurationHandler: (ConditionalLayoutView) -> Void, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) -> ConditionalLayoutView  {
        let conditionalLayoutView = ConditionalLayoutView()
        unowned let weakConditionalLayoutView = conditionalLayoutView
        configurationHandler(weakConditionalLayoutView)
        addSubview(conditionalLayoutView, valueHandler: valueHandler)
        return conditionalLayoutView
    }
    
    @available(*, unavailable)
    override func addScrollingView(configurationHandler: (ScrollingView) -> Void) -> ScrollingView {
        return super.addScrollingView(configurationHandler: configurationHandler)
    }
    
    @discardableResult
    func addScrollingView(configurationHandler: (ScrollingView) -> Void, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) -> ScrollingView  {
        let scrollingView = ScrollingView()
        unowned let weakScrollingView = scrollingView
        configurationHandler(weakScrollingView)
        addSubview(scrollingView, valueHandler: valueHandler)
        return scrollingView
    }
}

public class SplitViewHandler {
    var layoutType: SplitViewLayoutType = .fixed
    var valueHandler: ((CGRect) -> SplitViewLayoutInstruction)?
    var staticValue: CGFloat = 0.0
    var staticEdgeInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    func getLayoutInstruction(_ superviewBounds: CGRect) -> SplitViewLayoutInstruction {
        if let valueHandler = valueHandler {
            return valueHandler(superviewBounds)
        }
        return SplitViewLayoutInstruction(layoutType: layoutType, value: staticValue, edgeInsets: staticEdgeInsets)
    }
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

open class SplitView: UIView {
    public static let ExcludeLayoutTag = 102
    public static let onePixelHeight: CGFloat = .onePixel
    
    public var direction: SplitViewDirection = .vertical
    public var directionHandler: (()->(SplitViewDirection))?
    
    public var subviewPadding: CGFloat = 0.0
    public var preventAnimations: Bool = false
    public var clipsAllSubviews: Bool = false
    
    private var couldLayoutSubviews: (() -> Void)?
    public func couldLayoutSubviews(_ couldLayoutSubviews: @escaping () -> Void) {
        self.couldLayoutSubviews = couldLayoutSubviews
    }
    
    private var willLayoutSubviews: (() -> Void)?
    public func willLayoutSubviews(_ willLayoutSubviews: @escaping () -> Void) {
        self.willLayoutSubviews = willLayoutSubviews
    }
    
    private var didLayoutSubviews: (() -> Void)?
    public func didLayoutSubviews(_ didLayoutSubviews: @escaping () -> Void) {
        self.didLayoutSubviews = didLayoutSubviews
    }
    
    private var didChangeTraitCollection: ((_ traitCollection: UITraitCollection) -> Void)?
    public func didChangeTraitCollection(_ didChangeTraitCollection: @escaping (_ traitCollection: UITraitCollection) -> Void) {
        self.didChangeTraitCollection = didChangeTraitCollection
    }
    
    private var handlerContainer: Dictionary<AnyHashable, SplitViewHandler> = Dictionary()
    
    private var boundsCache: CGRect?
    public var observingSuperviewSafeAreaInsets = false
    public var observingSuperviewLayoutMargins = false
    
    @discardableResult
    fileprivate convenience init(superview: UIView, configurationHandler: (_ splitView: SplitView) -> Void) {
        self.init()
        
        if (superview.isKind(of: SplitView.self))
        {
            print("use 'superSplitView' and valueHandler to add childSplitViews, this will most likely crash your app otherwise - no way to deterministically lay out this SplitView instance")
        }
        
        unowned let weakSelf = self
        configurationHandler(weakSelf)
        
        superview.addSubview(self)
        snapToSuperview()
    }
    
    
    @discardableResult
    fileprivate convenience init(superSplitView: SplitView, configurationHandler: (_ splitView: SplitView) -> Void, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) {
        self.init()
        
        unowned let weakSelf = self
        configurationHandler(weakSelf)
        
        superSplitView.addSubview(self, valueHandler: valueHandler)
    }
    
    @available(*, unavailable)
    public override func addSubview(_ view: UIView) {
        super.addSubview(view)
    }
    
    @available(iOSApplicationExtension, unavailable)
    public static func suggestedSuperviewInsets() -> UIEdgeInsets {
        let defaultInset: CGFloat = 15.0
        var suggestedInsets = UIEdgeInsets(top: defaultInset, left: defaultInset, bottom: defaultInset, right: defaultInset)
        if #available(iOS 13.0, *) {
            if let keyWindow = UIApplication.shared.windows.first {
                suggestedInsets = keyWindow.safeAreaInsets
            }
        } else {
            if let keyWindow = UIApplication.shared.keyWindow {
                suggestedInsets = keyWindow.safeAreaInsets
            }
        }
        return suggestedInsets
    }
    
    public func addSubview(_ view: UIView, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction) {
        let handler = SplitViewHandler()
        handler.layoutType = valueHandler(.zero).layoutType
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
    
    @discardableResult
    public func addPadding(_ value: CGFloat) -> UIView {
        addPadding(layoutType: .fixed, value: value)
    }
    
    @discardableResult
    public func addPadding(layoutType: SplitViewLayoutType, value: CGFloat = 0.0) -> UIView {
        let padding = UIView()
        addSubview(padding.userInteractionEnabled(false), layoutType: layoutType, value: value)
        return padding
    }
    
    private func snapToSuperview() {
        if let superview = superview {
            frame = superview.bounds
        }
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    /// Force layout of subviews, can be animated inside an animation block
    public func invalidateLayout() {
        boundsCache = nil
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func layoutInstruction(for view: UIView) -> SplitViewLayoutInstruction {
        return handlerContainer[view]!.getLayoutInstruction(bounds)
    }
    
    deinit {
        handlerContainer.removeAll()
    }
}

/// UIView functions that have to be overwritten
extension SplitView {
    open class InternalLayoutCalculation {
        public var fixedValuesSum: CGFloat = 0.0
        public var percentageLossSum: CGFloat = 0.0
        public var numberOfLayoutTypeEqualSubviews: CGFloat = 0.0
        
        public static func calculate(for splitView: SplitView) -> InternalLayoutCalculation {
            let layoutCalculation = InternalLayoutCalculation()
            let horizontalLayout = (splitView.direction == .horizontal)
            let padding = splitView.subviewPadding
            let bounds: CGRect = splitView.bounds
            
            for subview in splitView.subviews {
                let layoutHandler = splitView.handlerContainer[subview]!
                let instruction = layoutHandler.getLayoutInstruction(bounds)
                
                if instruction.layoutType == .percentage {
                    layoutCalculation.percentageLossSum += (instruction.value / 100)
                    continue
                }
                
                if instruction.layoutType == .equal {
                    layoutCalculation.numberOfLayoutTypeEqualSubviews += 1
                    continue
                }
                
                var fixedValueFloat = instruction.value
                if instruction.layoutType == .automatic {
                    var additionalPadding: CGFloat = 0.0
                    if let button = subview as? UIButton {
                        additionalPadding += horizontalLayout ? (button.titleEdgeInsets.left + button.titleEdgeInsets.right) : (button.titleEdgeInsets.bottom + button.titleEdgeInsets.top)
                    }
                    
                    let edgeInsets = instruction.edgeInsets
                    additionalPadding += horizontalLayout ? (edgeInsets.left + edgeInsets.right + padding * 2) : (edgeInsets.top + edgeInsets.bottom + padding * 2)
                    
                    if let scrollingView = subview as? ScrollingView {
                        scrollingView.frame = .init(origin: .zero, size: CGSize(width: bounds.size.width - (edgeInsets.left + edgeInsets.right + padding*2), height: horizontalLayout ? bounds.size.height - (edgeInsets.top + edgeInsets.bottom + padding*2) : 100))
                    }
                    
                    let max = CGFloat.greatestFiniteMagnitude
                    let availableSize = CGSize(width: bounds.size.width - (edgeInsets.left + edgeInsets.right + padding*2), height: horizontalLayout ? bounds.size.height - (edgeInsets.top + edgeInsets.bottom + padding*2) : max)
                    var subviewDimensions: CGSize
                    if let stackView = subview as? UIStackView {
                        subviewDimensions = stackView.systemLayoutSizeFitting(availableSize)
                    } else {
                        subviewDimensions = subview.sizeThatFits(availableSize)
                    }
                    
                    fixedValueFloat = horizontalLayout ? subviewDimensions.width : subviewDimensions.height
                    fixedValueFloat += additionalPadding
                    layoutHandler.staticValue = fixedValueFloat
                }
                
                if fixedValueFloat < 1.0 && fixedValueFloat > 0.0 {
                    fixedValueFloat = .onePixel
                    instruction.value = fixedValueFloat
                }
                
                layoutCalculation.fixedValuesSum += fixedValueFloat
            }
            
            return layoutCalculation
        }
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
        couldLayoutSubviews?()
        
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
        
        willLayoutSubviews?()
        
        if let directionHandler = directionHandler {
            direction = directionHandler()
        }
        let horizontalLayout = direction == .horizontal
        let layoutCalculation = InternalLayoutCalculation.calculate(for: self)
        let padding: CGFloat = subviewPadding
        var offsetTracker: CGFloat = 0.0
        
        let width = bounds.size.width - (horizontalLayout ? layoutCalculation.fixedValuesSum : 0.0)
        let height = bounds.size.height - (horizontalLayout ? 0.0 : layoutCalculation.fixedValuesSum)
        
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
                ratio = (1.0 - layoutCalculation.percentageLossSum) / layoutCalculation.numberOfLayoutTypeEqualSubviews
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
            if childView.layer.borderWidth > 0 {
                childView.frame = targetFrame.integral
            } else {
                childView.frame = targetFrame
            }
            
            if (clipsAllSubviews) {
                childView.clipsToBounds = true
            }
        }
        
        if preventAnimations {
            CATransaction.commit()
        }
        
        didLayoutSubviews?()
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self  && gestureRecognizers?.count ?? 0 == 0 {
            return nil
        }
        return hitView
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
    @discardableResult
    func insertSafeAreaInsetsPadding(form parentView: UIView, paddingDirection: SplitViewPaddingDirection, adjustment: CGFloat = 0) -> UIView {
        observingSuperviewSafeAreaInsets = true
        
        unowned let weakParentView = parentView
        let padding = UIView()
        self.addSubview(padding) { (parentRect) -> SplitViewLayoutInstruction in
            var insetValue: CGFloat = 0.0
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
            return SplitViewLayoutInstruction(layoutType: .fixed, value: insetValue + adjustment)
        }
        return padding
    }
    
    override func safeAreaInsetsDidChange() {
        if observingSuperviewSafeAreaInsets {
            invalidateLayout()
        }
    }
    
    @discardableResult
    func insertLayoutMarginsPadding(form parentView: UIView, paddingDirection: SplitViewPaddingDirection, adjustment: CGFloat = 0) -> UIView {
        observingSuperviewLayoutMargins = true
        
        unowned let weakParentView = parentView
        let padding = UIView()
        self.addSubview(padding) { (parentRect) -> SplitViewLayoutInstruction in
            var insetValue: CGFloat = 0.0
            if #available(iOS 11.0, *) {
                let insets = weakParentView.layoutMargins
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
            return SplitViewLayoutInstruction(layoutType: .fixed, value: insetValue + adjustment)
        }
        return padding
    }
    
    override func layoutMarginsDidChange() {
        if observingSuperviewLayoutMargins {
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
        
        self.didChangeTraitCollection?(traitCollection)
    }
}

public extension SplitView {
    /// effective only in vertical direction
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layoutCalculation: InternalLayoutCalculation = InternalLayoutCalculation.calculate(for: self)
        return CGSize(width: size.width, height: layoutCalculation.fixedValuesSum)
    }
}

#endif
