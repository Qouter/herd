import Foundation

/// Polls GitHub API to get PR status and CI checks for each agent's branch.
class PRMonitor {
    private let store: AgentStore
    private var timer: Timer?
    private let pollInterval: TimeInterval = 20
    private var lastCheckedBranch: [String: String] = [:]  // sessionId -> branch
    private let session = URLSession.shared
    private var githubToken: String?
    
    init(store: AgentStore) {
        self.store = store
        self.githubToken = loadGitHubToken()
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        // Initial poll after 2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.poll()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func poll() {
        let sessions = store.sessions
        
        for session in sessions {
            guard let branch = session.gitBranch,
                  branch != "main" && branch != "master",
                  let repo = session.gitRepo else { continue }
            
            // Skip if branch hasn't changed since last check
            if lastCheckedBranch[session.id] == branch && session.prInfo != nil {
                // Still re-check to update CI status
                fetchChecks(sessionId: session.id, owner: repo.owner, repo: repo.repo, prInfo: session.prInfo!)
                continue
            }
            
            lastCheckedBranch[session.id] = branch
            fetchPR(sessionId: session.id, owner: repo.owner, repo: repo.repo, branch: branch)
        }
    }
    
    private func fetchPR(sessionId: String, owner: String, repo: String, branch: String) {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/pulls?head=\(owner):\(branch)&state=open&per_page=1"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        if let token = githubToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 10
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let prs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let pr = prs.first else {
                // No PR found — clear PR info
                DispatchQueue.main.async {
                    self?.store.setPRInfo(id: sessionId, prInfo: nil)
                }
                return
            }
            
            guard let number = pr["number"] as? Int,
                  let htmlUrl = pr["html_url"] as? String,
                  let head = pr["head"] as? [String: Any],
                  let sha = head["sha"] as? String else { return }
            
            let prInfo = PRInfo(
                number: number,
                url: htmlUrl,
                headSha: sha,
                checksTotal: 0,
                checksPassed: 0,
                checksFailed: 0,
                checksPending: 0
            )
            
            DispatchQueue.main.async {
                self?.store.setPRInfo(id: sessionId, prInfo: prInfo)
            }
            
            // Now fetch checks
            self?.fetchChecks(sessionId: sessionId, owner: owner, repo: repo, prInfo: prInfo)
            
        }.resume()
    }
    
    private func fetchChecks(sessionId: String, owner: String, repo: String, prInfo: PRInfo) {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/commits/\(prInfo.headSha)/check-runs"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        if let token = githubToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 10
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let checkRuns = json["check_runs"] as? [[String: Any]] else { return }
            
            var total = checkRuns.count
            var passed = 0
            var failed = 0
            var pending = 0
            
            for check in checkRuns {
                let status = check["status"] as? String ?? ""
                let conclusion = check["conclusion"] as? String ?? ""
                
                if status == "completed" {
                    if conclusion == "success" || conclusion == "skipped" || conclusion == "neutral" {
                        passed += 1
                    } else {
                        failed += 1
                    }
                } else {
                    pending += 1
                }
            }
            
            var updated = prInfo
            updated.checksTotal = total
            updated.checksPassed = passed
            updated.checksFailed = failed
            updated.checksPending = pending
            
            DispatchQueue.main.async {
                self?.store.setPRInfo(id: sessionId, prInfo: updated)
            }
            
        }.resume()
    }
    
    /// Try to load GitHub token from gh CLI, config file, or environment
    private func loadGitHubToken() -> String? {
        // 1. Environment variable
        if let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !token.isEmpty {
            return token
        }
        
        // 2. gh auth token (reads from keyring)
        if let token = runCommand("/usr/local/bin/gh", args: ["auth", "token"]) ?? runCommand("/opt/homebrew/bin/gh", args: ["auth", "token"]) {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        
        // 3. gh CLI config file (fallback for non-keyring setups)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let ghConfigPath = "\(home)/.config/gh/hosts.yml"
        if let content = try? String(contentsOfFile: ghConfigPath, encoding: .utf8) {
            for line in content.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("oauth_token:") {
                    let token = trimmed.replacingOccurrences(of: "oauth_token:", with: "").trimmingCharacters(in: .whitespaces)
                    if !token.isEmpty { return token }
                }
            }
        }
        
        return nil
    }
    
    private func runCommand(_ path: String, args: [String]) -> String? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            }
        } catch {}
        return nil
    }
}
