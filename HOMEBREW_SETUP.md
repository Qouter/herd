# Homebrew Distribution Setup - Complete ✅

This document summarizes the Homebrew distribution setup for Herd.

## 📁 Files Created

### In `/data/.openclaw/workspace/herd/` (this repo)

1. **`.github/workflows/release.yml`** - GitHub Actions workflow
   - Triggers on `v*` tags
   - Builds universal binary (arm64 + x86_64)
   - Creates .app bundle + hooks ZIP
   - Publishes GitHub Release
   - Auto-updates Homebrew tap

2. **`CHANGELOG.md`** - Release notes tracking

3. **`RELEASE.md`** - Complete release guide for maintainers

4. **`pre-release-check.sh`** - Verification script before releasing

5. **`HOMEBREW_SETUP.md`** - This file

6. **Updated `README.md`**:
   - Added Homebrew installation as primary method
   - Kept manual installation as alternative
   - Updated roadmap (Homebrew tap ✅)
   - Updated uninstall section

### In `/data/.openclaw/workspace/homebrew-tap/` (new repo)

1. **`Formula/herd.rb`** - Complete Homebrew formula with:
   - Auto-installs hooks on `brew install`
   - CLI wrapper: `herd open|install-hooks|uninstall-hooks|status`
   - Proper dependencies (jq, socat)
   - Caveats with usage instructions
   - Test suite

2. **`README.md`** - Tap documentation

3. **`LICENSE`** - MIT license

4. **`.gitignore`** - Standard ignores

## 🚀 Setup Steps for Alejandro

### 1. Create Homebrew Tap Repository

```bash
cd /data/.openclaw/workspace/homebrew-tap

# Initialize git
git init
git add .
git commit -m "Initial commit: Herd formula"

# Create repo at https://github.com/Qouter/homebrew-tap
# Then push:
git remote add origin https://github.com/Qouter/homebrew-tap.git
git branch -M main
git push -u origin main
```

### 2. Configure GitHub Secret

1. Create a GitHub Personal Access Token:
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: "Homebrew Tap Updater"
   - Scopes: ✅ `repo` (full control)
   - Generate and copy the token

2. Add secret to Herd repository:
   - Go to https://github.com/Qouter/herd/settings/secrets/actions
   - Click "New repository secret"
   - Name: `TAP_GITHUB_TOKEN`
   - Value: paste your token
   - Save

### 3. Push Herd Changes

```bash
cd /data/.openclaw/workspace/herd

# Add new files
git add .github/workflows/release.yml
git add CHANGELOG.md RELEASE.md HOMEBREW_SETUP.md pre-release-check.sh
git add README.md  # updated

git commit -m "feat: add Homebrew distribution

- GitHub Actions workflow for automated releases
- Homebrew tap formula with CLI wrapper
- Auto-update tap on release
- Pre-release verification script
- Complete release documentation"

git push origin main
```

### 4. Test Release Process (Optional but Recommended)

Before the first real release, test everything works:

```bash
cd /data/.openclaw/workspace/herd

# Run pre-release checks
./pre-release-check.sh

# If all green, create test tag
git tag v0.0.1-test
git push origin v0.0.1-test

# Watch workflow at https://github.com/Qouter/herd/actions
# Then delete test release and tag
```

### 5. Create First Release (v0.1.0)

When ready for the real release:

```bash
cd /data/.openclaw/workspace/herd

# Final pre-release check
./pre-release-check.sh

# Create and push tag
git tag v0.1.0
git push origin v0.1.0

# GitHub Actions will automatically:
# 1. Build universal binary
# 2. Create Herd.app + hooks ZIP
# 3. Create GitHub Release
# 4. Update homebrew-tap Formula
```

### 6. Verify Installation

After the release is published:

```bash
# Add tap
brew tap qouter/tap

# Install
brew install herd

# Verify
herd status
herd open

# Test with Claude Code session
```

## 🎯 What Happens on Release

When you run `git tag v0.1.0 && git push origin v0.1.0`:

1. **GitHub Actions triggers** on `macos-14` runner
2. **Builds**:
   - `swift build -c release --arch arm64 --arch x86_64`
   - Creates `Herd.app` bundle
   - Ad-hoc code signing
3. **Packages**:
   - `Herd-macos-universal.zip` containing:
     - `Herd-release/Herd.app/`
     - `Herd-release/hooks/` (4 scripts)
   - Generates SHA256
4. **Publishes**:
   - Creates GitHub Release with:
     - Zip file
     - SHA256 checksum
     - Auto-generated release notes
5. **Updates Tap** (if `TAP_GITHUB_TOKEN` is set):
   - Clones `Qouter/homebrew-tap`
   - Updates `Formula/herd.rb`:
     - `version "0.1.0"`
     - `url` with new tag
     - `sha256` with computed hash
   - Commits and pushes

## 🧪 CLI Wrapper Features

The Homebrew formula includes a bash wrapper at `$(brew --prefix)/bin/herd`:

```bash
herd open              # Launch Herd.app
herd install-hooks     # Register Claude Code hooks
herd uninstall-hooks   # Remove hooks before uninstall
herd status            # Show app status + hook configuration
herd                   # Show usage help
```

Hooks are **automatically installed** on `brew install herd` via `post_install`.

## 📋 Pre-Release Checklist

Before every release, run:

```bash
./pre-release-check.sh
```

This verifies:
- ✅ CHANGELOG is updated
- ✅ All required files exist
- ✅ Hook scripts are executable
- ✅ Build succeeds
- ✅ .app bundle structure is correct
- ✅ Git status is clean
- ✅ On main/master branch
- ✅ Homebrew tap repo exists

## 🐛 Troubleshooting

### Build fails on GitHub Actions
- Check logs at https://github.com/Qouter/herd/actions
- Verify Xcode version compatibility
- Test locally with `./build.sh`

### Tap not auto-updated
- Verify `TAP_GITHUB_TOKEN` secret is set correctly
- Check token has `repo` permissions
- Manually update formula (see `RELEASE.md`)

### Installation fails
```bash
# Test formula locally
cd /data/.openclaw/workspace/homebrew-tap
brew install --build-from-source ./Formula/herd.rb

# Check formula syntax
brew audit --strict herd
```

### Hooks not working
```bash
# Reinstall hooks
herd install-hooks

# Check settings.json
cat ~/.claude/settings.json

# Verify hook scripts
ls -l $(brew --prefix)/share/herd/hooks/
```

## 📚 Documentation

- **Release process**: See `RELEASE.md`
- **Version history**: See `CHANGELOG.md`
- **User installation**: See `README.md`
- **Tap repo**: See `/data/.openclaw/workspace/homebrew-tap/README.md`

## ✅ Ready to Go!

Everything is set up and ready. When you're ready for the first release:

1. Push the tap repo to GitHub
2. Add `TAP_GITHUB_TOKEN` secret
3. Push Herd changes
4. Run `./pre-release-check.sh`
5. Create tag: `git tag v0.1.0 && git push origin v0.1.0`
6. Watch the magic happen at https://github.com/Qouter/herd/actions

Happy shipping! 🚀
