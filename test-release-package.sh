#!/usr/bin/env bash
# Test Release Package Script
# Simulates the GitHub Actions release process locally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Testing Release Package Creation${NC}"
echo "===================================="
echo ""

# Clean up previous test
rm -rf test-release
mkdir -p test-release

echo "1. Building app..."
if ! ./build.sh > test-release/build.log 2>&1; then
  echo -e "${RED}✗ Build failed${NC}"
  cat test-release/build.log
  exit 1
fi
echo -e "${GREEN}✓${NC} Build succeeded"

echo ""
echo "2. Creating release package structure..."

# Create release directory structure
mkdir -p test-release/Herd-release

# Copy app bundle
cp -r build/Herd.app test-release/Herd-release/
echo -e "${GREEN}✓${NC} Copied Herd.app"

# Copy hooks
cp -r hooks test-release/Herd-release/
echo -e "${GREEN}✓${NC} Copied hooks/"

echo ""
echo "3. Verifying package structure..."

EXPECTED_FILES=(
  "test-release/Herd-release/Herd.app/Contents/MacOS/Herd"
  "test-release/Herd-release/Herd.app/Contents/Info.plist"
  "test-release/Herd-release/hooks/on-session-start.sh"
  "test-release/Herd-release/hooks/on-session-end.sh"
  "test-release/Herd-release/hooks/on-stop.sh"
  "test-release/Herd-release/hooks/on-prompt.sh"
)

ALL_EXIST=true
for file in "${EXPECTED_FILES[@]}"; do
  if [[ -f "$file" ]] || [[ -d "$file" ]]; then
    echo -e "  ${GREEN}✓${NC} ${file#test-release/Herd-release/}"
  else
    echo -e "  ${RED}✗${NC} ${file#test-release/Herd-release/} NOT FOUND"
    ALL_EXIST=false
  fi
done

if [[ "$ALL_EXIST" == false ]]; then
  echo ""
  echo -e "${RED}✗ Package structure incomplete${NC}"
  exit 1
fi

echo ""
echo "4. Code signing (ad-hoc)..."
codesign --force --deep -s - test-release/Herd-release/Herd.app
echo -e "${GREEN}✓${NC} Code signed"

echo ""
echo "5. Creating ZIP archive..."
cd test-release
zip -r Herd-macos-universal.zip Herd-release > /dev/null
cd ..
echo -e "${GREEN}✓${NC} Created test-release/Herd-macos-universal.zip"

echo ""
echo "6. Generating SHA256..."
SHA256=$(shasum -a 256 test-release/Herd-macos-universal.zip | awk '{print $1}')
echo "$SHA256" > test-release/Herd-macos-universal.zip.sha256
echo -e "${GREEN}✓${NC} SHA256: $SHA256"

echo ""
echo "7. Testing archive extraction..."
cd test-release
unzip -q Herd-macos-universal.zip -d extracted
cd ..

if [[ -f "test-release/extracted/Herd-release/Herd.app/Contents/MacOS/Herd" ]] && \
   [[ -f "test-release/extracted/Herd-release/hooks/on-session-start.sh" ]]; then
  echo -e "${GREEN}✓${NC} Archive extracts correctly"
else
  echo -e "${RED}✗${NC} Archive structure invalid"
  exit 1
fi

echo ""
echo "===================================="
echo -e "${GREEN}✓ Release package test PASSED${NC}"
echo ""
echo "Archive details:"
echo "  Location: test-release/Herd-macos-universal.zip"
echo "  Size:     $(du -h test-release/Herd-macos-universal.zip | awk '{print $1}')"
echo "  SHA256:   $SHA256"
echo ""
echo "Contents:"
echo "  Herd-release/"
echo "    ├── Herd.app/"
echo "    └── hooks/"
echo "        ├── on-session-start.sh"
echo "        ├── on-session-end.sh"
echo "        ├── on-stop.sh"
echo "        └── on-prompt.sh"
echo ""
echo "This structure matches what the Homebrew formula expects."
echo ""
echo "To clean up: rm -rf test-release"
