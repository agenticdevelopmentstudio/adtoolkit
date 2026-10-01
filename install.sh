#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Apple platform: regenerate XcodeGen-backed Xcode projects from project.yml.
# ADT's frameworks first — AgenticToolkit's project references their xcodeprojs.
if command -v xcodegen >/dev/null; then
  echo "==> Regenerating Apple Xcode projects from project.yml"
  for proj in \
      packages/apple/AgenticDeveloperToolkit \
      packages/apple/AgenticDeveloperHubClient \
      packages/apple/AvatarAnimationEngine \
      packages/apple/SampleApp \
      packages/apple/AgenticToolkit \
      packages/apple/AIPlugins \
      packages/apple/AgenticToolkitApp; do
    echo "    $proj"
    ( cd "$proj" && xcodegen generate )
  done
else
  echo "warn: xcodegen not installed — skipping Apple project regeneration."
  echo "      Install it with: brew install xcodegen"
fi

# Web platform: pnpm workspace. Build after installing: the @agentic-toolkit/* packages
# typecheck against the @agenticdevelopertoolkit/* packages' emitted .d.ts, and themes'
# generated theme-data.ts, neither of which is committed. Both steps are idempotent, so
# this is safe on every ./install.sh, not just the first.
if command -v pnpm >/dev/null && command -v node >/dev/null; then
  echo "==> Installing and building the web workspace in packages/web/"
  ( cd packages/web && pnpm install && pnpm build )
else
  echo "warn: node and pnpm are required for the web workspace — skipping."
  echo "      Install them and re-run ./install.sh to bootstrap packages/web/."
fi

cat <<'EOF'

Workspace ready.

Apple:
    open packages/apple/agenticdevelopertoolkit.xcworkspace

Web:
    cd packages/web && pnpm test
    cd packages/web && pnpm lint

Demo sites:
    cd websites/site && npm install && npm run dev
    cd websites/demo && npm install && npm run dev

Consumers read the packages from source; see docs/web/consuming-as-submodule.md
for the one-time wiring.
EOF
