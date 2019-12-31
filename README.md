# BaseComponents

## Introduction

BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensivly in production, the time has come to transition to Swift.

**Important Note: API for Components is currently unstable.**

### Components Roadmap
- [x] DataRender
- [x] SplitView
- [x] KeyboardManager
- [x] ControlClosures
- [x] NetFetch
- [x] Conveniences
- [ ] ActionSheet
- [ ] ProgressIndicator

## Components

### DataRender

DataRender abstracts all the tedious protocols one would need to implement when dealing with UICollectionView or UITableView. You decide whether to render a cell using a table or a grid, simply by choosing the appropriate superclass.

```
import UIKit

class Cell: UITableViewCell {
    override func bindObject(_ obj: AnyObject) {
        textLabel?.text = obj as? String
        detailTextLabel?.text = "Subtitle"
    }
}

class ViewController: UIViewController {
    
    lazy var dataRender: DataRender = {
        let configuration = DataRenderConfiguration(cellClass: Cell.self)
        let dataRender = DataRender(configuration: configuration)
        dataRender.rowHeight = 54
        view.addSubview(dataRender)
        return dataRender
    }()
    
    override func viewDidLoad() {
        title = "Data Render"
        
        let array = [["Hello","World"],["Swift 5.1"]]
        dataRender.renderArray(array as Array<AnyObject>)
        dataRender.onRefresh { (DataRender) in
            DataRender.refreshing = false
        }
        dataRender.onSelect { (DataRenderItemRenderProperties) in
            print("Selected:", DataRenderItemRenderProperties.object as! String)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if #available(iOS 11.0, *) {
            var insets = view.safeAreaInsets
            insets.left = 0
            insets.right = 0
            dataRender.insets = insets
        } else {
            // Fallback on earlier versions
        }
    }
}
```

### SplitView

AutoLayout is slow and tedious. UIStackedView is IDK. I've never used it. I've been writing all my layout in code since before it was released. SplitView is fast. You determine the direction and size of a view, either in % or px and SplitView will arrange everything else. Putting the sample code from below into a ViewController will allow you to observe SplitView's behaviour when switching between a vertical and horizontal layout, as well as when adding and removing views.

```
import UIKit

import BaseComponents

class SplitViewController: UIViewController {
    private var showHorizontal = true

    private lazy var label: UILabel = {
        var label = UILabel("Subview Counter, double tap anywhere to add views")
            .color(.text, .white)
            .color(.background, .black)
            .align(.center)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white

        SplitView(superview: view) { [unowned self] splitView in

            splitView.direction = .vertical
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)

            let containerSplit = SplitView(superSplitView: splitView, valueHandler: { (parentRect) -> SplitViewLayoutInstruction in
                return SplitViewLayoutInstruction(layoutType: .percentage, value: 100)
            }) { (splitView) in
                splitView.clipsToBounds = true
                splitView.addSubview(self.label, layoutType: .automatic)
            }
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .bottom)

            let tapGesture = UITapGestureRecognizer { (tapGesture) in
                if (tapGesture.state != .recognized) {
                    return
                }
                
                let splitView = tapGesture.view as! SplitView

                self.showHorizontal = !self.showHorizontal
                splitView.direction = self.showHorizontal ? .horizontal : .vertical

                let targetColor = self.showHorizontal ? UIColor.cyan : UIColor.magenta
                let view = UIView()
                view.backgroundColor = targetColor
                let targetFrame = splitView.subviews.last?.frame ?? CGRect.zero
                view.frame = targetFrame.offsetBy(dx: 0, dy: targetFrame.height)
                splitView.addSubview(view, layoutType: .equal)
                
                self.updateLabel(splitView: splitView)

                UIView.animate(withDuration: 0.3) {
                    splitView.invalidateLayout()
                }
            }
            tapGesture.numberOfTapsRequired = 2
            containerSplit.addGestureRecognizer(tapGesture)

            let longPress = UILongPressGestureRecognizer { (longPress) in
                if longPress.state != .recognized {
                    return
                }

                let splitView = longPress.view as! SplitView

                if splitView.subviews.count == 1 {
                    return
                }

                splitView.subviews.last?.removeFromSuperview()

                self.updateLabel(splitView: splitView)

                UIView.animate(withDuration: 0.3) {
                    splitView.invalidateLayout()
                }
            }
            containerSplit.addGestureRecognizer(longPress)
        }
    }

    func updateLabel(splitView: SplitView) {
        label.text = String(format: "%i Subviews", splitView.subviews.count)
    }
}

```

### KeyboardManager

KeyboardManager takes care of handeling a splitView's size when a keyboard appears. It calculates the overlap, animation duration and curve to do a correct resize when needed. Furthermore, when implementing the manager in all views containing a textField or a textView, query the keyboardVisible API if needed.

```
let splitView = SplitView(superview: view) { (splitView) in

    let textField = UITextField()
    textField.placeholder = "Tap Me"
    textField.textAlignment = .center
    splitView.addSubview(textField, layoutType: .fixed, value: 44.0)

    let subView = UIView()
    subView.backgroundColor = UIColor.green
    splitView.addSubview(subView, layoutType: .equal)

}
splitView.direction = .horizontal

KeyboardManager.manage(rootView: view, resizableChildSplitView: splitView)
```

### ControlClosures

An easy way to transform UIKit's legacy target-action pattern into modern closures, keeping code organised and consise. In addition to supporting UIControl subclasses like Buttons, TextFields, SegmentedControls, etc., GestureRecognizers are also implemented. As are popular delegate methods.

#### UISegmentedControl
```
let segmentedControl = UISegmentedControl(items: ["Hello","World","Swift"])
segmentedControl.selectedSegmentIndex = 0
segmentedControl.addAction(for: .valueChanged) { (control) in
    let segmentedControl = control as! UISegmentedControl    
    let item = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
    print(item)
}
splitView.addSubview(segmentedControl, layoutType: .fixed, value: 44.0)
```

#### UIGestureRecognizer
```
let tap = UITapGestureRecognizer { (recognizer) in
    if (recognizer.state == .recognized) {
        print("tapped twice")
    }
}
tap.numberOfTapsRequired = 2
subView.addGestureRecognizer(tap)
```

#### UITextField
```
let textField = UITextField()
textField.placeholder = "Tap Me"
textField.textAlignment = .center
textField.addAction(for: .editingChanged) { (control) in
    let textField = control as! UITextField
    print(textField.text!)
}
textField.shouldReturn { (textField) -> (Bool) in
    textField.resignFirstResponder()
    return true
}
splitView.addSubview(textField, layoutType: .fixed, value: 84.0)
```

### NetFetch
Abstracts network calls and keeps boilerplate code to a minimum. Easily convert the response into a string or object (using Codable)

```
import BaseComponents

struct Post: Codable {
    var userId: Int?
    var id: Int?
    var title: String?
    var body: String?
}

public class PostCell: UITableViewCell {
    public override func bindObject(_ obj: AnyObject) {
        let post = obj as! Post
        textLabel?.text = post.title
    }
}

public class NetFetchViewController: UIViewController {

    lazy var dataRender: DataRender = {
        let configuration = DataRenderConfiguration(cellClass: PostCell.self)
        let dataRender = DataRender(configuration: configuration)
        view.addSubview(dataRender)
        return dataRender
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        dataRender.onRefresh { [unowned self] (render) in
            let request = NetFetchRequest(urlString: "https://jsonplaceholder.typicode.com/posts") { (response) in
                self.dataRender.refreshing = false
                if let posts = response.bind([Post].self) {
                    self.dataRender.renderArray(posts as Array<AnyObject>)
                }
            }
            NetFetch.fetch(request)
        }
        dataRender.onSelect { (itemProperites) in
            let post = itemProperites.object as! Post
            print("Read:",post.body!)
        }
        dataRender.refreshing = true
    }

}
```

## Documentation

Documentation on the components is currently severly lacking. I'm working on improving it over time and pull requests are always welcome.
