import SwiftUI

@main
struct MemoViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let memosPath = homeDir.appendingPathComponent(".openclaw/workspace/memos")
            let archivePath = homeDir.appendingPathComponent(".openclaw/workspace/memos-archive")

            ContentView(memosPath: memosPath, archivePath: archivePath)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        if let frame = UserDefaults.standard.value(forKey: "windowFrame") as? String {
                            let components = frame.split(separator: ",").compactMap { Double($0) }
                            if components.count == 4 {
                                window.setFrame(
                                    NSRect(x: components[0], y: components[1], width: components[2], height: components[3]),
                                    display: true
                                )
                            }
                        } else {
                            window.setFrame(NSRect(x: 0, y: 0, width: 800, height: 600), display: true)
                        }

                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowResizabilityContentSize()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            let frame = window.frame
            let frameString = "\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height)"
            UserDefaults.standard.set(frameString, forKey: "windowFrame")
        }
    }
}
