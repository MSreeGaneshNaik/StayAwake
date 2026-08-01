#!/bin/bash
# Builds StayAwake directly with swiftc, bypassing SwiftPM.
# (SwiftPM's own manifest compilation is broken in this environment — a link
# error against PackageDescription happens even for an empty Package.swift —
# so `swift build` can't be used until the CommandLineTools install is repaired.)
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p .build
swiftc -parse-as-library -O -o .build/StayAwake Sources/StayAwake/*.swift

echo "Built .build/StayAwake"
echo "Run it with: .build/StayAwake &"
