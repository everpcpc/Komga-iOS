#!/bin/bash

# Upload exported artifact to App Store Connect using App Store Connect API key.
# Usage: ./upload.sh <artifact_path> <platform>
# platform: iOS, macOS, tvOS (used to determine altool type)

set -euo pipefail

if [ $# -lt 2 ]; then
	echo "Usage: $0 <artifact_path> <platform>" >&2
	exit 1
fi

ARTIFACT_PATH="$1"
PLATFORM="$2"

if [ ! -f "$ARTIFACT_PATH" ]; then
	echo "Artifact not found at '$ARTIFACT_PATH'" >&2
	exit 1
fi

if [ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ] || [ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ] || [ -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]; then
	echo "App Store Connect API credentials are required for upload" >&2
	exit 1
fi

UPLOAD_TYPE="ios"
case "$PLATFORM" in
"macOS")
	UPLOAD_TYPE="macos"
	;;
"tvOS" | "iOS")
	UPLOAD_TYPE="ios"
	;;
*)
	echo "Unknown platform '$PLATFORM'; defaulting upload type to ios"
	UPLOAD_TYPE="ios"
	;;
esac

echo "Uploading $ARTIFACT_PATH ($PLATFORM) to App Store Connect..."
xcrun altool --upload-app \
	-f "$ARTIFACT_PATH" \
	-t "$UPLOAD_TYPE" \
	--apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
	--apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
	--apiKeyFile "$APP_STORE_CONNECT_API_KEY_PATH"

echo "✓ Upload completed for $ARTIFACT_PATH"
