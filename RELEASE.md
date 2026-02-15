# Release Guide

This document describes how to create a new release of Herd.

## Prerequisites

1. **GitHub Access Token** for the Homebrew tap repo
   - Create a token at https://github.com/settings/tokens
   - Permissions needed: `repo` (full control)
   - Add as secret `TAP_GITHUB_TOKEN` in the Herd repository settings:
     - Go to https://github.com/Qouter/herd/settings/secrets/actions
     - Click "New repository secret"
     - Name: `TAP_GITHUB_TOKEN`
     - Value: your GitHub token

2. **Create the Homebrew tap repository**
   ```bash
   # Create repo at https://github.com/Qouter/homebrew-tap
   # Then push the tap files:
   cd /data/.openclaw/workspace/homebrew-tap
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/Qouter/homebrew-tap.git
   git push -u origin main
   ```

## Release Process

### 1. Update version and changelog

```bash
cd /data/.openclaw/workspace/herd

# Update CHANGELOG.md with release notes
# - Move items from [Unreleased] to [X.Y.Z]
# - Add release date
# - Update version links at bottom

# Update version in app/Package.swift if needed
```

### 2. Commit changes

```bash
git add CHANGELOG.md
git commit -m "chore: prepare v0.1.0 release"
git push origin main
```

### 3. Create and push tag

```bash
# Create tag
git tag v0.1.0

# Push tag (this triggers the GitHub Actions workflow)
git push origin v0.1.0
```

### 4. Monitor the release

1. Go to https://github.com/Qouter/herd/actions
2. Watch the "Release" workflow run
3. Verify:
   - ✅ Universal binary builds successfully
   - ✅ .app bundle is created
   - ✅ ZIP archive is created with app + hooks
   - ✅ SHA256 is generated
   - ✅ GitHub Release is created
   - ✅ Homebrew tap is updated (if TAP_GITHUB_TOKEN is set)

### 5. Verify Homebrew installation

```bash
# Update tap
brew update

# Install/upgrade
brew install herd
# or
brew upgrade herd

# Test
herd status
herd open
```

## What happens automatically

When you push a tag `vX.Y.Z`:

1. **GitHub Actions** runs on `macos-14` runner
2. Builds universal binary (arm64 + x86_64)
3. Creates `Herd.app` bundle
4. Code signs with ad-hoc signature
5. Packages `Herd.app` + `hooks/` into `Herd-macos-universal.zip`
6. Generates SHA256 checksum
7. Creates GitHub Release with:
   - ZIP file
   - SHA256 file
   - Auto-generated release notes
8. **Clones `homebrew-tap` repo** and updates:
   - `version` in `Formula/herd.rb`
   - `url` with new tag
   - `sha256` with computed checksum
9. Commits and pushes to `homebrew-tap`

## Manual Formula Update

If the automated update fails (e.g., TAP_GITHUB_TOKEN not set):

```bash
cd /data/.openclaw/workspace/homebrew-tap

# Get SHA256 from release page or compute it:
curl -L https://github.com/Qouter/herd/releases/download/v0.1.0/Herd-macos-universal.zip \
  | shasum -a 256

# Edit Formula/herd.rb:
# - Update version "0.1.0"
# - Update url with new tag
# - Update sha256 with computed hash

git add Formula/herd.rb
git commit -m "herd: update to 0.1.0"
git push origin main
```

## Testing a Release Locally

Before tagging, you can test the build process:

```bash
cd /data/.openclaw/workspace/herd

# Build locally
./build.sh

# Test the app
open build/Herd.app

# Test hook installation
./install.sh

# Start a Claude Code session and verify Herd updates
```

## Troubleshooting

### Build fails on GitHub Actions

- Check Swift version compatibility
- Verify Xcode version on `macos-14` runner
- Review build logs at https://github.com/Qouter/herd/actions

### Homebrew tap not updated

- Verify `TAP_GITHUB_TOKEN` secret is set
- Check token permissions (needs `repo` access)
- Manually update the formula (see above)

### Formula installation fails

- Test the formula locally:
  ```bash
  brew install --build-from-source ./Formula/herd.rb
  ```
- Check SHA256 matches the release ZIP
- Verify ZIP structure contains `Herd-release/Herd.app` and `Herd-release/hooks/`

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features, backwards compatible
- **PATCH** (0.1.1): Bug fixes, backwards compatible

Examples:
- `v0.1.0` - Initial release
- `v0.2.0` - Add notification sounds
- `v0.2.1` - Fix menu bar refresh bug
- `v1.0.0` - Stable API, production ready
