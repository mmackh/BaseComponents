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

/**
 Display a customisable sheet similar to `UIAlertController.Style.actionSheet`, that is both more flexible and easier to use.
 
 A `SheetView` instance can be constructed using `components`. A component provides a contentView and a given height (height can either be static or dynamic - use `invalidateLayout()` to recalculate). Premade `SheetViewComponent`s include:
    - **SheetViewPullTab**: A pill view indicating that the sheet can be interactively dismissed
    - **SheetViewNavigationBar**: A simple compact `UINavigationBar` replica
    - **SheetViewButton**: A button module that highlights and acts like an UIAlertController button
    - **SheetViewSeparator**: A hairline divider used to separate components
    - **SheetViewSpace**: Divides components into sections
    - **SheetViewCustomView**: A base class to use for adding custom UI to SheetView
 
 Each section (divided by SheetViewSpace), has a background which can be styled using `sectionBackgroundViewProvider()`. To further style the sheet, use `maximumWidth`, `adjustToSafeAreaInsets` or `horizontalInset`. After components have been added and the sheet is styled, display it using `show(in view: UIView?)`.
 
 # Best Practices
 1. Set `components` only once
 2. Be careful about creating retain cycles when working with closures
 3. If the app supports landscape, test if your `SheetView` instance does not overflow
 
# Code Example
 
 *Basic*
 
 SheetView containing 2 buttons, separated into two sections. One button is styled red.
 ```
 let sheetView = SheetView()
 sheetView.components = [
    SheetViewButton("Delete", configurationHandler: { (button) in
        button.color(.text, .red)
    }, onTap: nil),
    SheetViewSpace(),
    SheetViewButton("Cancel", onTap: nil),
 ]
 sheetView.show(in: self.view)
 ```
 
 *Advanced*
 
 SheetView mimicking a `UIViewController`, including a `UINavigationBar`, sliding in from the bottom. Has the ability to be interactivly dismissed. Features a `UIDatePicker` in a `SheetViewCustomView` component.
 ```
 let sheetView = SheetView()
 let sheetNavigationBarComponent = SheetViewNavigationBar(title: "Navigation Bar", leftBarButton: UIButton(title: "Cancel", type: .system), rightBarButton: UIButton(title: "Save", type: .system))
 sheetNavigationBarComponent.enableInteractiveDismissGuesture = true
 
 let dynamicBottomPadding = SheetViewCustomView(UIView(), height: 0)
 dynamicBottomPadding.dynamicHeightHandler = { [unowned self] parentRect in
     return self.navigationController?.view.safeAreaInsets.bottom ?? 0
 }
 sheetView.components = [
     SheetViewPullTab(style: .navigationBar),
     sheetNavigationBarComponent,
     SheetViewCustomView(UIDatePicker(frame: .zero), height: 200),
     SheetViewButton("Done", onTap: nil),
     dynamicBottomPadding,
 ]
 sheetView.adjustToSafeAreaInsets = false
 sheetView.horizontalInset = 0
 sheetView.show(in: self.navigationController?.view)
 ```
*/
public class SheetView: UIView, UIGestureRecognizerDelegate {
    private var componentView: UIView = UIView()
    private var componentViewHeight: CGFloat = 0
    private var componentViewBoundsCache: CGRect = .zero
    private var keyboardVisible = false
    
    private var internalSectionComponents: [SheetView.InternalSectionComponent] = []
    private var buttonComponents: [SheetViewButton.HighlightButton] = []
    
    private var shown: Bool = false
    private var dismissed: Bool = false
    
    /**
     Declare components for use in a `SheetView` instance
     
     Once the sheet is shown for the first time, `contentView`s defined within components are added to the sheet permanently. This behaviour chould change in the future.
     
     - Attention: Can only be set once before the sheet is shown
     */
    public var components: [SheetViewComponent] = [] {
        didSet {
            var temporaryComponents: [SheetViewComponent] = []
            for component in components {
                if let space = component as? SheetViewSpace {
                    internalSectionComponents.append(SheetView.InternalSectionComponent(spacing: space.height, components: temporaryComponents))
                    temporaryComponents.removeAll()
                }
                temporaryComponents.append(component)
            }
            if temporaryComponents.count > 0 {
                internalSectionComponents.append(SheetView.InternalSectionComponent(spacing: 0, components: temporaryComponents))
            }
        }
    }
    
    /**
     Get notified when the sheet will start the showing animation
     */
    public var onBeforeShow: ((SheetView)->())? = nil
    
    /**
     Get notified when the sheet has completed the showing animation
     */
    public var onShow: ((SheetView)->())? = nil
    
    /**
     Get notified when the sheet was completely dismissed, but before it has been removed from the superview
     */
    public var onDismissed: ((SheetView)->())? = nil
    
    /**
     Prevent the sheet from being dismissed, if the user needs to meet a certain state
     
     The sheet can still be moved through interactive gestures, however it will refuse to close and thus prevent the user from tapping views below the sheet.
     */
    public var isDismissable: Bool = true
    
    /**
     Declare the left and right inset
     
     By default, an inset of 15pts is applied on either side and `SheetView` to follow the conventions of UIKit. This yields a design similar to to `UIAlertController.Style.actionSheet`.
     */
    public var horizontalInset: CGFloat = 15.0
    
    /**
     Declare whether the `SheetView` adheres to `superview`'s safeAreaInsets
     
     In order to avoid displaying UI below the home indicator on all-screen phones/pads, the default behaviour is to adhere to safeAreaInsets defined by the `view` on which `SheetView` is presented. When this variable is `false`, an additional dynamic height component should be added to avoid overlapping UI elements.
     */
    public var adjustToSafeAreaInsets: Bool = true
    
    /**
     The default bottom padding when `safeAreaInsets.bottom` is zero
     
     The safe area insets can be zero when the device has a homebutton or when the software keyboard is shown.
     */
    public var bottomPaddingOnSafeAreaUnavailable: CGFloat = 15.0
    
    /**
     The maximum width `SheetView` can have on wider screens
     
     The value for `horizontalInset` is deducted from `maximumWidth` for consistency purposes.
     */
    public var maximumWidth: CGFloat = 420.0
    
    /**
     A `UITextField` or `UITextView` can require a software keyboard to be shown, which covers up a large portion of the screen. The default behaviour for the sheet is to reposition itself automatically in those situations
     */
    public var automaticKeyboardRepositioning: Bool = true
    
    /**
     Define custom backgrounds for sections created by adding `SheetViewSpace` inbetween other components
     
     In order mimic the style of `UIAlertController.Style.actionSheet`, an instance of `UIVisualEffectView` has to be returned. If desired, the background can be colored using e.g., `.color(.background, UIColor.blue.alpha(0.5))`. Determine the transparency by tweaking the alpha value.
     A custom `borderRadius` value can determine the appearance of the edges
     
     # Code Example
     ```
     sheetView.sectionBackgroundViewProvider = { section in
         let view = UIVisualEffectView()
             .color(.background, .white)
             .border(cornerRadius: 12)
         return view
     }
     ```
     */
    public var sectionBackgroundViewProvider: ((_ section: Int)->(UIVisualEffectView))? = nil
    
    /**
     Convenience initializer for situations not requiring components to reference the `SheetView` instance for more complex behaviour.
     
     - parameter components: Array of `SheetViewComponent`s to build the sheet.
     */
    public convenience init(components: [SheetViewComponent]) {
        self.init()
        
        self.components = components
    }
    
    /**
     Initializes an instance of `SheetView`
     
     In order to create more complex behaviour, an instance of the sheets needs to be sometimes referenced in components. Always make sure to add `[unowned self]` or `[weak self]` whenever appropriate to avoid retain cycles.
     */
    public init() {
        super.init(frame: .zero)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Display an instance of `SheetView` in a view
     
     It is often better to display a sheetView in a `UIViewController`'s `navigationController?.view` or `tabBarController?.view` in order for the entire background to be dimmed and thus to prevent the user from entering an invalid state.
     
     Ensure that the view does exist, otherwise `SheetView` will refuse to show.
     
     # Code Example
     ```
     sheetView.show(in: self.navigationController?.view)
     ```
     or
     ```
     if let view = self.tabBarController?.view {
         sheetView.show(in: view)
     }
     ```
     
     - parameter view: Superview upon which all `SheetView` components will be added.
     */
    public func show(in view: UIView?) {
        guard let view = view else { return }
        self.frame = view.bounds
        view.addSubview(self)
        show(true)
    }
    
    /**
     Recalculates every component's `contentView` manually. Only useful when a component was added that features a dynamic height
     
     Occures also when `layoutSubviews()` is called, however an additional bounds check will prevent `SheetView` from doing unecessary work.
     */
    public func invalidateLayout() {
        componentViewBoundsCache = .zero
        layoutSubviews()
    }
    
    /**
     Manually dismiss a `SheetView` instance
     
     Once dismissed, the same sheet cannot be shown again.
     */
    public func dismiss() {
        show(false)
    }
    
    private func show(_ show: Bool) {
        if !show {
            if !self.isDismissable {
                return
            }
            
            if dismissed {
                return
            }
            dismissed = true
            
            UIView.animate(withDuration: 0.2, animations: {
                self.color(.background, .clear)
                self.componentView.frame = self.currentFrame()
            }) { (complete) in
                if !complete { return }
                
                if let onDismissed = self.onDismissed {
                    unowned let weakSelf = self
                    onDismissed(weakSelf)
                }
                
                self.destroy()
            }
            
            return
        }
        
        if automaticKeyboardRepositioning {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardDidShowNotification, object: nil)
            notificationCenter.addObserver(self, selector:#selector(showKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
        invalidateLayout()
        self.componentView.frame = currentFrame()
        shown = true
        
        if let onBeforeShow = self.onBeforeShow {
            unowned let weakSelf = self
            onBeforeShow(weakSelf)
        }
        
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .allowUserInteraction, animations: {
            if !self.keyboardVisible {
                self.componentView.frame = self.currentFrame()
            }
        }, completion: { completed in
            if !completed { return }
            
            if let onShow = self.onShow {
                unowned let weakSelf = self
                onShow(weakSelf)
            }
        })
        
        self.color(.background, .clear)
        UIView.animate(withDuration: 0.3) {
            self.color(.background, .dynamic(light: .init(white: 0, alpha: 0.2), dark: .init(white: 0, alpha: 0.6)))
        }
        
        let dismissTap = UITapGestureRecognizer { [weak self] (tap) in
            if tap.state == .recognized {
                self?.dismiss()
            }
        }
        self.addGestureRecognizer(dismissTap)
    }
    
    @objc func showKeyboard(notificationObject: Notification) {
        let show = (notificationObject.name == UIResponder.keyboardDidShowNotification || notificationObject.name == UIResponder.keyboardWillShowNotification)
        keyboardVisible = show
        
        let keyboardFrame = (notificationObject.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let animationDuration = (notificationObject.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
        let animationCurve = (notificationObject.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.uintValue ?? 0
        if let superview = superview {
            let masterFrame = superview.convert(superview.frame, to: window)
            let intersectionFrame = masterFrame.intersection(keyboardFrame)
            var targetFrame = superview.bounds
            targetFrame.size.height -= intersectionFrame.size.height
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve), animations: {
                self.frame = targetFrame
                self.componentView.frame = self.currentFrame()
            }, completion: nil)
        }
    }
    
    deinit {
        if !automaticKeyboardRepositioning { return }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func sectionBackgroundViewFactory(_ section: Int) -> UIVisualEffectView {
        if let sectionBackgroundViewProvider = sectionBackgroundViewProvider {
            return sectionBackgroundViewProvider(section)
        }
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular)).border(cornerRadius: 12.0)
        visualEffectView.contentView.color(.background, .dynamic(light: .init(white: 1, alpha: 0.7), dark: .init(white: 0.1, alpha: 0.4)))
        return visualEffectView
    }
    
    private func suggestedWidth() -> CGFloat {
        return min(bounds.width - horizontalInset * 2, maximumWidth)
    }
    
    private func currentFrame() -> CGRect {
        let x = (bounds.width - suggestedWidth()) / 2
        
        if dismissed || !shown {
            return .init(x: x, y: bounds.height, width: suggestedWidth(), height: componentViewHeight)
        }
        
        return .init(x: x, y: bounds.height - (adjustToSafeAreaInsets ? (safeAreaInsets.bottom > 0 ? safeAreaInsets.bottom : bottomPaddingOnSafeAreaUnavailable) : 0) - componentViewHeight, width: suggestedWidth(), height: componentViewHeight)
    }
    
    private func destroy() {
        for internalComponent in internalSectionComponents {
            for component in internalComponent.components {
                component.contentView?.removeFromSuperview()
                component.contentView = nil
            }
            internalComponent.containerView?.removeFromSuperview()
        }
        internalSectionComponents.removeAll()
        buttonComponents.removeAll()
        
        componentView.removeFromSuperview()
        
        removeFromSuperview()
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
        for (idx, internalComponent) in internalSectionComponents.enumerated() {
            var internalComponentHeightTracker: CGFloat = 0.0
            let subComponentView = internalComponent.containerView != nil ? internalComponent.containerView! : sectionBackgroundViewFactory(idx)
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
                        if customViewComponent.enableInteractiveDismissGesture {
                            customViewComponent.contentView?.addGestureRecognizer(UIPanGestureRecognizer({ [unowned self] (gesture) in
                                guard let pan = gesture as? UIPanGestureRecognizer else { return }
                                
                                let yTranslation = pan.translation(in: self.componentView).y
                                if pan.state == .ended || pan.state == .cancelled || pan.state == .failed {
                                    
                                    let threshold: CGFloat = 50
                                    
                                    if (yTranslation <= threshold) || !self.isDismissable {
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

    fileprivate class InternalSectionComponent {
        let spacing: CGFloat
        let components: [SheetViewComponent]
        
        weak var containerView: UIVisualEffectView? = nil
        
        init(spacing: CGFloat, components: [SheetViewComponent]) {
            self.spacing = spacing
            self.components = components
        }
    }
}

/**
 Used as a base class for all components
 
 Not recommended as a subclass for custom components, use `SheetViewCustomView` instead.
 */
open class SheetViewComponent {
    /**
     References the view to add when `show(in view: UIView?)` is called
     
     Should not be reassigned or nilled, once the sheet has been shown. Used as a reference in `layoutSubviews()`
     */
    public var contentView: UIView?
    
    /**
     Determines the height of the component
     
     All premade components have a pre-determined height.
     */
    public var height: CGFloat = 0.0
    
    /**
     Implement for dynamic height handling of a component
     
     Should a sheet require additional tuning or components have a different height depending on device orientation, implement this handler. The sheet will update automatically on `layoutSubviews()` or manually when `invalidateLayout()` is called.
     
     # Code Example
     ```
     let sheetViewCustomView = SheetViewCustomView(UIView(), height: 0)
     sheetViewCustomView.dynamicHeightHandler = { [unowned self] parentRect in
         return self.view.safeAreaInsets.bottom
     }
     ```
     */
    public var dynamicHeightHandler: ((_ superviewBounds: CGRect)->(CGFloat))? = nil
    
    /**
     Prevents the `contentView` from overflowing when its height is less than that of its subviews
     
     Useful when used in conjunction with `dynamicHeightHandler` - a component's visiblity can be toggled for a more complex sheet interface.
     */
    public var clipsToBounds: Bool = true
}

/**
 A component used to add buttons to a `SheetView` instance
 
 In order to mimick the handeling and style of `UIAlertController` buttons, this class provides all the necessary logic. When a sheet is shown, the user can tap on a given button, change their mind and slide to a different one - changing the highlight states in the process. Since UIButton does not provide us with all necessary behaviour, `SheetViewButton` uses its own private subclass.
 
 - Attention: Don't overwrite the `contentView` with a UIButton instance, this will break the custom gesture recognizer and internal logic.
 */
open class SheetViewButton: SheetViewComponent {
    fileprivate var dismissOnTap: Bool = true
    
    /**
     Initializes a new button component with a default height of 57.0pts
     
     - parameter title: Title of the button in `.normal` state
     - parameter configurationHandler: Optionally style the button, e.g. to change the color or font size
     - parameter onTap: Called when the user taps the button
     - parameter dismissOnTap: Change the value to `false` to prevent the `SheetView` instance from being dismissed when the button is being tapped
     */
    public init(_ title: String, configurationHandler: ((UIButton)->())? = nil, onTap: ((UIButton)->())?, dismissOnTap: Bool = true) {
        super.init()
        
        let button = HighlightButton(title: title).size(19.0)
        
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
        self.height = 57.0
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
/**
 A component used to separate components into sections within a `SheetView` instance

 In order to logically divide the sheet into sections, insert space components where necessary. Mimicks the behaviour of `UIAlertController`, where usually the *Dismiss* or *Cancel* buttons are visually separated from the rest of the button groups.
 */
open class SheetViewSpace: SheetViewComponent {
    /**
      Initializes a new space component with a separation distance of 8.0pts

      - parameter height: Distance between two sections
     */
    public init(_ height: CGFloat = 8.0) {
        super.init()
        
        self.height = height
    }
}

/**
A component used as a foundation for embedding custom views into a `SheetView` instance

Subclass this component or use as-is. What separates this class from `SheetViewComponent` is the ability to enable an interactive dismiss gesture, which lets the user dismiss the `SheetView`.
*/
open class SheetViewCustomView: SheetViewComponent {
    /**
     Determines if a `UIPanGestureRecognizer` is added to the `contentView`
     
     Before enabeling this property, make sure that adding an additional `UIGestureRecognizer` will not conflict with any existing ones, e.g. when the contentView is a `UITableView`.
     */
    public var enableInteractiveDismissGesture: Bool = false
    
    /**
     Initializes a new `SheetViewCustomView` instance

     - parameter view: Assign a view that is to be embedded into the sheet
     - parameter height: Determines the height of the component
    */
    public init(_ view: UIView, height: CGFloat) {
        super.init()
        
        self.contentView = view
        self.height = height
    }
}

/**
A component used to visually separate buttons or other components with a thin (1px) line
*/
open class SheetViewSeparator: SheetViewCustomView {
    public init() {
        super.init(UIView().color(.background, .hairline), height: .onePixel)
    }
}

/**
A component used to communicate the availability of being able to interactivly dismiss the sheet through a panning gesture
*/
open class SheetViewPullTab: SheetViewCustomView {
    /// Style makes sure that the pullTab fits in, regardless of the positioning
    public enum Style {
        /// Features a height of 30pts and a clear background color
        case standard
        /// Choose when pullTab is positioned above a `SheetViewNavigationBar` component to decrease the height and match background colors
        case navigationBar
    }
    
    /**
     Initializes a new `SheetViewPullTab` instance

     - parameter style: Change to a different style, depending on the component's positioning
    */
    public init(style: Style = .standard) {
        let height: CGFloat = 30
        
        let pillIndicator = UIView(frame: .init(x: 0, y: 0, width: 40, height: 5))
            .border(cornerRadius: 2.5)
            .color(.background, .dynamic(light: .init(white: 0.2, alpha: 0.3), dark: .init(white: 1, alpha: 0.2)))
        pillIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        let contentView = UIView(frame: .init(x: 0, y: 0, width: 320, height: height))
        contentView.addSubview(pillIndicator)
        pillIndicator.center = contentView.center
        
        super.init(contentView, height: height)
        
        enableInteractiveDismissGesture = true
        
        if style == .navigationBar {
            contentView.color(.background, SheetViewNavigationBar.backgroundColor)
            self.height = 20
        }
    }
}

/**
A component mimicking the style of `UINavigationBar` with a smaller title label
*/
open class SheetViewNavigationBar: SheetViewCustomView {
    
    /**
     Define a default backgroundColor for all instances of `SheetViewNavigationBar`
     
     This property will also determine the background color of the `SheetViewPullTab` component when `SheetViewPullTab.Style` is set to `.navigationBar`
     */
    public static var backgroundColor: UIColor = .dynamic(light: .init(white: 1, alpha: 0.2), dark: .init(white: 0.3, alpha: 0.4))
    
    /**
     Initializes a new `SheetViewNavigationBar` instance

     - parameter title: Positioned in the center with a fixed size of 17.5pts
     - parameter leftBarButton: Optional, add a UIButton on the left side of the navigation bar
     - parameter rightBarButton: Optional, add a UIButton on the right side of the navigation bar
     
     This code serves as example for how to design and implement more complex custom views for a `SheetView`. `SplitView`s are being used to illustrate on how achive a more complex layout with minimal LOC.
     
     # Code Example
     ```
     let sheetNavigationBarComponent = SheetViewNavigationBar(
         title: "Navigation Bar",
         leftBarButton: nil,
         rightBarButton: UIButton(title: "Save", type: .system).addAction(for: .touchUpInside, { (button) in
             // perform save action
         })
     )
     ```
    */
    public init(title: String, leftBarButton: UIButton?, rightBarButton: UIButton?) {
        let containerView = UIView().color(.background, SheetViewNavigationBar.backgroundColor)
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

/**
 Convenience extension for configuring a `SheetView` instance with minimal LOC to look like `UIAlertController.Style.actionSheet`
 */
public extension SheetView {
    /**
     Convenience function to display an instance of `SheetView` with buttons and a closure as completion handler.
     
     Buttons are tuples with an optional color variable. Useful when alerting the user to a destructive action.
    
     # Code Example
     ```
     SheetView.showIn(view: self.navigationController?.view, buttons: [("Edit Note",nil),("Delete",.red)], dismissButton: ("Dismiss",nil)) { [unowned self] (idx) in
         if idx == 0 {
             self.showEditSheet(for: itemRenderProperties.object as? Note)
         }
         if idx == 1 {
             self.navigationController?.view.showProgressView(true)
             self.dataProvider.delete((itemRenderProperties.object as! Note)) { (error) in
                 self.navigationController?.view.showProgressView(false)
                 if error == nil {
                     self.dataRender.removeNote(at: itemRenderProperties.indexPath.row)
                 }
             }
         }
     }
     ```
    
     - parameter view: Superview upon which all `SheetView` components will be added.
     - parameter buttons: Tuple with (title: String, color: UIColor?)
     - parameter dismissButton: Optional: tuple with tile and optional color
     - parameter onDismiss: closure that is called when a button has been tapped. Will not be called when the dismiss button has been tapped
    */
    @discardableResult
    static func showIn(view: UIView?, buttons: [(String, UIColor?)], dismissButton: (String, UIColor?)?, onDismiss: @escaping(_ buttonIdx: Int)->()) -> SheetView {
        let sheetView = SheetView()
        let lastIdx = buttons.count - 1
        var components: [SheetViewComponent] = []
        for (idx, button) in buttons.enumerated() {
            components.append(SheetViewButton(button.0, configurationHandler: { (uiButton) in
                if let color = button.1 {
                    uiButton.color(.text, color)
                }
            }, onTap: { (uiButton) in
                onDismiss(idx)
            }, dismissOnTap: true))
            if idx != lastIdx {
                components.append(SheetViewSeparator())
            }
        }
        
        if let dismissButton = dismissButton {
            components.append(SheetViewSpace())
            components.append(SheetViewButton(dismissButton.0, configurationHandler: { (button) in
                if let dismissButtonColor = dismissButton.1 {
                    button.color(.text, dismissButtonColor).size(19, .bold)
                }
            }, onTap: nil, dismissOnTap: true))
        }
        
        sheetView.components = components
        sheetView.show(in: view)
        
        return sheetView
    }
}
