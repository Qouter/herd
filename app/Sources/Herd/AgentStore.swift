import Foundation
import Combine

/// Store global de sesiones de agentes
@MainActor
class AgentStore: ObservableObject {
    @Published var sessions: [AgentSession] = []
    
    private var timeoutTimer: Timer?
    private let sessionTimeout: TimeInterval = 5 * 60 // 5 minutos
    
    init() {
        // Timer para limpiar sesiones muertas
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupStaleSessions()
            }
        }
    }
    
    deinit {
        timeoutTimer?.invalidate()
    }
    
    // MARK: - Computed Properties
    
    var totalCount: Int {
        sessions.count
    }
    
    var idleCount: Int {
        sessions.filter { $0.status == .idle }.count
    }
    
    var workingCount: Int {
        sessions.filter { $0.status == .working }.count
    }
    
    // MARK: - Session Management
    
    func addSession(id: String, cwd: String) {
        // Evitar duplicados
        if sessions.contains(where: { $0.id == id }) {
            return
        }
        
        let session = AgentSession(id: id, cwd: cwd, status: .working)
        sessions.append(session)
        print("Added session: \(id) at \(cwd)")
    }
    
    func removeSession(id: String) {
        sessions.removeAll { $0.id == id }
        print("Removed session: \(id)")
    }
    
    func updateSessionStatus(id: String, status: AgentSession.Status, lastMessage: String? = nil) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].status = status
            sessions[index].lastActivity = Date()
            if let message = lastMessage {
                sessions[index].lastMessage = message
            }
            print("Updated session \(id) status: \(status)")
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupStaleSessions() {
        let now = Date()
        let staleIds = sessions.filter { session in
            now.timeIntervalSince(session.lastActivity) > sessionTimeout
        }.map(\.id)
        
        for id in staleIds {
            removeSession(id: id)
            print("Removed stale session: \(id)")
        }
    }
}
