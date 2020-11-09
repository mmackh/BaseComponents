# BaseComponents

## Introduction

BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensively in production, the time has come to transition to Swift.

Current Version: 1.0

## Components

### Layout
#### ConditionalLayoutView  

<details>
<summary>Adjust the order, size and selection of subviews based on traitCollections, userInterfaceIdiom, screen size or any other condition. The actual layout is performed by a <code>SplitView</code> instance.</summary>

##### First Steps
Use ```addConditionalLayoutView()``` on any ```UIView```. To add conditional layout paths use ```addSubviews()``` and return ```true``` if a layout condition is met.
  
##### Code Sample
```swift
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
```swift
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
```swift
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
```swift
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
Create a class conforming to the ```CloudKitDataCodable``` protocol. Create an instance of ```CloudKitDataProvider``` to perform CRUD operations on objects. When first trying to query objects, attributes will have to be adjusted in the CloudKit Dashboard. **Check the error parameter in the ```completionHandler``` for more information.**

##### Code Sample
```swift
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
```swift
NetFetchRequest(urlString: "https://twitter.com/mmackh") { (response) in
    print(response.string())
}.fetch()
```
</details>

---

### Dates & Time
#### TimeKeep
<details>
<summary>Adds conveniece methods to Swift's <code>Date</code> in order to calculate time spans, add or remove time units and get formatted strings.</summary>

##### First Steps
Create a `Date` and call `remove()`  or `add()` to modify using time units. Use `format()` to retrieve a string.

##### Code Sample
```swift
let date = Date()
print(date.remove(.month(1)).dates(until: date))
print("In 7 seconds", date.add(.second(7)).format())

let past = date.remove(.year(5)).startOf(.month)
print(past.format(string: "EEEE, YYYY-MM-dd"))
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
```swift
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
```swift
let label = UILabel("Hello World!")
    .size(.largeTitle, .bold)
    .color(.text, .blue)
    .color(.background, .white)
    .align(.center)
```
---
</details>

#### Geometry
<details>
<summary>Adds shortcuts to UIView, CGRect & UIEdgeInsets for manually managing frames.</summary>

##### Code Sample
```swift
let label = UILabel("Hello World!")
label.x = 10
label.y = 10
label.width = 200
label.height = 300

let view = UIView().width(50).height(50)
```
---
</details>

#### DataRender
<details>
<summary>Avoid writing boilerplate and common pitfalls when displaying data in a <code>UITableView</code> or <code>UICollectionView</code>. Supports fast and accurate automatic cell sizing with <code>ScrollingView</code>. </summary>

##### First Steps
Create a `UITableViewCell` or `UICollectionView` subclass and overwrite `bindObject()`. Create an instance of `DataRenderConfiguration` and use it to init `DataRender`. Finally call `renderArray()`.

##### Automatic Height for `UITableViewCell`
- Implement `itemAutomaticRowHeightCacheKeyHandler()` on your `DataRender` instance
- Add a `ScrollingView` as the first subview of the cell's `contentView`, i.e. `contentView.addScrollingView()`.
- To accurately measure the required height, `safeAreaInsets` and `layoutMargins` for every object in advance, an invisible child `UITableView` is added the provided `UITableViewCell` subclass. To recalculate a height based on new information or user action `recalculateAutomaticHeight()`


##### Code Sample
```swift
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
<summary>Repositions and resizes a <code>SplitView</code> instance to avoid overlapping issues caused by the keyboard.</summary>

##### Code Sample
```swift
KeyboardManager.manage(rootView: view, resizableChildSplitView: splitView)
```
</details>

---

### UIKit Reimplementations
#### PerformLabel
<details>
<summary>A faster label useful for auto sizing cells. Animates smoothly by streching. Even though a `numberOfLines`  API is defined, the current implementation will disregard this setting.</summary>

##### Code Sample
```swift
lazy var contentLabel: PerformLabel = {
    return PerformLabel()
        .align(.left)
        .color(.background, .black)
        .color(.text, .white)
        .size(.body)
}()
```
</details>

---

### UI Components

#### CountdownPickerView
<details>
<summary>Display a countdown picker with seconds that is very close to the native iOS Timer app. All labels will be translated automatically depending on the phone's locale. A maximum width prevents this view from overflowing.</summary>

##### First Steps
Create a new `CountdownPickerView` instance and add it to a target view.

##### Code Sample
```swift
let datePicker = CountdownPickerView()
datePicker.isEndless = true
datePicker.countDownDuration = TimeInterval(3 * 60 * 60 + 2 * 60 + 1)
view.addSubview(datePicker)
```
---
</details>

#### NotificationView
<details>
<summary>Display a short message with an icon to inform about a success or error case. The message will dismiss itself after a certain duration or with a swipe.</summary>

##### Important Notes
Only show short messages. A message with a required width less than the width of the superview's frame will only take up the minimum required space.

##### Code Sample
```swift
NotificationView.show(.success, in: self.navigationController?.view, for: 2, message: "Document Uploaded")
```
---
</details>

#### ProgressView
<details>
<summary>Able to display a progress spinner in different styles to indicate a loading state. Blocks interaction of the underlying UI when visible.</summary>

##### First Steps
Use the convenience method `showProgressView()` on any `UIView` to display a loading state.

##### Code Sample
```swift
view.showProgressView(true, type: .appleStyle)
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    view.showProgressView(false)
}
```
---
</details>

#### SheetView
<details>
<summary>Display a customisable sheet similar to `UIAlertController.Style.actionSheet`, that is both more flexible and easier to use.</summary>

##### Structure
 A `SheetView` instance can be constructed using `components`. A component provides a contentView and a given height (height can either be static or dynamic, use `invalidateLayout()` to recalculate). Premade `SheetViewComponent` include:
 ```
    - SheetViewPullTab: A pill view indicating that the sheet can be interactively dismissed  
    - SheetViewNavigationBar: A simple compact `UINavigationBar` replica   
    - SheetViewButton: A button module that highlights and acts like an UIAlertController button   
    - SheetViewSeparator: A hairline divider used to separate components   
    - SheetViewSpace: Divides components into sections   
    - SheetViewCustomView: A base class to use for adding custom UI to SheetView   
 ```
 Each section (divided by SheetViewSpace), has a background which can be styled using `sectionBackgroundViewProvider()`. To further style the sheet, use `maximumWidth`, `adjustToSafeAreaInsets` or `horizontalInset`. After components have been added and the sheet is styled, display it using `show(in view: UIView?)`.    

##### Code Sample
```swift
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
</details>

## Reasoning

1) BaseComponents allows you to write efficient & understandable code in a short amount of time by abstracting the tedious stuff. Implementing data sources or delegates takes a lot of boilerplate and often there's no need. Closures provide us with the ability to mentally connect the component with an action and is therefore the preferred way of passing values async in this library.

2) BaseComponents is flexible, meaning that you don't always have to use the components that come with it. Everything is built on top of UIKit, so mix and match if the project requires it. Don't be afraid of using UITableView instead of DataRender if you need the flexibility of tweaking every single value.

3) BaseComponents is evolving. Like Swift, this library will evolve over time to account for new improvements in the language and to cover more features. Documentation will improve and so will the understanding of what is needed next. SwiftUI is on the horizon as the next big thing, but in the mean time, I'm sure that UIKit will stick around. Particularly due to stability and predictability across iOS versions.

## Sample Code

![Screenshot](https://user-images.githubusercontent.com/948693/71639820-2a930100-2c7e-11ea-8700-24bb3c0b6318.png)

When looking at the sample code, we have a View Controller that supports:
- Dynamic Type
- Self-sizing cells
- Refresh control, reloading the data
- Layout fully in code
- Minimal state
- Easily understandable components
- Fetching JSON data and binding it to a model
- Responding to size of Keyboard

Check out the [complete code for the screenshot here](https://github.com/mmackh/BaseComponents/wiki/Sample-Code) or others in the [wiki](https://github.com/mmackh/BaseComponents/wiki).

## Documentation

Documentation on the components is improving and pull requests are always welcome.




