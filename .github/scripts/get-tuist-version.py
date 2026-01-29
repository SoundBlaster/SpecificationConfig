#!/usr/bin/env python3
"""
Fetch the latest Tuist CLI release version from GitHub.
Sets TUIST_VERSION as a GitHub Actions output variable.

Note: Tuist has multiple release types (CLI and server). CLI releases have
simple version tags like "4.36.1", while server releases have "server@" prefix.
We need to filter for CLI releases only since those contain tuist.zip.
"""
import json
import os
import re
import sys
import urllib.request


def is_cli_release(tag_name):
    """Check if a tag represents a CLI release (simple semver, no prefix)."""
    return bool(re.match(r"^\d+\.\d+\.\d+$", tag_name))


def get_latest_tuist_version():
    """Fetch the latest Tuist CLI release version from GitHub API."""
    url = "https://api.github.com/repos/tuist/tuist/releases?per_page=50"

    headers = {"User-Agent": "GitHub-Actions-Tuist-Installer"}
    auth_header = os.environ.get("AUTH_HEADER")
    if auth_header:
        headers["Authorization"] = auth_header.replace("Authorization: ", "")

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as response:
            releases = json.loads(response.read().decode())

            for release in releases:
                tag_name = release.get("tag_name", "")
                if is_cli_release(tag_name) and not release.get("draft", False):
                    return tag_name

            print("Error: No CLI release found in recent releases", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error fetching Tuist version: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    version = get_latest_tuist_version()
    print(f"Latest Tuist CLI version: {version}")
    
    # Set GitHub Actions output
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as f:
            f.write(f"tuist_version={version}\n")
    else:
        # For local testing only - this won't set the output variable in GitHub Actions
        print(f"Warning: GITHUB_OUTPUT not set, output variable not created", file=sys.stderr)
        print(f"tuist_version={version}")


if __name__ == "__main__":
    main()
