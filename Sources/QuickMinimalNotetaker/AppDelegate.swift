import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hostingController = NSHostingController(rootView: ContentView())

        // Phone-sized window (roughly iPhone screen proportions), floats alongside other apps.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // Off: it fights with in-content drag-to-reorder. The window still drags
        // by its title bar strip (the top ~28pt), which is unaffected by this.
        window.isMovableByWindowBackground = false
        window.minSize = NSSize(width: 300, height: 400)
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
