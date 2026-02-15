import AppKit
import SwiftUI

@main
struct HerdApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    var socketServer: SocketServer?
    @MainActor var agentStore = AgentStore()
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        socketServer = SocketServer(store: agentStore)
        Task {
            await socketServer?.start()
        }
        
        menuBarController = MenuBarController(store: agentStore)
        
        print("Herd started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Task {
            await socketServer?.stop()
        }
    }
}
