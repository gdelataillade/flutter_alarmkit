#!/usr/bin/env bash

set -euo pipefail

# Type-check the real plugin sources against Apple SDKs. A minimal Flutter
# module stub keeps this check independent of Flutter engine slices while the
# plugin sources themselves exercise AlarmKit symbols such as AlarmManager.
#
# Run from anywhere with: tool/check_native_availability.sh

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
source_dir="$repo_root/ios/flutter_alarmkit/Sources/flutter_alarmkit"
stub_source="$script_dir/native_availability/flutter_stub.swift"
probe_dir=$(mktemp -d)

trap 'rm -rf -- "$probe_dir"' EXIT

compile_plugin_sources() {
  local label=$1
  local sdk=$2
  local target=$3
  shift 3

  local sdk_path
  sdk_path=$(xcrun --sdk "$sdk" --show-sdk-path)

  local module_dir="$probe_dir/$sdk"
  mkdir -p "$module_dir"

  xcrun swiftc \
    -emit-module \
    -parse-as-library \
    -module-name Flutter \
    -sdk "$sdk_path" \
    -target "$target" \
    "$@" \
    -o "$module_dir/Flutter.swiftmodule" \
    "$stub_source"

  xcrun swiftc \
    -typecheck \
    -sdk "$sdk_path" \
    -target "$target" \
    -I "$module_dir" \
    "$@" \
    "$source_dir"/*.swift

  echo "Passed native availability check: $label"
}

compile_plugin_sources \
  "iOS Simulator" \
  iphonesimulator \
  arm64-apple-ios18.0-simulator

macos_sdk_path=$(xcrun --sdk macosx --show-sdk-path)
ios_support_frameworks="$macos_sdk_path/System/iOSSupport/System/Library/Frameworks"

compile_plugin_sources \
  "Mac Catalyst (unsupported registration path)" \
  macosx \
  arm64-apple-ios26.0-macabi \
  -F "$ios_support_frameworks"
