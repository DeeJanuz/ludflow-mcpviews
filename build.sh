#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="ludflow"
ZIP_NAME="${PLUGIN_NAME}-plugin.zip"
RELEASE_DIR="release"

echo "Building ${ZIP_NAME}..."

# Clean previous build
rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

# Read version from manifest and sync download_url
VERSION=$(python3 -c "import json; print(json.load(open('manifest.json'))['version'])")
DOWNLOAD_URL="https://github.com/DeeJanuz/ludflow-mcpviews/releases/download/v${VERSION}/${ZIP_NAME}"
BUILD_CHANNEL="${LUDFLOW_MCPVIEWS_BUILD_CHANNEL:-production}"

python3 - <<'PY'
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

expected_origins = {
    "production": "https://app.ludflow.com",
    "staging": "https://staging.app.ludflow.com",
}
channel = os.environ.get("LUDFLOW_MCPVIEWS_BUILD_CHANNEL", "production")
if channel not in expected_origins:
    print(
        "LUDFLOW_MCPVIEWS_BUILD_CHANNEL must be 'production' or 'staging'",
        file=sys.stderr,
    )
    sys.exit(1)

manifest = json.load(open("manifest.json"))
auth = manifest.get("mcp", {}).get("auth", {})
urls = [
    manifest.get("mcp", {}).get("url"),
    auth.get("auth_url"),
    auth.get("token_url"),
]

renderer = Path("renderers/ludflow-pages.js").read_text()
match = re.search(r"LUDFLOW_APP_ORIGIN\s*=\s*['\"]([^'\"]+)['\"]", renderer)
if match:
    urls.append(match.group(1))

def origin(value):
    if not value:
        return ""
    parsed = urlparse(value)
    if parsed.scheme and parsed.netloc:
        return f"{parsed.scheme}://{parsed.netloc}"
    return str(value).rstrip("/")

origins = {origin(value) for value in urls if origin(value)}
expected = expected_origins[channel]
if origins != {expected}:
    print(
        "Ludflow plugin build channel/origin mismatch: "
        f"channel={channel}, expected={expected}, found={sorted(origins)}. "
        "Set LUDFLOW_MCPVIEWS_BUILD_CHANNEL=staging only for staging VM builds.",
        file=sys.stderr,
    )
    sys.exit(1)

frame_origins = [origin(value) for value in manifest.get("frame_origins", [])]
frame_origins = [value for value in frame_origins if value]
if not frame_origins:
    print("Ludflow plugin manifest must declare frame_origins.", file=sys.stderr)
    sys.exit(1)
if frame_origins[0] != expected:
    print(
        "Ludflow plugin first frame_origin does not match build channel: "
        f"channel={channel}, expected={expected}, first={frame_origins[0]}.",
        file=sys.stderr,
    )
    sys.exit(1)

mcp_origin = origin(manifest.get("mcp", {}).get("url"))
selected_embed_origin = mcp_origin or frame_origins[0]
if selected_embed_origin != expected:
    print(
        "Ludflow plugin selected embed origin does not match build channel: "
        f"channel={channel}, expected={expected}, selected={selected_embed_origin}.",
        file=sys.stderr,
    )
    sys.exit(1)

print(f"  Build channel: {channel} ({expected})")
PY

python3 -c "
import json
m = json.load(open('manifest.json'))
m['download_url'] = '${DOWNLOAD_URL}'
json.dump(m, open('manifest.json', 'w'), indent=2)
print('  Updated source manifest download_url')
"

echo "  Version: ${VERSION}"
echo "  Download URL: ${DOWNLOAD_URL}"

# Create ZIP with manifest, renderers, and prompts
zip -r "${RELEASE_DIR}/${ZIP_NAME}" manifest.json renderers/ prompts/

echo "Built ${RELEASE_DIR}/${ZIP_NAME} ($(du -h "${RELEASE_DIR}/${ZIP_NAME}" | cut -f1))"
