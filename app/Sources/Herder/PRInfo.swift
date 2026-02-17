import Foundation

struct PRInfo: Equatable {
    let number: Int
    let url: String
    let headSha: String
    var checksTotal: Int
    var checksPassed: Int
    var checksFailed: Int
    var checksPending: Int
    
    var checksStatus: ChecksStatus {
        if checksTotal == 0 { return .none }
        if checksPending > 0 { return .running }
        if checksFailed > 0 { return .failed }
        return .passed
    }
    
    var checksSummary: String {
        switch checksStatus {
        case .none: return "No checks"
        case .running: return "Checks running... (\(checksPassed)/\(checksTotal))"
        case .failed: return "\(checksFailed) failed (\(checksPassed)/\(checksTotal) passed)"
        case .passed: return "All checks passed (\(checksTotal)/\(checksTotal))"
        }
    }
    
    var checksIcon: String {
        switch checksStatus {
        case .none: return "⚪"
        case .running: return "🔄"
        case .failed: return "❌"
        case .passed: return "✅"
        }
    }
    
    enum ChecksStatus: Equatable {
        case none, running, failed, passed
    }
}
