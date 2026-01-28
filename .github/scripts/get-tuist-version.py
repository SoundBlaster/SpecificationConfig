#!/usr/bin/env python3
"""
Fetch the latest Tuist release version from GitHub.
Sets TUIST_VERSION as a GitHub Actions output variable.
"""
import json
import os
import sys
import urllib.request


def get_latest_tuist_version():
    """Fetch the latest Tuist release version from GitHub API."""
    url = "https://api.github.com/repos/tuist/tuist/releases/latest"
    
    headers = {"User-Agent": "GitHub-Actions-Tuist-Installer"}
    auth_header = os.environ.get("AUTH_HEADER")
    if auth_header:
        headers["Authorization"] = auth_header.replace("Authorization: ", "")
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode())
            tag_name = data.get("tag_name")
            if not tag_name:
                print("Error: No tag_name in response", file=sys.stderr)
                sys.exit(1)
            return tag_name
    except Exception as e:
        print(f"Error fetching Tuist version: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    version = get_latest_tuist_version()
    print(f"Latest Tuist version: {version}")
    
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
