#!/bin/bash
# Navigate up one or more directory levels.
# Usage: source up.sh [levels]
#   levels - number of directories to move up (default: 1)

levels=${1:-1}

if (( levels <= 0 )); then
    return 2>/dev/null || exit
fi

path=""
for (( i = 0; i < levels; i++ )); do
    path="../$path"
done

cd "$path"
