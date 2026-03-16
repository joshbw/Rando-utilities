#!/bin/bash
# Create a directory and immediately change into it.
# Usage: source mdcd.sh <directory>

if [ -z "$1" ]; then
    echo "Usage: source mdcd.sh <directory>"
    return 2>/dev/null || exit 1
fi

mkdir -p "$1" && cd "$1"
