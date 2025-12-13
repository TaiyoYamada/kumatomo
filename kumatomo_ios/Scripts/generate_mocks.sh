#!/bin/bash
# Mockolo Mock Generator Script

set -e

echo "🔄 Generating mocks with Mockolo..."

# Check if Mockolo is installed
if ! command -v mockolo &>/dev/null; then
    echo "⚠️ Mockolo not found. Install with: brew install mockolo"
    echo "   Skipping mock generation..."
    exit 0
fi

# Configuration - when in kumatomo_ios/Scripts, go up to kumatomo_ios
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="${IOS_DIR}/Domain/Repository"
OUTPUT_FILE="${IOS_DIR}/kumatomoTests/Mocks/GeneratedMocks.swift"

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "   Source: $SOURCE_DIR"
echo "   Output: $OUTPUT_FILE"

# Generate mocks
mockolo \
    -s "$SOURCE_DIR" \
    -d "$OUTPUT_FILE" \
    -i kumatomo \
    --mock-final

echo "✅ Mocks generated successfully!"
