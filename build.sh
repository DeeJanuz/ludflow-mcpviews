#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="ludflow"
ZIP_NAME="${PLUGIN_NAME}-plugin.zip"
RELEASE_DIR="release"
BUILD_DIR=".build"
BUILD_CHANNEL="${LUDFLOW_MCPVIEWS_BUILD_CHANNEL:-production}"

echo "Building ${ZIP_NAME}..."

# Clean previous build
rm -rf "${RELEASE_DIR}" "${BUILD_DIR}"
mkdir -p "${RELEASE_DIR}"
mkdir -p "${BUILD_DIR}/renderers"

# Read version from manifest and generate a channel-specific build artifact.
VERSION=$(python3 -c "import json; print(json.load(open('manifest.json'))['version'])")
DOWNLOAD_URL="https://github.com/DeeJanuz/ludflow-mcpviews/releases/download/v${VERSION}/${ZIP_NAME}"

BUILD_CHANNEL="${BUILD_CHANNEL}" DOWNLOAD_URL="${DOWNLOAD_URL}" python3 - <<'PY'
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

def origin(value):
    if not value:
        return ""
    parsed = urlparse(value)
    if parsed.scheme and parsed.netloc:
        return f"{parsed.scheme}://{parsed.netloc}"
    return str(value).rstrip("/")

expected_origins = {
    "production": "https://app.ludflow.com",
    "staging": "https://staging.app.ludflow.com",
}
forbidden_origins = {
    "production": ["https://staging.app.ludflow.com"],
    "staging": ["https://app.ludflow.com"],
}
channel = os.environ.get("BUILD_CHANNEL", "production")
if channel not in expected_origins:
    print(
        "LUDFLOW_MCPVIEWS_BUILD_CHANNEL must be 'production' or 'staging'",
        file=sys.stderr,
    )
    sys.exit(1)

expected = expected_origins[channel]
manifest = json.load(open("manifest.json"))
manifest["download_url"] = os.environ["DOWNLOAD_URL"]
manifest.setdefault("mcp", {})
manifest["mcp"]["url"] = f"{expected}/api/mcp"
manifest["mcp"].setdefault("auth", {})
manifest["mcp"]["auth"]["auth_url"] = f"{expected}/oauth/authorize"
manifest["mcp"]["auth"]["token_url"] = f"{expected}/oauth/token"

source_frame_origins = manifest.get("frame_origins", [])
frame_origins = [expected]
for value in source_frame_origins:
    value = origin(value)
    if not value:
        continue
    if value in expected_origins.values():
        continue
    if value not in frame_origins:
        frame_origins.append(value)
manifest["frame_origins"] = frame_origins

auth = manifest.get("mcp", {}).get("auth", {})
urls = [
    manifest.get("mcp", {}).get("url"),
    auth.get("auth_url"),
    auth.get("token_url"),
]

renderer = Path("renderers/ludflow-pages.js").read_text()
renderer = re.sub(
    r"LUDFLOW_APP_ORIGIN\s*=\s*['\"][^'\"]+['\"]",
    f"LUDFLOW_APP_ORIGIN = '{expected}'",
    renderer,
    count=1,
)
match = re.search(r"LUDFLOW_APP_ORIGIN\s*=\s*['\"]([^'\"]+)['\"]", renderer)
if match:
    urls.append(match.group(1))

if "clipboard-write" not in renderer:
    print(
        "Ludflow embedded app iframe must grant clipboard-write for Windows/WebView2 share-link buttons.",
        file=sys.stderr,
    )
    sys.exit(1)

origins = {origin(value) for value in urls if origin(value)}
if origins != {expected}:
    print(
        "Ludflow plugin build channel/origin mismatch: "
        f"channel={channel}, expected={expected}, found={sorted(origins)}. "
        "Set LUDFLOW_MCPVIEWS_BUILD_CHANNEL=staging only for staging VM builds.",
        file=sys.stderr,
    )
    sys.exit(1)

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

payload = json.dumps(manifest, indent=2)
for forbidden in forbidden_origins[channel]:
    if forbidden in payload or forbidden in renderer:
        print(
            f"Ludflow {channel} artifact contains forbidden endpoint {forbidden}",
            file=sys.stderr,
        )
        sys.exit(1)

Path(".build/manifest.json").write_text(payload + "\n")
Path(".build/renderers/ludflow-pages.js").write_text(renderer)
print(f"  Build channel: {channel} ({expected})")
PY

cp -r prompts "${BUILD_DIR}/prompts"

echo "  Version: ${VERSION}"
echo "  Download URL: ${DOWNLOAD_URL}"

# Create ZIP with manifest, renderers, and prompts
cd "${BUILD_DIR}"
zip -r "../${RELEASE_DIR}/${ZIP_NAME}" manifest.json renderers/ prompts/
cd ..

python3 - <<'PY'
import os
import sys
import zipfile

channel = os.environ.get("LUDFLOW_MCPVIEWS_BUILD_CHANNEL", "production")
forbidden = {
    "production": ["https://staging.app.ludflow.com"],
    "staging": ["https://app.ludflow.com"],
}[channel]

with zipfile.ZipFile("release/ludflow-plugin.zip") as archive:
    for entry in archive.namelist():
        if entry.endswith("/"):
            continue
        data = archive.read(entry)
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        for endpoint in forbidden:
            if endpoint in text:
                print(
                    f"Ludflow {channel} ZIP contains forbidden endpoint {endpoint} in {entry}",
                    file=sys.stderr,
                )
                sys.exit(1)
print(f"  Endpoint guard passed for {channel}")
PY

rm -rf "${BUILD_DIR}"

echo "Built ${RELEASE_DIR}/${ZIP_NAME} ($(du -h "${RELEASE_DIR}/${ZIP_NAME}" | cut -f1))"
