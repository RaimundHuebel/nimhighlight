#!/bin/sh

PROJECTDIR=$(realpath "$(dirname "$0")/..")
#echo $PROJECTDIR

VERSION=$(grep '^\s*version\s*=\s*' "$PROJECTDIR/highlight.nimble" | cut -d\" -f2)
AUTHOR=$(grep '^\s*author\s*=\s*' "$PROJECTDIR/highlight.nimble" | cut -d\" -f2)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
#GIT_COMMIT_ID=$(git rev-parse --verify HEAD)
GIT_COMMIT_DETAILS=$(git show -s --format="%ci, sha1: %H")
echo "highlighter v$VERSION (by: $AUTHOR)"
echo "git: $GIT_BRANCH ($GIT_COMMIT_DETAILS)"
