# BaseComponents

## Introduction

BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensivly in production, the time has come to transition to Swift.

Current Version: 0.8

**Important Note: API for Components is currently unstable.**

## Components

### Layout
#### ConditionalLayoutView  

<details>
<summary>Adjust the order, size and selection of subviews based on traitCollections, userInterfaceIdiom, screen size or any other condition. The actual layout is performed by a <code>SplitView</code> instance.</summary>

##### First Steps
Use ```addConditionalLayoutView()``` on any ```UIView```. To add conditional layout paths use ```addSubviews()``` and return ```true``` if a layout condition is met.
  
##### Code Sample
```
view.addConditionalLayoutView { (conditionalLayoutView) in
    let redView = UIView().color(.background, .red)
    let greenView = UIView().color(.background, .green)
    let blueView = UIView().color(.background, .blue)

    conditionalLayoutView.addSubviews({ (targetView) in
        targetView.addSubview(redView, layoutType: .equal)
        targetView.addSubview(greenView, layoutType: .equal)
        targetView.addSubview(blueView, layoutType: .equal)
    }) { (traitCollection) -> Bool in
        return traitCollection.horizontalSizeClass == .compact || traitCollection.horizontalSizeClass == .unspecified
    }

    conditionalLayoutView.addSubviews({ (targetView) in
        targetView.addSubview(greenView, layoutType: .percentage, value: 30, edgeInsets: .init(horizontal: 10))
        targetView.addSubview(redView, layoutType: .percentage, value: 70)
    }) { (traitCollection) -> Bool in
        return traitCollection.horizontalSizeClass == .regular
    }
}
```
---
</details>

#### ScrollingView
<details>
<summary>A subclass of <code>UIScrollView</code> to programatically layout  subviews in a given direction. The size of a subview along a horizontal or vertical direction can be determined automatically, e.g. <code>UILabel</code> , or by providing a fixed point value.</summary>

##### First Steps
Use ```addScrollingView()``` on any ```UIView```. 

##### Code Sample
```
view.addScrollingView { (scrollingView) in
    let label = UILabel("Large Title").size(.largeTitle, .bold)
    scrollingView.addSubview(label, edgeInsets: .init(horizontal: 15))

    let contentView = UIView().color(.background, .red)
    scrollingView.addSubview(contentView, layoutType: .fixed, value: 500)

    let footerView = UIView().color(.background, .blue)
    scrollingView.addSubview(footerView, layoutType: .fixed, value: 400)
}
```
---
</details>

#### SplitView
<details>
<summary>Divide the available width or height of a <code>UIView</code> amongst its subviews programmatically. </summary>

##### First Steps
Use ```addSplitView()``` on any ```UIView```. 

##### Code Sample
```
view.addSplitView { (splitView) in
    splitView.direction = .vertical
    
    splitView.addSubview(UIView().color(.background, .red), layoutType: .equal)
    splitView.addSubview(UIView().color(.background, .blue), layoutType: .equal)
    splitView.addSubview(UIView().color(.background, .green), layoutType: .fixed, value: 44)
}
```
</details>

---

### Storage
#### DiskData
<details>
<summary>Store and retrieve <code>Codable</code> objects, images, strings or data on the local file system. Has the ability to compress directories into a <code>.zip</code> archive.</summary>

##### First Steps
Create an instance of ```File``` or ```Directory```. Use ```save()``` to store data. 

##### Code Sample
```
let file = File(name: "helloWorld.txt")
file.save("Hello World!")
if let content = file.read(as: String.self) {
    print("File read", content)
}
file.delete()
```
---
</details>


#### CloudKitData
<details>
<summary>Store and retrieve objects conforming to <code>CloudKitDataCodable</code> in CloudKit.</summary>

##### First Steps 
Create a class conforming to the ```CloudKitDataCodable``` protocol. Create an instance of ```CloudKitDataProvider``` to perform CRUD operations on objects. When first trying to query objects, attributes will have to be adjusted in the CloudKit Dashboard. Check the error parameter in the ```completionHandler``` for more information. 

##### Code Sample
```
class Note: CloudKitDataCodable {
    var record: CloudKitRecord?
    func searchableKeywords() -> String? {
        return text
    }
    
    var text: String = ""
}

let dataProvider: CloudKitDataProvider = CloudKitDataProvider(.public)

let note = Note()
note.text = "Hello World"
dataProvider.save(note) { (storedNote, error) in
    if error != nil {
        print("Error storing note, try again?")
    }
    if let storedNote = storedNote {
        print("Note saved with id:", storedNote.record?.id)
    }
}
```
</details>

---

### Networking
#### NetFetch
<details>
<summary>Create network requests that can be sent immediately or added to a queue. Convert a response into an object using <code>bind()</code>.</summary>

##### First Steps
Create a `NetFetchRequest` and call `fetch()` 

##### Code Sample
```
NetFetchRequest(urlString: "https://twitter.com/mmackh") { (response) in
    print(response.string())
}.fetch()
```
</details>

---

### UIKit Helpers
#### ControlClosures
<details>
<summary>Adds closures for actions and delegates to <code>UIControl</code>, <code>UIGestureRecognizer</code>, <code>UIBarButtonItem</code>, <code>UITextField</code>, <code>UISearchBar</code>, etc. </summary>

##### First Steps
Create a `UIButton` and `addAction` for the desired control event.

##### Code Sample
```
let button = UIButton(title: "Tap me!", type: .system)
button.addAction(for: .touchUpInside) { (button) in
    print("Hello World!")
}
```
---
</details>

#### Conveniences
<details>
<summary>Chainable properties for popular <code>UIKit</code> methods. Populate an <code>UIImageView</code> with remote images. Introduces many other conveniences.</summary>

##### Code Sample
```
let label = UILabel("Hello World!")
    .size(.largeTitle, .bold)
    .color(.text, .blue)
    .color(.background, .white)
    .align(.center)
```
---
</details>

#### DataRender
<details>
<summary>Avoid writing boilerplate and common pitfalls when displaying data in a <code>UITableView</code> or <code>UICollectionView</code>.</summary>

##### First Steps
Create a `UITableViewCell` or `UICollectionView` subclass and overwrite `bindObject()`. Create an instance of `DataRenderConfiguration` and use it to init `DataRender`. Finally call `renderArray()`.

##### Code Sample
```
class Cell: UITableViewCell {
    override func bindObject(_ obj: AnyObject) {
        textLabel?.text = obj as? String
    }
}

lazy var dataRender: DataRender = {
    let config = DataRenderConfiguration(cellClass: Cell.self)
    let render = DataRender(configuration: config)
    render.adjustInsets = true
    render.onSelect { (itemRenderProperties) in
        print("Tapped:",itemRenderProperties.object)
    }
    view.addSubview(render)
    return render
}()

override func viewDidLoad() {
    super.viewDidLoad()

    dataRender.renderArray(["Hello","World"])
}
```
---
</details>

#### KeyboardManager
<details>
<summary>Repositions and resizes a <code>SplitView</code> instance to avoid overlapping issues based on the visibility of the keyboard.</summary>

##### Code Sample
```
KeyboardManager.manage(rootView: view, resizableChildSplitView: splitView)
```
</details>

---

### UIKit Reimplementations
- [x] PerformLabel

### UI Components
- [x] CountdownPickerView
- [x] NotificationView
- [x] ProgressView
- [x] SheetView

## Reasoning

1) BaseComponents allows you to write efficient & understandable code in a short amount of time by abstracting the tedious stuff. Implementing data sources or delegates takes a lot of boilerplate and often there's no need. Closures provide us with the ability to mentally connect the component with an action and is therefore the preferred way of passing values async in this library.

2) BaseComponents is flexible, meaning that you don't always have to use the components that come with it. Everything is built on top of UIKit, so mix and match if the project requires it. Don't be afraid of using UITableView instead of DataRender if you need the flexibility of tweaking every single value.

3) BaseComponents is evolving. Like Swift, this library will evolve over time to account for new improvements in the language and to cover more features. Documentation will improve and so will the understanding of what is needed next. SwiftUI is on the horizon as the next big thing, but in the mean time, I'm sure that UIKit will stick around. Particularly due to stability and predictability across iOS versions.

## Sample Code

![Screenshot](https://user-images.githubusercontent.com/948693/71639820-2a930100-2c7e-11ea-8700-24bb3c0b6318.png)

When looking at the sample code blow, we have a View Controller that supports:
- Dynamic Type
- Self-sizing cells
- Refresh control, reloading the data
- Layout fully in code
- Minimal state
- Easily understandable components
- Fetching JSON data and binding it to a model
- Responding to size of Keyboard

```
import UIKit

import BaseComponents

struct Post: Codable {
    var userId: Int?
    var id: Int?
    var title: String?
    var body: String?
}

public class PostCell: UITableViewCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel?.lines(0)
            .size(.body, .bold)
        detailTextLabel?.lines(3)
            .size(.subheadline)
            .color(.text, .black)
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func bindObject(_ obj: AnyObject) {
        let post = obj as! Post
        let title = post.title!
        let subtitle = "Posted by News"
        let headline = title.appendingFormat("\n%@", subtitle)
        let range = (headline as NSString).range(of: subtitle)
        let attributedString = NSMutableAttributedString(string: headline)
        attributedString.addAttribute(.font, value: UIFont.size(.footnote), range: range)
        attributedString.addAttribute(.foregroundColor, value: UIColor.lightGray, range: range)
        textLabel?.attributedText = attributedString
        detailTextLabel?.text = post.body?.replacingOccurrences(of: "\n", with: "")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

public class KeybardViewController: UIViewController {

    lazy var dataRender: DataRender = {
        let configuration = DataRenderConfiguration(cellClass: PostCell.self)
        let dataRender = DataRender(configuration: configuration)
        dataRender.rowHeight = UITableView.automaticDimension
        dataRender.clipsToBounds = true
        return dataRender
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Welcome to BaseComponents"
        
        view.backgroundColor = UIColor.white

        let splitView = view.addSplitView { (splitView) in
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)
            
            let segmentedControl = UISegmentedControl(items: ["Hello","World","Swift"])
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addAction(for: .valueChanged) { (segmentedControl) in
                let item = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
                print(item)
            }
            splitView.addSubview(segmentedControl, layoutType: .fixed, value: 44.0, edgeInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        
            dataRender.onRefresh { [weak self] (render) in
                let request = NetFetchRequest(urlString: "https://jsonplaceholder.typicode.com/posts") { (response) in
                    self?.dataRender.refreshing = false
                    self?.view.showProgressView(false)
                    if let posts = response.bind([Post].self) {
                        NotificationView.show(.success, in: self?.dataRender, for: 2, message: "Updated to the latest News", position: .bottom)
                        self?.dataRender.renderArray(posts)
                    }
                    else {
                        NotificationView.show(.error, in: self?.view, for: 2, message: "Check your Network Connection")
                    }
                }
                NetFetch.fetch(request)
            }
            dataRender.onSelect { (itemProperites) in
                let post = itemProperites.object as! Post
                print("Read:",post.body!)
            }
            splitView.addSubview(dataRender, layoutType: .percentage, value: 100)
            dataRender.refreshing = true
            
            splitView.addSubview(UIView().color(.background, .init(white: 0.89, alpha: 1)), layoutType: .fixed, value: 0.5)
            
            splitView.addSplitView(configurationHandler: { (splitView) in
                splitView.direction = .horizontal
                
                let valueLabel = PerformLabel("0.00")
                    .size(.body, [.monoSpaceDigit,.bold])
                    .lines(0)
                
                let slider = UISlider()
                    .addAction(for: .valueChanged) { (slider) in
                        valueLabel.text = NSString(format: "%.02f", slider.value) as String
                }
                splitView.addSubview(slider, layoutType: .percentage, value: 100, edgeInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
                splitView.addSubview(valueLabel, layoutType: .automatic, edgeInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
            }) { (parentRect) -> SplitViewLayoutInstruction in
                return .init(layoutType: .fixed, value: 44)
            }
            
            splitView.addSubview(UIView().color(.background, .init(white: 0.89, alpha: 1)), layoutType: .fixed, value: 0.5)
            
            let textField = UITextField(placeholder: "Enter a new Title")
                .align(.center)
                .size(.body)
                .addAction(for: .editingChanged) { (textField) in
                    print(textField.text!)
                }
                .addAction(for: .editingDidEnd, { (textField) in
                    self.title = textField.text
                })
                .shouldReturn { (textField) -> (Bool) in
                    textField.resignFirstResponder()
                    return true
                }
            splitView.addSubview(textField, layoutType: .fixed, value: 84.0)
            
            let paddingView = UIView()
            splitView.addSubview(paddingView) { (parentRect) -> SplitViewLayoutInstruction in
                var bottomInset: CGFloat = 0.0;
                if #available(iOS 11.0, *) {
                    bottomInset = self.view.safeAreaInsets.bottom
                }
                if KeyboardManager.visibility == .visible {
                    bottomInset = 0
                }
                return SplitViewLayoutInstruction(layoutType: .fixed, value: bottomInset)
            }
            
        }
        splitView.direction = .vertical
        
        KeyboardManager.manage(rootView: view, resizableChildSplitView: splitView)
        
        view.showProgressView(true, type: .appleStyle)
    }
    
}

```

## Documentation

Documentation on the components is currently lacking. I'm working on improving it over time and pull requests are always welcome.


