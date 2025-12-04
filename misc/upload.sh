#!/bin/bash

# Upload exported artifact to App Store Connect using App Store Connect API key.
# Usage: ./upload.sh <artifact_path> <platform>
# platform: iOS, macOS, tvOS (used to determine altool type)

set -e

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

if [ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
	echo "Error: API key file path is required" >&2
	echo "Set APP_STORE_CONNECT_API_KEY_PATH environment variable" >&2
	exit 1
fi

if [ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]; then
	echo "Error: API key file not found at '$APP_STORE_CONNECT_API_KEY_PATH'" >&2
	exit 1
fi

if [ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ] || [ -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]; then
	echo "Error: API Key ID and Issuer ID are required" >&2
	echo "Set APP_STORE_CONNECT_API_KEY_ID and APP_STORE_CONNECT_API_ISSUER_ID environment variables" >&2
	exit 1
fi

UPLOAD_TYPE="ios"
case "$PLATFORM" in
"macOS" | "macos")
	UPLOAD_TYPE="macos"
	;;
"tvOS" | "tvos")
	UPLOAD_TYPE="appletvos"
	;;
"iOS" | "ios")
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
	--api-key "$APP_STORE_CONNECT_API_KEY_ID" \
	--api-issuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
	--p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"

echo "✓ Upload completed for $ARTIFACT_PATH"
