#!/bin/bash

# Export script for KMReader archives
# Usage: ./export.sh [archive_path] [export_options_plist] [destination] [--keep-archive] [--platform <name>]
# Example: ./export.sh ./archives/KMReader-iOS_20240101_120000.xcarchive exportOptions.plist ./exports
# --keep-archive: Keep the archive after successful export (default: delete archive)
# --platform: Optional label (iOS, macOS, tvOS) used to rename exported artifacts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Auto-load .env file if it exists (in project root or script directory)
if [ -f "$PROJECT_ROOT/.env" ]; then
	echo -e "${GREEN}Loading environment variables from .env file...${NC}"
	set -a # automatically export all variables
	source "$PROJECT_ROOT/.env"
	set +a # stop automatically exporting
elif [ -f "$SCRIPT_DIR/.env" ]; then
	echo -e "${GREEN}Loading environment variables from .env file...${NC}"
	set -a
	source "$SCRIPT_DIR/.env"
	set +a
fi

# Parse arguments
KEEP_ARCHIVE=false
ARCHIVE_PATH=""
EXPORT_OPTIONS=""
DEST_DIR=""
PLATFORM_LABEL=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--keep-archive)
		KEEP_ARCHIVE=true
		shift
		;;
	--platform)
		if [ -z "${2:-}" ]; then
			echo -e "${RED}Error: --platform requires a value (e.g. iOS, macOS, tvOS)${NC}"
			exit 1
		fi
		PLATFORM_LABEL="$2"
		shift 2
		;;
	*)
		if [ -z "$ARCHIVE_PATH" ]; then
			ARCHIVE_PATH="$1"
		elif [ -z "$EXPORT_OPTIONS" ]; then
			EXPORT_OPTIONS="$1"
		elif [ -z "$DEST_DIR" ]; then
			DEST_DIR="$1"
		fi
		shift
		;;
	esac
done

# Set defaults
EXPORT_OPTIONS="${EXPORT_OPTIONS:-$SCRIPT_DIR/exportOptions.plist}"
DEST_DIR="${DEST_DIR:-$PROJECT_ROOT/exports}"

# Validate arguments
if [ -z "$ARCHIVE_PATH" ]; then
	echo -e "${RED}Error: Archive path is required${NC}"
	echo "Usage: ./export.sh [archive_path] [export_options_plist] [destination]"
	exit 1
fi

if [ ! -d "$ARCHIVE_PATH" ]; then
	echo -e "${RED}Error: Archive not found at '$ARCHIVE_PATH'${NC}"
	exit 1
fi

if [ ! -f "$EXPORT_OPTIONS" ]; then
	echo -e "${RED}Error: Export options plist not found at '$EXPORT_OPTIONS'${NC}"
	echo "You can copy exportOptions.plist.example to exportOptions.plist and customize it"
	exit 1
fi

# Create destination directory
mkdir -p "$DEST_DIR"

# Generate export path with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_PATH="$DEST_DIR/export_${TIMESTAMP}"

# Check export method
EXPORT_METHOD=""
if command -v plutil &>/dev/null; then
	EXPORT_METHOD=$(plutil -extract method raw "$EXPORT_OPTIONS" 2>/dev/null || echo "")
fi

# Determine App Store Connect API credentials from environment
USING_API_KEY=false

if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
	if [ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]; then
		echo -e "${RED}Error: API key file not found at '$APP_STORE_CONNECT_API_KEY_PATH'${NC}"
		exit 1
	fi
	if [ -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ] || [ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ]; then
		echo -e "${RED}Error: API Issuer ID and Key ID are required when using API key${NC}"
		echo -e "${YELLOW}Set APP_STORE_CONNECT_API_ISSUER_ID and APP_STORE_CONNECT_API_KEY_ID environment variables${NC}"
		exit 1
	fi
	USING_API_KEY=true
fi

echo -e "${GREEN}Starting export...${NC}"
echo "Archive: $ARCHIVE_PATH"
echo "Export options: $EXPORT_OPTIONS"
echo "Export path: $EXPORT_PATH"
if [ -n "$EXPORT_METHOD" ]; then
	echo "Export method: $EXPORT_METHOD"
fi
echo -e "${YELLOW}Export only; upload handled by separate script${NC}"
echo ""

# Configure authentication flags if App Store Connect API credentials are available
AUTH_ARGS=()
if [ "$USING_API_KEY" = true ]; then
	AUTH_ARGS+=(
		-authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
		-authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID"
		-authenticationKeyIssuerID "$APP_STORE_CONNECT_API_ISSUER_ID"
	)
	echo -e "${GREEN}Using App Store Connect API key for authentication${NC}"
fi

# Export
echo -e "${YELLOW}Exporting archive...${NC}"

# Run xcodebuild quietly (warnings/errors still show)
xcodebuild -exportArchive \
	-archivePath "$ARCHIVE_PATH" \
	-exportPath "$EXPORT_PATH" \
	-exportOptionsPlist "$EXPORT_OPTIONS" \
	-quiet \
	"${AUTH_ARGS[@]}"
XCODEBUILD_EXIT_CODE=$?

if [ "$XCODEBUILD_EXIT_CODE" -ne 0 ]; then
	echo -e "${RED}✗ Export failed!${NC}"
	exit 1
fi

echo -e "${GREEN}✓ Export completed successfully!${NC}"

echo "Export location: $EXPORT_PATH"
echo ""
echo "Exported files:"

# Rename exported artifact to include platform when requested
if [ -n "$PLATFORM_LABEL" ]; then
	shopt -s nullglob
	for ext in ipa pkg; do
		for file in "$EXPORT_PATH"/*."$ext"; do
			[ -e "$file" ] || continue
			BASENAME="$(basename "$file")"
			TARGET_NAME="KMReader-${PLATFORM_LABEL}.${ext}"
			TARGET_PATH="$EXPORT_PATH/$TARGET_NAME"
			if [ "$BASENAME" != "$TARGET_NAME" ]; then
				mv "$file" "$TARGET_PATH"
				echo -e "${GREEN}Renamed ${BASENAME} -> ${TARGET_NAME}${NC}"
			fi
		done
	done
	shopt -u nullglob
fi

ls -lh "$EXPORT_PATH"

# Delete archive if not keeping it
if [ "$KEEP_ARCHIVE" = false ]; then
	echo ""
	echo -e "${YELLOW}Deleting archive...${NC}"
	rm -rf "$ARCHIVE_PATH"
	echo -e "${GREEN}✓ Archive deleted${NC}"
else
	echo ""
	echo -e "${YELLOW}Archive kept at: $ARCHIVE_PATH${NC}"
fi
