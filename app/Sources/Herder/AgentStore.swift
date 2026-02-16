import Foundation
import Combine

class AgentStore: ObservableObject, @unchecked Sendable {
    @Published var sessions: [AgentSession] = []
    
    private var timeoutTimer: Timer?
    private let idleSessionTimeout: TimeInterval = 30 * 60  // 30 min for idle sessions
    private let workingSessionTimeout: TimeInterval = 4 * 60 * 60  // 4 hours for working sessions
    
    init() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.cleanupStaleSessions() }
        }
    }
    
    deinit { timeoutTimer?.invalidate() }
    
    var totalCount: Int { sessions.count }
    var idleCount: Int { sessions.filter { $0.status == .idle }.count }
    
    func addSession(id: String, cwd: String, tty: String? = nil, terminalPid: String? = nil, terminalApp: String? = nil) {
        guard !sessions.contains(where: { $0.id == id }) else { return }
        sessions.append(AgentSession(id: id, cwd: cwd, status: .working, tty: tty, terminalPid: terminalPid, terminalApp: terminalApp))
    }
    
    func removeSession(id: String) {
        sessions.removeAll { $0.id == id }
    }
    
    func updateSessionStatus(id: String, status: AgentSession.Status, lastMessage: String? = nil) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].status = status
            sessions[index].lastActivity = Date()
            if let message = lastMessage { sessions[index].lastMessage = message }
        }
    }
    
    func setTranscriptPath(id: String, path: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].transcriptPath = path
        }
    }
    
    private func cleanupStaleSessions() {
        let now = Date()
        sessions.removeAll {
            let elapsed = now.timeIntervalSince($0.lastActivity)
            switch $0.status {
            case .working: return elapsed > workingSessionTimeout
            case .idle: return elapsed > idleSessionTimeout
            }
        }
    }
}
