#!/usr/bin/env bash
# Pre-release verification script
# Run this before creating a release tag

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Pre-Release Verification"
echo "============================"
echo ""

ERRORS=0
WARNINGS=0

# Check 1: CHANGELOG updated
echo -n "Checking CHANGELOG.md... "
if grep -q "\[Unreleased\]" CHANGELOG.md && ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
  echo -e "${RED}✗${NC}"
  echo "  ⚠️  CHANGELOG has unreleased items. Move them to a version section."
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✓${NC}"
fi

# Check 2: Required files exist
echo -n "Checking required files... "
REQUIRED_FILES=(
  "README.md"
  "CHANGELOG.md"
  "RELEASE.md"
  "build.sh"
  "install.sh"
  "hooks/on-session-start.sh"
  "hooks/on-session-end.sh"
  "hooks/on-stop.sh"
  "hooks/on-prompt.sh"
  ".github/workflows/release.yml"
)

MISSING=()
for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    MISSING+=("$file")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo -e "${RED}✗${NC}"
  echo "  Missing files:"
  for file in "${MISSING[@]}"; do
    echo "    - $file"
  done
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✓${NC}"
fi

# Check 3: Hook scripts are executable
echo -n "Checking hook permissions... "
NON_EXEC=()
for hook in hooks/*.sh; do
  if [[ ! -x "$hook" ]]; then
    NON_EXEC+=("$hook")
  fi
done

if [[ ${#NON_EXEC[@]} -gt 0 ]]; then
  echo -e "${YELLOW}⚠${NC}"
  echo "  Non-executable hooks:"
  for hook in "${NON_EXEC[@]}"; do
    echo "    - $hook"
  done
  echo "  Run: chmod +x hooks/*.sh"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}✓${NC}"
fi

# Check 4: Build script works
echo -n "Testing build... "
if ./build.sh > /tmp/herd-build-test.log 2>&1; then
  echo -e "${GREEN}✓${NC}"
  rm -f /tmp/herd-build-test.log
else
  echo -e "${RED}✗${NC}"
  echo "  Build failed. See /tmp/herd-build-test.log"
  ERRORS=$((ERRORS + 1))
fi

# Check 5: .app bundle was created
echo -n "Checking .app bundle... "
if [[ -d "build/Herd.app" ]]; then
  echo -e "${GREEN}✓${NC}"
  
  # Check bundle structure
  echo -n "Checking bundle structure... "
  if [[ -f "build/Herd.app/Contents/MacOS/Herd" ]] && \
     [[ -f "build/Herd.app/Contents/Info.plist" ]]; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    echo "  Incomplete bundle structure"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo -e "${RED}✗${NC}"
  echo "  No .app bundle found"
  ERRORS=$((ERRORS + 1))
fi

# Check 6: Version consistency (if app has version in Package.swift)
echo -n "Checking version info... "
if [[ -f "app/Package.swift" ]]; then
  # Extract version from Info.plist if build succeeded
  if [[ -f "build/Herd.app/Contents/Info.plist" ]]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "build/Herd.app/Contents/Info.plist" 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} (v$VERSION)"
  else
    echo -e "${YELLOW}⚠${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo -e "${YELLOW}⚠${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Check 7: Homebrew tap repo exists locally
echo -n "Checking Homebrew tap repo... "
if [[ -f "../homebrew-tap/Formula/herd.rb" ]]; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  Tap repo not found at ../homebrew-tap/"
  echo "  It will be needed for the release"
  WARNINGS=$((WARNINGS + 1))
fi

# Check 8: Git status
echo -n "Checking git status... "
if [[ -z "$(git status --porcelain)" ]]; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  Uncommitted changes:"
  git status --short | sed 's/^/    /'
  WARNINGS=$((WARNINGS + 1))
fi

# Check 9: On main branch
echo -n "Checking git branch... "
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  Currently on branch: $CURRENT_BRANCH"
  echo "  Releases should be from main/master"
  WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "============================"
echo "Summary:"
echo ""

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo ""
  echo "Ready to release. Next steps:"
  echo "  1. Review CHANGELOG.md"
  echo "  2. git tag vX.Y.Z"
  echo "  3. git push origin vX.Y.Z"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s)${NC}"
  echo ""
  echo "You can proceed with caution."
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s), $WARNINGS warning(s)${NC}"
  echo ""
  echo "Fix errors before releasing."
  exit 1
fi
