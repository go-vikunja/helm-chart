#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 <version> [tag description]"
	exit 1
fi

VERSION="$1"
# Strip 'v' prefix if present (helm convention: no v prefix)
VERSION="${VERSION#v}"
TAG_DESCRIPTION="${2:-}"
DATE=$(date +%Y-%m-%d)

sed -i "s/^version: .*/version: ${VERSION}/" Chart.yaml
sed -i "/^  global:/,/^  [^ ]/ s/^      helm.sh\\/chart: .*/      helm.sh\\/chart: \"vikunja-${VERSION}\"/" values.yaml

git add Chart.yaml values.yaml
git commit -m "chore: release ${VERSION}"

TAG_MESSAGE="${VERSION} [${DATE}]"
if [ -n "$TAG_DESCRIPTION" ]; then
	TAG_MESSAGE="${TAG_MESSAGE}

${TAG_DESCRIPTION}"
fi

git tag -a "${VERSION}" -m "${TAG_MESSAGE}"

echo "Released ${VERSION}"
