#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate --quiet
fi

xcodebuild -project Foldaway.xcodeproj -scheme Foldaway -configuration Release \
  -derivedDataPath build/DerivedData -quiet build

rm -rf build/Foldaway.app
cp -R build/DerivedData/Build/Products/Release/Foldaway.app build/
echo "Built build/Foldaway.app"

if [[ "${1:-}" == "--install" ]]; then
  osascript -e 'tell application "Foldaway" to quit' >/dev/null 2>&1 || true
  rm -rf /Applications/Foldaway.app
  cp -R build/Foldaway.app /Applications/
  open /Applications/Foldaway.app
  echo "Installed to /Applications/Foldaway.app"
fi
