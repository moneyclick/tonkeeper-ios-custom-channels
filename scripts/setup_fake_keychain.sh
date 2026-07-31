#!/bin/bash
set -e
set -x

KEYCHAIN="build.keychain"
PASSWORD="secret"

echo "Setting up temporary keychain for fake-codesigning..."

# Delete keychain if it exists from previous run
security delete-keychain "$KEYCHAIN" 2>/dev/null || true

# Create and unlock new keychain
security create-keychain -p "$PASSWORD" "$KEYCHAIN"
security default-keychain -s "$KEYCHAIN"
security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
security set-keychain-settings -t 3600 -u "$KEYCHAIN"

CERTS_DIR="build-system/fake-codesigning/certs"

if [ -d "$CERTS_DIR" ]; then
  for f in "$CERTS_DIR"/*.p12; do
    if [ -f "$f" ]; then
      echo "Importing $f..."
      security import "$f" -k "$KEYCHAIN" -P "" -A -T /usr/bin/codesign -T /usr/bin/security || true
    fi
  done

  for f in "$CERTS_DIR"/*.cer; do
    if [ -f "$f" ]; then
      echo "Importing $f..."
      security import "$f" -k "$KEYCHAIN" -P "" -A -T /usr/bin/codesign -T /usr/bin/security || true
    fi
  done
fi

if [ -f "build-system/AppleWWDRCAG3.cer" ]; then
  echo "Importing AppleWWDRCAG3.cer..."
  security import "build-system/AppleWWDRCAG3.cer" -k "$KEYCHAIN" -P "" -A -T /usr/bin/codesign -T /usr/bin/security || true
fi

# Allow codesign tool to access keychain without UI prompt
security set-key-partition-list -S apple-tool:,apple: -k "$PASSWORD" "$KEYCHAIN" || true

echo "Fake codesigning keychain ready!"
