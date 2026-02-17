import SwiftUI

/// Vista de una fila individual de agente
struct AgentRowView: View {
    let session: AgentSession
    @State private var isPulsing = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 20))
                .frame(width: 24)
                .opacity(session.status == .working ? (isPulsing ? 0.3 : 1.0) : 1.0)
                .animation(session.status == .working ?
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                    value: isPulsing)
                .onAppear { isPulsing = true }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // CWD
                Text(session.shortCwd)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                
                // Git branch
                if let branch = session.gitBranch {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text(branch)
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                
                // PR checks status
                if let pr = session.prInfo {
                    HStack(spacing: 4) {
                        Text(pr.checksIcon)
                            .font(.caption2)
                        Text(pr.checksSummary)
                            .font(.caption)
                    }
                    .foregroundColor(checksColor(pr.checksStatus))
                }
                
                // Status text or last message
                if let lastMessage = session.lastMessage, !lastMessage.isEmpty {
                    Text(lastMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Elapsed time
                Text(session.elapsedString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 6) {
                // Open terminal button
                Button(action: {
                    TerminalLauncher.open(session: session)
                }) {
                    Text("Open")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                // PR button (only if PR exists)
                if let pr = session.prInfo {
                    Button(action: {
                        if let url = URL(string: pr.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 3) {
                            Text("PR #\(pr.number)")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8))
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func checksColor(_ status: PRInfo.ChecksStatus) -> Color {
        switch status {
        case .none: return .secondary
        case .running: return .blue
        case .failed: return .red
        case .passed: return .green
        }
    }
    
    private var statusIcon: String {
        switch session.status {
        case .working: return "circle.fill"
        case .idle: return "pause.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch session.status {
        case .working: return .green
        case .idle: return .orange
        }
    }
    
    private var statusText: String {
        switch session.status {
        case .working: return "Working..."
        case .idle: return "Waiting for you"
        }
    }
}
