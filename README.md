# Gate

[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/wadetregaskis/Gate.svg)]()
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwadetregaskis%2FGate%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/wadetregaskis/Gate)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fwadetregaskis%2FGate%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/wadetregaskis/Gate)
[![GitHub build results](https://github.com/wadetregaskis/Gate/actions/workflows/swift.yml/badge.svg)](https://github.com/wadetregaskis/Gate/actions/workflows/swift.yml)

Swift Concurrency 'gate' type to control forward progress of async tasks.

A gate can be opened and closed, and while closed it cannot be entered.  Async tasks can pass through the gate at appropriate point(s) in their execution (chosen by them, like checking for task cancellation).  If the gate is closed at the time they try to enter it, they will pause and wait for it to open before proceeding.

The gate can be opened or closed from any code (not just async contexts).

An example use is in SwiftUI where you have background task(s) (e.g. from the [`task`](https://developer.apple.com/documentation/swiftui/view/task(priority:_:)) view modifier) that you want to pause & resume in response to state changes:

```swift
struct Example: View {
    let frames: NSImage

    @Binding var animate: Bool {
        didSet {
            guard animate != oldValue else { return }

            if animate {
                self.animationGate.open()
            } else {
                self.animationGate.close()
            }
        }
    }
    
    @State private var animationGate = Gate(initiallyOpen: true)

    @State var currentFrameIndex: Int = 0
    
    var body: some View {
        Image(nsImage: self.frames[self.currentFrameIndex])
            .task {
                while !Task.isCancelled && let _ = try? await self.animationGate.enter() {
                    self.currentFrameIndex = (self.currentFrameIndex + 1) % self.frames.count
                    try? await Task.sleep(for: .seconds(1) / 60)
                }
            }
    }
}
```

## Thanks to…

This was inspired by (and based in part on) [Gwendal Roué](https://github.com/groue)'s [`Semaphore`](https://github.com/groue/Semaphore) package.
