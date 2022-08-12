
//  InterfaceBuilder.swift
//  BaseComponents
//
//  Created by mmackh on 10.07.22.
//  Copyright © 2022 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#if os(iOS)

import UIKit

extension UIView {
    @discardableResult
    public func build(@InterfaceBuilder.Builder _ builder: ()->[InterfaceBuilderComponent]) -> InterfaceBuilder.Tree? {
        let components = builder()
        let rootSplitView: SplitView = {
            if let splitView = self as? SplitView {
                return splitView
            }
            return self.addSplitView { _ in }
        }()
        
        let tree: InterfaceBuilder.Tree = InterfaceBuilder.Tree(superview: self, rootSplitView: rootSplitView)
        InterfaceBuilder.layout(on: rootSplitView, components: components, tree: tree)
        return tree
    }
}

public class InterfaceBuilder {
    @resultBuilder
    public struct Builder {
        public static func buildBlock(_ components: InterfaceBuilderComponent...) -> [InterfaceBuilderComponent] {
            components
        }
        
        public static func buildBlock(_ components: [InterfaceBuilderComponent]...) -> [InterfaceBuilderComponent] {
            components.flatMap { $0 }
        }
        
        public static func buildOptional(_ component: [InterfaceBuilderComponent]?) -> [InterfaceBuilderComponent] {
            component ?? []
        }
        
        public static func buildEither(first component: [InterfaceBuilderComponent]) -> [InterfaceBuilderComponent] {
            component
        }
        
        public static func buildEither(second component: [InterfaceBuilderComponent]) -> [InterfaceBuilderComponent] {
            component
        }
        
        public static func buildExpression(_ expression: InterfaceBuilderComponent) -> [InterfaceBuilderComponent] {
            [expression]
        }
        
        public static func buildExpression(_ expression: [InterfaceBuilderComponent]) -> [InterfaceBuilderComponent] {
            expression
        }
        
        public static func buildArray(_ components: [[InterfaceBuilderComponent]]) -> [InterfaceBuilderComponent] {
            components.flatMap { $0 }
        }
    }
    
    public enum Direction {
        case vertical
        case horizontal
        
        var splitViewDirection: SplitViewDirection {
            self == .vertical ? .vertical : .horizontal
        }
        
        var scrollingViewDirection: ScrollingViewDirection {
            self == .vertical ? .vertical : .horizontal
        }
    }

    public enum LayoutType {
        // Split & Scroll
        case fixed
        case automatic
        
        // Split only
        case percentage
        case equal
        case dynamic
        
        var splitViewLayoutType: SplitViewLayoutType {
            if self == .fixed { return .fixed }
            if self == .percentage { return .percentage }
            if self == .equal { return .equal }
            return .automatic
        }
        
        var scrollingViewLayoutType: ScrollingViewLayoutType {
            if self == .fixed { return .fixed }
            return .automatic
        }
    }
    
    public class LayoutInstruction {
        let `type`: InterfaceBuilder.LayoutType
        let value: CGFloat
        let insets: UIEdgeInsets
        
        public init(_ type: InterfaceBuilder.LayoutType, _ value: CGFloat, insets: UIEdgeInsets = .zero) {
            self.type = type
            self.value = value
            self.insets = insets
        }
        
        var splitViewLayoutInstruction: SplitViewLayoutInstruction {
            .init(layoutType: type.splitViewLayoutType, value: value, edgeInsets: insets)
        }
        
        var scrollingViewLayoutInstruction: ScrollingViewLayoutInstruction {
            .init(layoutType: type.scrollingViewLayoutType, value: value, edgeInsets: insets)
        }
        
        public static func fixed(_ value: CGFloat, insets: UIEdgeInsets = .zero) -> LayoutInstruction {
            LayoutInstruction(.fixed, value, insets: insets)
        }
        
        public static func percentage(_ value: CGFloat, insets: UIEdgeInsets = .zero) -> LayoutInstruction {
            LayoutInstruction(.percentage, value, insets: insets)
        }
        
        public static func equal(insets: UIEdgeInsets = .zero) -> LayoutInstruction {
            LayoutInstruction(.equal, 0, insets: insets)
        }
        
        public static func automatic(insets: UIEdgeInsets = .zero) -> LayoutInstruction {
            LayoutInstruction(.automatic, 0, insets: insets)
        }
    }
    
    public class Tree {
        weak var superview: UIView?
        public weak var rootSplitView: SplitView?
        
        init(superview: UIView, rootSplitView: SplitView) {
            self.superview = superview
            self.rootSplitView = rootSplitView
        }
        
        public func invalidateLayout() {
            superview?.subviews(of: SplitView.self).forEach({ splitView in
                splitView.invalidateLayout()
            })
            superview?.subviews(of: ScrollingView.self).forEach({ scrollingView in
                scrollingView.invalidateLayout()
            })
        }
    }
    
    static func layout(on view: UIView, components: [InterfaceBuilderComponent], tree: InterfaceBuilder.Tree) {
        let parentSplitView: SplitView? = view as? SplitView
        let parentScrollingView: ScrollingView? = view as? ScrollingView
        
        for component in components {
            if component is Modifier<SplitView> || component is Modifier<ScrollingView> {
                if let splitModifier = component as? Modifier<SplitView>, let splitView = parentSplitView {
                    splitModifier.modifierHandler(splitView)
                } else if let scrollingModifier = component as? Modifier<ScrollingView>, let scrollingView = parentScrollingView {
                    scrollingModifier.modifierHandler(scrollingView)
                }
                continue
            }
            
            let view: UIView = component.viewBuilder?() ?? UIView()
            
            if let splitComponent = component as? Split {
                if let splitView = parentSplitView {
                    splitView.addSplitView { splitView in
                        splitComponent.modifierHandler?(splitView)
                        splitView.directionHandler = {
                            splitComponent.directionHandler().splitViewDirection
                        }
                        InterfaceBuilder.layout(on: splitView, components: splitComponent.subComponents, tree: tree)
                    } valueHandler: { superviewBounds in
                        return component.layoutInstruction().splitViewLayoutInstruction
                    }
                } else if let scrollingView = parentScrollingView {
                    scrollingView.addScrollingSplitView { splitView in
                        splitView.directionHandler = {
                            splitComponent.directionHandler().splitViewDirection
                        }
                        InterfaceBuilder.layout(on: splitView, components: splitComponent.subComponents, tree: tree)
                    } valueHandler: { superviewBounds in
                        let layoutInstruction = splitComponent.layoutInstruction()
                        return .init(fixedLayoutTypeValue: layoutInstruction.value, edgeInsets: layoutInstruction.insets)
                    }

                }

                continue
            }

            if let scrollComponent = component as? Scroll {
                if let splitView = parentSplitView {
                    splitView.addScrollingView { scrollingView in
                        scrollComponent.modifierHandler?(scrollingView)
                        splitView.direction = scrollComponent.directionHandler().splitViewDirection
                        InterfaceBuilder.layout(on: scrollingView, components: scrollComponent.subComponents, tree: tree)
                    } valueHandler: { superviewBounds in
                        return component.layoutInstruction().splitViewLayoutInstruction
                    }
                }
                continue
            }
            
            if let splitView = parentSplitView {
                splitView.addSubview(view) { superviewBounds in
                    let layoutInstruction = component.layoutInstruction()
                    return layoutInstruction.splitViewLayoutInstruction
                }
            } else if let scrollingView = parentScrollingView {
                scrollingView.addSubview(view) { superviewBounds in
                    let layoutInstruction = component.layoutInstruction()
                    return layoutInstruction.scrollingViewLayoutInstruction
                }
            }
            
            if component is Padding, let paddingComponent = component as? Padding {
                paddingComponent.modifierHandler?(view)
                if let splitView = parentSplitView {
                    switch paddingComponent.observingEdgeInsetsType {
                    case .safeAreaInsets:
                        splitView.observingSuperviewSafeAreaInsets = true
                    case .layoutMargins:
                        splitView.observingSuperviewLayoutMargins = true
                    case .none:
                        break
                    }
                }
            }
        }
    }
    
    public static func build(@InterfaceBuilder.Builder _ builder:() -> [InterfaceBuilderComponent]) -> [InterfaceBuilderComponent] {
        builder()
    }
}

open class InterfaceBuilderComponent {
    open class Custom: InterfaceBuilderComponent {
        public override init(_ layoutInstruction: @escaping ()->(InterfaceBuilder.LayoutInstruction), viewBuilder: (()->(UIView))?) {
            super.init(layoutInstruction, viewBuilder: viewBuilder)
        }
    }
    
    public var subComponents: [InterfaceBuilderComponent] = []
    public let layoutInstruction: ()->(InterfaceBuilder.LayoutInstruction)
    public let viewBuilder: (()->(UIView))?
    
    init(_ layoutInstruction: @escaping ()->(InterfaceBuilder.LayoutInstruction), viewBuilder: (()->(UIView))?) {
        self.layoutInstruction = layoutInstruction
        self.viewBuilder = viewBuilder
    }
}

public class Padding: InterfaceBuilderComponent {
    let observingEdgeInsetsType: Padding.EdgeInsetsType?
    let modifierHandler: ((UIView)->())?
    
    public enum EdgeInsetsType {
        case safeAreaInsets(direction: Direction)
        case layoutMargins(direction: Direction)
        
        var direction: Direction {
            switch self {
            case .safeAreaInsets(let direction):
                return direction
            case .layoutMargins(let direction):
                return direction
            }
        }
        
        var isSafeAreaInsetsType: Bool {
            if case .safeAreaInsets = self {
                return true
            }
            return false
        }
    }
    
    public enum Direction {
        case top
        case left
        case bottom
        case right
    }
    
    public init(_ value: CGFloat) {
        self.observingEdgeInsetsType = nil
        self.modifierHandler = nil
        super.init({ .init(.fixed, value) }, viewBuilder: { UIView().userInteractionEnabled(false) })
    }
    
    public init(_ size: @escaping ()->(InterfaceBuilder.LayoutInstruction), modifier: ((_ view: UIView)->())? = nil) {
        self.observingEdgeInsetsType = nil
        self.modifierHandler = modifier
        super.init(size, viewBuilder: { UIView().userInteractionEnabled(false) })
    }
    
    public init(observe view: UIView, _ type: EdgeInsetsType, modifier: ((_ view: UIView)->())? = nil) {
        self.observingEdgeInsetsType = type
        self.modifierHandler = modifier
        super.init({ [weak view] in
            let direction = type.direction
            let insets: UIEdgeInsets = (type.isSafeAreaInsetsType ? view?.safeAreaInsets : view?.layoutMargins) ?? .zero
            let value: CGFloat = {
                switch direction {
                case .top:
                    return insets.top
                case .left:
                    return insets.left
                case .bottom:
                    return insets.bottom
                case .right:
                    return insets.right
                }
            }()
            return .init(.fixed, value)
        }, viewBuilder: { UIView().userInteractionEnabled(false) })
    }
    
}

public class Modifier<T>: InterfaceBuilderComponent {
    let modifierHandler: (_ view: T)->()
    
    public init(_ modifierHandler: @escaping (_ view: T)->()) {
        self.modifierHandler = modifierHandler
        super.init({ .init(.fixed, 0) }, viewBuilder: nil)
    }
}

public class Separator: InterfaceBuilderComponent {
    public init(insets: (()->(UIEdgeInsets))? = nil) {
        super.init({ .init(.fixed, .onePixel, insets: insets?() ?? .zero) }, viewBuilder: { UIView().color(.background, .hairline) })
    }
}

public class Fixed: InterfaceBuilderComponent {
    public init(_ value: CGFloat, _ viewBuilder: @escaping ()->(UIView), insets: (()->(UIEdgeInsets))? = nil) {
        super.init({ .init(.fixed, value, insets: insets?() ?? .zero) }, viewBuilder: viewBuilder)
    }
}

public class Percentage: InterfaceBuilderComponent {
    public init(_ value: CGFloat, _ viewBuilder: @escaping ()->(UIView), insets: (()->(UIEdgeInsets))? = nil) {
        super.init({ .init(.percentage, value, insets: insets?() ?? .zero) }, viewBuilder: viewBuilder)
    }
}

public class Automatic: InterfaceBuilderComponent {
    public init(viewBuilder: @escaping () -> (UIView), insets: (()->(UIEdgeInsets))? = nil) {
        super.init({ .init(.automatic, 0, insets: insets?() ?? .zero) }, viewBuilder: viewBuilder)
    }
}

public class Equal: InterfaceBuilderComponent {
    public init(viewBuilder: @escaping () -> (UIView?), insets: (()->(UIEdgeInsets))? = nil) {
        super.init({ .init(.equal, 0, insets: insets?() ?? .zero) }, viewBuilder: { viewBuilder() ?? UIView().userInteractionEnabled(false) })
    }
    
    public init() {
        super.init({ .init(.equal, 0) }, viewBuilder: { UIView().userInteractionEnabled(false) })
    }
}

public class Dynamic: InterfaceBuilderComponent {
    public init(_ viewBuilder: @escaping () -> (UIView), size: @escaping ()->(InterfaceBuilder.LayoutInstruction)) {
        super.init(size, viewBuilder: viewBuilder)
    }
}

public class Split: InterfaceBuilderComponent {
    let directionHandler: ()->(InterfaceBuilder.Direction)
    let modifierHandler: ((SplitView)->())?
    
    public init(directionHandler: @escaping ()->(InterfaceBuilder.Direction), @InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ splitView: SplitView)->())? = nil) {
        self.directionHandler = directionHandler
        self.modifierHandler = modifier
        
        super.init({ size?() ?? .init(.equal, 0) }, viewBuilder: { UIView() })
        
        self.subComponents = builder()
    }
}

public class VSplit: Split {
    public init(@InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ splitView: SplitView)->())? = nil) {
        super.init(directionHandler: { .vertical }, builder: builder, size: size, modifier: modifier)
    }
}

public class HSplit: Split {
    public init(@InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ splitView: SplitView)->())? = nil) {
        super.init(directionHandler: { .horizontal }, builder: builder, size: size, modifier: modifier)
    }
}

public class Scroll: InterfaceBuilderComponent {
    let directionHandler: ()->(InterfaceBuilder.Direction)
    let modifierHandler: ((ScrollingView)->())?
    
    public init(directionHandler: @escaping ()->(InterfaceBuilder.Direction), @InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ scrollingView: ScrollingView)->())? = nil) {
        self.directionHandler = directionHandler
        self.modifierHandler = modifier
        
        super.init({ size?() ?? .init(.equal, 0) }, viewBuilder: { UIView() })
        
        self.subComponents = builder()
    }
}

public class VScroll: Scroll {
    public init(@InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ scrollingView: ScrollingView)->())? = nil) {
        super.init(directionHandler: { .vertical }, builder: builder, size: size, modifier: modifier)
    }
}

public class HScroll: Scroll {
    public init(@InterfaceBuilder.Builder builder: ()->[InterfaceBuilderComponent], size: (()->(InterfaceBuilder.LayoutInstruction))? = nil, modifier: ((_ scrollingView: ScrollingView)->())? = nil) {
        super.init(directionHandler: { .horizontal }, builder: builder, size: size, modifier: modifier)
    }
}

extension UIView {
    func subviews<T:UIView>(of type:T.Type) -> [T] {
        var result = self.subviews.compactMap {$0 as? T}
        for sub in self.subviews {
            result.append(contentsOf: sub.subviews(of: type))
        }
        return result
    }
}

#endif
