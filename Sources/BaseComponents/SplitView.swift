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
    var valueHandler: ((CGRect) -> SplitViewLayoutInstruction)??
    var staticValue: CGFloat = 0.0
    var staticEdgeInsets: UIEdgeInsets = UIEdgeInsets.zero

    func getLayoutInstruction(_ superviewBounds: CGRect) -> SplitViewLayoutInstruction {
        return (valueHandler == nil) ? SplitViewLayoutInstruction(value: staticValue, layoutType: layoutType, edgeInsets: staticEdgeInsets) : valueHandler!!(superviewBounds)
    }
}

private class SplitViewHandlerContainer {
    private var valueHandlers: Array<SplitViewHandler> = []

    var equalSubviewsCount: CGFloat = 0
    var percentageLeftForEqualSubviews: CGFloat = 1.0

    var estimatedFixedHeight: CGFloat = 0.0

    var viewForHandlerDictionary: Dictionary<UIView, SplitViewHandler> = [:]

    func hasHandlers() -> Bool {
        return valueHandlers.count > 0
    }

    func addValueHandler(_ valueHandler: SplitViewHandler, _ view: UIView) {
        valueHandlers.append(valueHandler)
        viewForHandlerDictionary[view] = valueHandler
    }

    func removeValueHandlerForView(_ view: UIView) {
        let valueHandler = viewForHandlerDictionary[view]

        if let idx = valueHandlers.firstIndex(where: { $0 === valueHandler }) {
            valueHandlers.remove(at: idx)
        }

        viewForHandlerDictionary.removeValue(forKey: view)
    }

    func layoutInstruction(view: UIView) -> String {
        var layoutInstructions: Array<String> = []

        var layoutInstructionObjects: Array<SplitViewLayoutInstruction> = []

        let bounds = view.bounds

        estimatedFixedHeight = 0.0
        equalSubviewsCount = 0
        percentageLeftForEqualSubviews = 1.0

        for handler in valueHandlers {
            let layoutInstruction = handler.getLayoutInstruction(bounds)
            layoutInstructionObjects.append(layoutInstruction)

            if layoutInstruction.layoutType == .equal {
                equalSubviewsCount += 1
            }

            if layoutInstruction.layoutType == .percentage {
                percentageLeftForEqualSubviews -= layoutInstruction.value / 100
            }
        }

        for layoutInstruction in layoutInstructionObjects {
            var value = layoutInstruction.value

            var layoutInstructionString = ""

            if layoutInstruction.layoutType == .automatic {
                layoutInstructionString = "0*-2"
            }
            if layoutInstruction.layoutType == .percentage {
                value /= 100
                layoutInstructionString = String(format: "%f*-1", value)
            }
            if layoutInstruction.layoutType == .fixed {
                estimatedFixedHeight += value
                layoutInstructionString = String(format: "0*%f", value)
            }
            if layoutInstruction.layoutType == .equal {
                value = percentageLeftForEqualSubviews / equalSubviewsCount
                layoutInstructionString = String(format: "%f*-1", value)
            }

            layoutInstructionString = NSCoder.string(for: layoutInstruction.edgeInsets).replacingOccurrences(of: ",", with: ";") + "|" + layoutInstructionString
            layoutInstructions.append(layoutInstructionString)
        }
        return layoutInstructions.joined(separator: ",")
    }
}

public class SplitViewLayoutInstruction {
    var value: CGFloat = 0
    var layoutType: SplitViewLayoutType = .equal
    var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero

    public convenience init(value: CGFloat, layoutType: SplitViewLayoutType) {
        self.init()

        self.value = value
        self.layoutType = layoutType
    }

    public convenience init(value: CGFloat, layoutType: SplitViewLayoutType, edgeInsets: UIEdgeInsets) {
        self.init()

        self.value = value
        self.edgeInsets = edgeInsets
        self.layoutType = layoutType
    }
}

public class SplitView: UIView {
    public static let ClipSubivewTag = 101
    public static let ExcludeLayoutTag = 102

    public var direction: SplitViewDirection = .horizontal

    public var subviewPadding: CGFloat = 0.0
    public var preventAnimations: Bool = false

    public var willLayoutSubviews: (() -> Void)?
    public var didLayoutSubviews: (() -> Void)?

    private var handlerContainer: SplitViewHandlerContainer = SplitViewHandlerContainer()

    private var subviewRatios: Array<CGFloat> = []
    private var subviewFixedValues: Array<CGFloat> = []
    private var subviewEdgeInsets: Array<UIEdgeInsets> = []

    private var originalSubviews: Array<UIView> = []
    private var cachedSubviewLayout: String = ""

    private var boundsCache: CGRect = CGRect()
    private var layoutParsed: Bool = false

    public static let onePixelHeight: CGFloat = 1 / UIScreen.main.scale

    @discardableResult
    public convenience init(superview: UIView, configurationHandler: (_ splitView: SplitView) -> Void) {
        self.init()

        configurationHandler(self)
        
        superview.addSubview(self)
        snapToSuperview()
    }
    

    @discardableResult
    public convenience init(superview: SplitView, valueHandler: @escaping (_ superviewBounds: CGRect) -> SplitViewLayoutInstruction, configurationHandler: (_ splitView: SplitView) -> Void) {
        self.init()

        configurationHandler(self)
        
        superview.addSubview(self, valueHandler: valueHandler)
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

        handlerContainer.addValueHandler(handler, view)

        addSubview(view)
    }

    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType) {
        addSubview(view, layoutType: layoutType, value: 0, edgeInsets: UIEdgeInsets.zero)
    }

    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat) {
        addSubview(view, layoutType: layoutType, value: value, edgeInsets: UIEdgeInsets.zero)
    }

    public func addSubview(_ view: UIView, layoutType: SplitViewLayoutType, value: CGFloat, edgeInsets: UIEdgeInsets) {
        let handler = SplitViewHandler()
        handler.staticValue = value
        handler.staticEdgeInsets = edgeInsets
        handler.layoutType = layoutType

        handlerContainer.addValueHandler(handler, view)

        addSubview(view)
    }

    private func snapToSuperview() {
        if superview != nil {
            frame = superview!.frame
        }
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    /// Force layout of subviews, can be animated inside an animation block
    public func invalidateLayout() {
        layoutParsed = false
        originalSubviews = []

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func evaluateLayoutValueHandlers() {
        let instruction = handlerContainer.layoutInstruction(view: self)

        if cachedSubviewLayout != instruction {
            layoutParsed = false
        } else {
            return
        }

        cachedSubviewLayout = instruction

        var subviewRatiosMutable: Array<CGFloat> = Array()
        var subviewFixedValuesMutable: Array<CGFloat> = Array()
        var subviewEdgeInsetsMutable: Array<UIEdgeInsets> = Array()

        for subInstruction in cachedSubviewLayout.components(separatedBy: ",") {
            let subInstructionSplit: Array<String> = subInstruction.components(separatedBy: "*")

            let subSubValueString = subInstructionSplit.first ?? ""
            let subSubInstructionSplit = subSubValueString.components(separatedBy: "|")

            var edgeInsetsValue = UIEdgeInsets.zero
            if subSubInstructionSplit.count > 1 {
                edgeInsetsValue = NSCoder.uiEdgeInsets(for: subSubInstructionSplit.first?.replacingOccurrences(of: ";", with: ",") ?? "")
            }
            subviewEdgeInsetsMutable.append(edgeInsetsValue)

            let ratioValueString = subSubInstructionSplit.last ?? ""
            let ratioValue: CGFloat = CGFloat((ratioValueString as NSString).floatValue)
            subviewRatiosMutable.append(ratioValue)

            let fixedValueString: String = subInstructionSplit.count > 1 ? subInstructionSplit.last! : "-1"
            let fixedValue = CGFloat((fixedValueString as NSString).floatValue)

            subviewFixedValuesMutable.append(fixedValue)
        }

        subviewRatios = subviewRatiosMutable
        subviewFixedValues = subviewFixedValuesMutable
        subviewEdgeInsets = subviewEdgeInsetsMutable
    }
}

/// UIView functions that have to be overwritten
extension SplitView {
    public override func willRemoveSubview(_ subview: UIView) {
        handlerContainer.removeValueHandlerForView(subview)
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

        super.layoutSubviews()

        if handlerContainer.hasHandlers() {
            evaluateLayoutValueHandlers()
        }

        if boundsCache.equalTo(bounds) && layoutParsed {
            if (preventAnimations) {
                CATransaction.commit()
            }
            return
        }

        boundsCache = bounds
        layoutParsed = true

        if originalSubviews.count == 0 || originalSubviews.count != subviews.count {
            originalSubviews = subviews
        }

        var subviewsMutable: Array<UIView> = []

        for subview in originalSubviews {
            if subview.tag == SplitView.ExcludeLayoutTag {
                continue
            }

            subviewsMutable.append(subview)
        }

        if subviewRatios.count == 0 {
            return
        }

        let horizontalLayout = (direction == .horizontal)

        var fixedValuesMutable = subviewFixedValues
        let ratios = subviewRatios
        let padding = subviewPadding

        var counter = 0
        var offsetTracker: CGFloat = 0.0

        var ratioTargetCount = 0
        var ratioLossIndex = 0
        var ratioLossValue: CGFloat = 0.0

        var fixedValuesSum: CGFloat = 0.0

        for fixedValue in fixedValuesMutable {
            var fixedValueFloat = fixedValue

            let ratio = ratios[ratioLossIndex]
            ratioLossIndex += 1

            ratioTargetCount += 1
            if fixedValueFloat == -1 {
                continue
            }
            ratioTargetCount -= 1

            // Automatic label loss calculation
            if fixedValueFloat < -1.0 {
                let idx = ratioLossIndex - 1
                let subview: Any = subviewsMutable[idx]

                var additionalPadding: CGFloat = 0.0
                if subview is UIButton {
                    let button = subview as! UIButton
                    additionalPadding += horizontalLayout ? (button.titleEdgeInsets.left + button.titleEdgeInsets.right) : (button.titleEdgeInsets.bottom + button.titleEdgeInsets.top)
                }

                let label = subview as! UIView
                let max = CGFloat.greatestFiniteMagnitude
                let labelDimensions = label.sizeThatFits(CGSize(width: horizontalLayout ? max : bounds.size.width, height: horizontalLayout ? bounds.size.height : max))
                fixedValueFloat = horizontalLayout ? labelDimensions.width : labelDimensions.height
                fixedValueFloat += additionalPadding
                fixedValuesMutable[idx] = fixedValueFloat
            }

            if fixedValueFloat < 1.0 && fixedValueFloat > 0.0 {
                fixedValueFloat = SplitView.onePixelHeight
            }

            fixedValuesSum += fixedValueFloat
            ratioLossValue += ratio
        }

        let width = bounds.size.width - (horizontalLayout ? fixedValuesSum : 0.0)
        let height = bounds.size.height - (horizontalLayout ? 0.0 : fixedValuesSum)

        for childView in subviewsMutable {
            let edgeInsets = subviewEdgeInsets[counter]

            let ratio: CGFloat = ratios[counter] + (ratioLossValue > 0 ? (ratioLossValue / CGFloat(ratioTargetCount)) : 0.0)
            var fixedValue: CGFloat = -1

            if fixedValuesMutable.count > 0 {
                fixedValue = fixedValuesMutable[counter]
            }

            if fixedValue < 1.0 && fixedValue > 0.0 {
                fixedValue = SplitView.onePixelHeight
            }

            var childFrame = CGRect(x: horizontalLayout ? offsetTracker : 0.0, y: horizontalLayout ? 0.0 : offsetTracker, width: horizontalLayout ? width * ratio : width, height: horizontalLayout ? height : height * ratio)

            if fixedValue > -1 && horizontalLayout {
                childFrame.size.width = fixedValue
            }

            if fixedValue > -1 && !horizontalLayout {
                childFrame.size.height = fixedValue
            }

            offsetTracker += horizontalLayout ? childFrame.size.width : childFrame.size.height

            var targetFrame = childFrame.insetBy(dx: padding, dy: padding)
            targetFrame = targetFrame.inset(by: edgeInsets)
            childView.frame = targetFrame

            childView.clipsToBounds = (childView.tag == SplitView.ClipSubivewTag)

            counter += 1
        }

        if preventAnimations {
            CATransaction.commit()
        }

        didLayoutSubviews?()
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
            return SplitViewLayoutInstruction(value: insetValue, layoutType: .fixed)
        }
    }
}
