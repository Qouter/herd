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
    var prMonitor: PRMonitor?
    let agentStore = AgentStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        socketServer = SocketServer(store: agentStore)
        socketServer?.start()
        
        transcriptMonitor = TranscriptMonitor(store: agentStore)
        transcriptMonitor?.start()
        
        prMonitor = PRMonitor(store: agentStore)
        prMonitor?.start()
        
        menuBarController = MenuBarController(store: agentStore)
        
        print("Herder started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        prMonitor?.stop()
        transcriptMonitor?.stop()
        socketServer?.stop()
    }
}
