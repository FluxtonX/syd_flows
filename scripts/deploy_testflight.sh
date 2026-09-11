#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN} 🚀 SYD FLOW — Automated TestFlight Deployment ${NC}"
echo -e "${CYAN}====================================================${NC}"

# 1. Ensure running from project root
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from the project root directory.${NC}"
    exit 1
fi

# 2. Extract version from pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml | head -n 1)
VERSION_RAW=$(echo "$VERSION_LINE" | awk '{print $2}' | tr -d '\r' | cut -d'#' -f1 | tr -d ' ')

if [ -z "$VERSION_RAW" ]; then
    echo -e "${RED}❌ Error: Could not parse version from pubspec.yaml.${NC}"
    exit 1
fi

TAG_NAME="v${VERSION_RAW}"

echo -e "${GREEN}📌 Current Version in pubspec.yaml:${NC} ${VERSION_RAW}"
echo -e "${GREEN}🏷️  Git Tag to be created:${NC} ${TAG_NAME}"

# 3. Get commit message from argument or default
COMMIT_MSG="$1"
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Release ${TAG_NAME} - TestFlight Build"
fi

echo -e "${GREEN}📝 Commit Message:${NC} \"${COMMIT_MSG}\""
echo -e "${CYAN}----------------------------------------------------${NC}"

# 4. Git Operations: Stage & Commit
echo -e "${YELLOW}📦 Staging modified files...${NC}"
git add .

if git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}ℹ️  No uncommitted changes detected in working tree.${NC}"
else
    echo -e "${YELLOW}💾 Committing changes...${NC}"
    git commit -m "$COMMIT_MSG"
fi

# 5. Push code to current active branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${YELLOW}⬆️  Pushing code to remote branch '${CURRENT_BRANCH}'...${NC}"
git push origin "$CURRENT_BRANCH"

# 6. Handle Git Tag creation and push
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Tag ${TAG_NAME} already exists locally. Updating tag...${NC}"
    git tag -d "$TAG_NAME"
fi

if git ls-remote --tags origin | grep -q "refs/tags/${TAG_NAME}$"; then
    echo -e "${YELLOW}⚠️  Tag ${TAG_NAME} exists on remote origin. Overwriting remote tag...${NC}"
    git push --delete origin "$TAG_NAME" || true
fi

echo -e "${YELLOW}🏷️  Creating git tag '${TAG_NAME}'...${NC}"
git tag -a "$TAG_NAME" -m "Release $TAG_NAME for TestFlight"

echo -e "${YELLOW}🚀 Pushing tag '${TAG_NAME}' to trigger GitHub Actions TestFlight Build...${NC}"
git push origin "$TAG_NAME"

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN} ✅ SUCCESS! Code pushed & TestFlight build triggered!${NC}"
echo -e "${GREEN} 📊 Monitor build progress here:${NC}"
echo -e "    https://github.com/FluxtonX/syd_flows/actions"
echo -e "${CYAN}====================================================${NC}"
