import AppKit
import SwiftUI

@main
struct HerderApp: App {
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
    var transcriptMonitor: TranscriptMonitor?
    let agentStore = AgentStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        socketServer = SocketServer(store: agentStore)
        socketServer?.start()
        
        transcriptMonitor = TranscriptMonitor(store: agentStore)
        transcriptMonitor?.start()
        
        menuBarController = MenuBarController(store: agentStore)
        
        print("Herder started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        transcriptMonitor?.stop()
        socketServer?.stop()
    }
}
