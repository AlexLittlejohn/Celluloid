# Celluloid

A view that allows you to control many aspects of the iOS camera.

---

###Installation & Requirements

This project requires Xcode 7 to run and compiles with swift 2.2

###Usage

```swift
import Celluloid

class ViewController: UIViewController {

    let cameraView = CelluloidView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cameraView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        do {
            try cameraView.startCamera() { success in }
        } catch {

        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cameraView.frame = view.bounds
    }
}
```

##License

Celluloid is available under the MIT license. See the LICENSE file for more info.
