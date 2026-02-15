# Changelog

All notable changes to Herd will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - TBD

### Added
- Initial release
- Menu bar icon showing active Claude Code agents
- Real-time counter for active and waiting agents
- Click-to-open terminal for each agent
- Display last message from idle agents
- Claude Code hooks integration (SessionStart, SessionEnd, Stop, UserPromptSubmit)
- Homebrew tap distribution (`brew install herd`)
- CLI wrapper with `install-hooks`, `uninstall-hooks`, `open`, and `status` commands
- Universal binary support (Apple Silicon + Intel)
- Auto-cleanup of stale sessions after 5 minutes

### Technical
- Swift + SwiftUI menu bar app
- Unix socket communication (/tmp/herd.sock)
- Async bash hooks using jq and socat
- GitHub Actions CI/CD for releases
- Automatic Homebrew formula updates

[Unreleased]: https://github.com/Qouter/herd/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Qouter/herd/releases/tag/v0.1.0
