//
//  SheetView.swift
//  BaseComponents
//
//  Created by mmackh on 09.05.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

fileprivate class SheetViewInternalComponent {
    let spacing: CGFloat
    let components: [SheetViewComponent]
    
    weak var containerView: UIVisualEffectView? = nil
    
    init(spacing: CGFloat, components: [SheetViewComponent]) {
        self.spacing = spacing
        self.components = components
    }
}

public class SheetView: UIView, UIGestureRecognizerDelegate {
    private var componentView: UIView = UIView()
    private var componentViewHeight: CGFloat = 0
    private var componentViewBoundsCache: CGRect = .zero
    
    private var internalComponents: [SheetViewInternalComponent] = []
    private var buttonComponents: [SheetViewButton.HighlightButton] = []
    
    private var shown: Bool = false
    private var dismissed: Bool = false
    
    public var components: [SheetViewComponent] = [] {
        didSet {
            var temporaryComponents: [SheetViewComponent] = []
            for component in components {
                if let space = component as? SheetViewSpace {
                    internalComponents.append(SheetViewInternalComponent(spacing: space.height, components: temporaryComponents))
                    temporaryComponents.removeAll()
                }
                temporaryComponents.append(component)
            }
            if temporaryComponents.count > 0 {
                internalComponents.append(SheetViewInternalComponent(spacing: 0, components: temporaryComponents))
            }
        }
    }
    
    public var horizontalPadding: CGFloat = 15.0
    public var adjustToSafeAreaInsets: Bool = true
    public var maximumWidth: CGFloat = 420.0
    
    public var componentBackgroundViewProvider: ((_ section: Int)->(UIVisualEffectView))? = nil
    
    public init(components: [SheetViewComponent]) {
        super.init(frame: .zero)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.components = components
    }
    
    public init() {
        super.init(frame: .zero)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show(in view: UIView?) {
        guard let view = view else { return }
        self.frame = view.bounds
        view.addSubview(self)
        show(true)
    }
    
    public func dismiss() {
        show(false)
    }
    
    private func show(_ show: Bool) {
        
        if !show {
            if dismissed {
                return
            }
            dismissed = true
            
            UIView.animate(withDuration: 0.2, animations: {
                self.color(.background, .clear)
                self.componentView.frame = self.currentFrame()
            }) { (complete) in
                if !complete { return }
                
                self.destroy()
            }
            
            return
        }
        
        invalidateLayout()
        self.componentView.frame = currentFrame()
        shown = true
        
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .allowUserInteraction, animations: {
            self.componentView.frame = self.currentFrame()
        })
        
        self.color(.background, .clear)
        UIView.animate(withDuration: 0.3) {
            self.color(.background, .init(white: 0, alpha: 0.3))
        }
        
        let dismissTap = UITapGestureRecognizer { [weak self] (tap) in
            if tap.state == .recognized {
                self?.dismiss()
            }
        }
        self.addGestureRecognizer(dismissTap)
    }
    
    private func backgroundViewFactory(_ section: Int) -> UIVisualEffectView {
        if let backgroundViewProvider = componentBackgroundViewProvider {
            return backgroundViewProvider(section)
        }
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular)).border(cornerRadius: 12.0)
        visualEffectView.contentView.color(.background, .dynamic(light: .init(white: 1, alpha: 0.4), dark: .init(white: 0.3, alpha: 0.4)))
        return visualEffectView
    }
    
    func suggestedWidth() -> CGFloat {
        guard let superview = superview else { return 0 }
        return min(superview.bounds.width - horizontalPadding * 2, 480)
    }
    
    func currentFrame() -> CGRect {
        guard let superview = superview else { return .zero }
        
        let x = (superview.bounds.width - suggestedWidth()) / 2
        
        if dismissed || !shown {
            return .init(x: x, y: superview.bounds.height, width: suggestedWidth(), height: componentViewHeight)
        }
        
        return .init(x: x, y: superview.bounds.height - (adjustToSafeAreaInsets ? superview.safeAreaInsets.bottom : 0) - componentViewHeight, width: suggestedWidth(), height: componentViewHeight)
    }
    
    func destroy() {
        for internalComponent in internalComponents {
            for component in internalComponent.components {
                component.contentView?.removeFromSuperview()
                component.contentView = nil
            }
            internalComponent.containerView?.removeFromSuperview()
        }
        internalComponents.removeAll()
        buttonComponents.removeAll()
        
        removeFromSuperview()
    }
    
    public func invalidateLayout() {
        componentViewBoundsCache = .zero
        layoutSubviews()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if componentViewBoundsCache.equalTo(bounds) {
            return
        }
        componentViewBoundsCache = bounds
        
        if dismissed {
            return
        }
        
        let width = suggestedWidth()
        guard let superview = superview else { return }
        
        let initialLayout = (self.componentView.superview == nil)
        self.componentView.frame = .init(x: 0, y: 0, width: width, height: 0)
        if initialLayout {
            addSubview(componentView)
        }
        
        var overallHeightTracker: CGFloat = 0.0
        for (idx, internalComponent) in internalComponents.enumerated() {
            var internalComponentHeightTracker: CGFloat = 0.0
            let subComponentView = internalComponent.containerView != nil ? internalComponent.containerView! : backgroundViewFactory(idx)
            subComponentView.frame = .init(x: 0, y: 0, width: width, height: 0)
            if initialLayout {
                internalComponent.containerView = subComponentView
            }
            
            for component in internalComponent.components {
                if let componentView = component.contentView {
                    var height = component.height
                    if let dynamicHeightHandler = component.dynamicHeightHandler {
                        height = dynamicHeightHandler(superview.bounds)
                    }
                    componentView.frame = .init(x: 0, y: internalComponentHeightTracker, width: width, height: height)
                    componentView.clipsToBounds = component.clipsToBounds
                    internalComponentHeightTracker += height
                    if initialLayout {
                        subComponentView.contentView.addSubview(componentView)
                    }
                }
                if initialLayout {
                    if let buttonComponent = component as? SheetViewButton {
                        if buttonComponent.dismissOnTap {
                            if let button = buttonComponent.contentView as? UIButton {
                                button.addAction(for: .touchUpInside) { [unowned self] (button) in
                                    self.dismiss()
                                }
                            }
                        }
                        
                        if let button = buttonComponent.contentView as? SheetViewButton.HighlightButton {
                            buttonComponents.append(button)
                        }
                        
                    }
                    if let customViewComponent = component as? SheetViewCustomView {
                        if customViewComponent.enableInteractiveDismissGuesture {
                            customViewComponent.contentView?.addGestureRecognizer(UIPanGestureRecognizer({ [unowned self] (gesture) in
                                guard let pan = gesture as? UIPanGestureRecognizer else { return }
                                
                                let yTranslation = pan.translation(in: self.componentView).y
                                if pan.state == .ended || pan.state == .cancelled || pan.state == .failed {
                                    
                                    let threshold: CGFloat = 50
                                    
                                    if (yTranslation <= threshold) {
                                        let animationDuration = TimeInterval(0.001 * abs(yTranslation) + 0.35)
                                        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                                            self.componentView.transform = .identity
                                        })
                                    } else {
                                        self.dismiss()
                                    }
                                }
                                
                                if pan.state == .changed {
                                    self.componentView.transform = .init(translationX: 0, y: yTranslation)
                                }
                            }))
                        }
                    }
                }
            }
            subComponentView.frame = .init(x: 0, y: overallHeightTracker, width: width, height: internalComponentHeightTracker)
            overallHeightTracker += internalComponentHeightTracker
            overallHeightTracker += internalComponent.spacing
            componentView.addSubview(subComponentView)
        }
        
        
        self.componentViewHeight = overallHeightTracker
        componentView.frame = currentFrame()
        
        if initialLayout == false { return }
        
        superview.addSubview(componentView)
        
        let gesture = SheetGestureRecognizer { [weak self] (gesture) in
            
            guard let componentView = self?.componentView, let buttonComponents = self?.buttonComponents else { return }
            
            let point = gesture.location(in: componentView)
            
            var aButtonWasHighlighted = false
            let isCompleted: Bool = gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled
            for button in buttonComponents {
                if isCompleted  {
                    if button.isHighlighted {
                        button.sendActions(for: .touchUpInside)
                        button.isHighlighted = false
                    }
                    continue
                }
                
                if button.convert(button.bounds, to: componentView).contains(point) {
                    button.isHighlighted = true
                    aButtonWasHighlighted = true
                } else {
                    button.isHighlighted = false
                }
            }
            
            if gesture.state == .began && aButtonWasHighlighted == false {
                gesture.cancel()
            }
        }
        componentView.addGestureRecognizer(gesture)
    }

    private class SheetGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
        var onStateChange: ((SheetGestureRecognizer)->())?
        
        convenience init(onStateChange: @escaping (UIGestureRecognizer)->()) {
            self.init(onStateChange)
            
            self.onStateChange = onStateChange
            delegate = self
        }
        
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            if state == .began {
                return
            }
            self.state = .began
            super.touchesBegan(touches, with: event)
            
            if let onStateChange = onStateChange {
                unowned let weakSelf = self
                onStateChange(weakSelf)
            }
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer == self && gestureRecognizer.state == .cancelled {
                return true
            }
            return false
        }
    }
}

open class SheetViewComponent {
    public var contentView: UIView?
    public var height: CGFloat = 0.0
    public var dynamicHeightHandler: ((_ superviewBounds: CGRect)->(CGFloat))? = nil
    public var clipsToBounds: Bool = true
}

open class SheetViewButton: SheetViewComponent {
    public var dismissOnTap: Bool = true
    
    public init(_ title: String, configurationHandler: ((UIButton)->())? = nil, onTap: ((UIButton)->())?, dismissOnTap: Bool = true) {
        super.init()
        
        let button = HighlightButton(title: title).size(17.5)
        
        if let configurationHandler = configurationHandler {
            unowned let buttonUnowned = button
            configurationHandler(buttonUnowned)
        }
        
        button.addAction(for: .touchUpInside) { (button) in
            if let onTap = onTap {
                onTap(button)
            }
        }
        
        self.dismissOnTap = dismissOnTap
        self.contentView = button
        self.height = 54.0
    }
    
    fileprivate class HighlightButton: UIButton {
        override open var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .init(white: 0.6, alpha: 0.2) : .clear
            }
        }
        
        init(title: String) {
            super.init(frame: .zero)
            
            setTitle(title, for: .normal)
            setTitleColor(tintColor, for: .normal)
            
            isUserInteractionEnabled = false
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

open class SheetViewSpace: SheetViewComponent {
    public init(_ height: CGFloat = 15.0) {
        super.init()
        
        self.height = height
    }
}

open class SheetViewCustomView: SheetViewComponent {
    public var enableInteractiveDismissGuesture: Bool = false
    
    public init(_ view: UIView, height: CGFloat) {
        super.init()
        
        self.contentView = view
        self.height = height
    }
}

open class SheetViewSeparator: SheetViewCustomView {
    public init() {
        super.init(UIView().color(.background, .hairline), height: .onePixel)
    }
}

open class SheetViewNavigationBar: SheetViewCustomView {
    public init(title: String, leftBarButton: UIButton?, rightBarButton: UIButton?) {
        let containerView = UIView().color(.background, .dynamic(light: .init(white: 1, alpha: 0.2), dark: .init(white: 0.3, alpha: 0.4)))
        let titleLabel = UILabel(title).size(17.5, .bold).align(.center)
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(titleLabel)
        
        containerView.addSplitView { (splitView) in
            splitView.addSplitView(configurationHandler: { (splitView) in
                splitView.direction = .horizontal
                        
                func addPlaceholderView() {
                   splitView.addSubview(UIView(), layoutType: .equal, edgeInsets: .zero)
                }

                if let leftBarButton = leftBarButton {
                   splitView.addSubview(leftBarButton, layoutType: .equal, edgeInsets: .init(top: 0, left: 15, bottom: 0, right: 0))
                   leftBarButton.align(.left).size(using: .systemFont(ofSize: 17))
                } else {
                   addPlaceholderView()
                }

                addPlaceholderView()

                if let rightBarButton = rightBarButton {
                   splitView.addSubview(rightBarButton, layoutType: .equal, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 15))
                   rightBarButton.align(.right).size(using: .boldSystemFont(ofSize: 17))
                } else {
                   addPlaceholderView()
                }
            }, layoutType: .percentage, value: 100)
            
            splitView.addSubview(UIView().color(.background, .hairline), layoutType: .fixed, value: .onePixel)
        }
        
        super.init(containerView, height: 55.0)
    }
}
