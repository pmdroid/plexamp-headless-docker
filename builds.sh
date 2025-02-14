#!/usr/bin/env bash


VERSION=${VERSION:-latest}
TAG=${TAG:-}

if [ "$VERSION" = "latest" ]; then
    LV=$(curl -s "https://plexamp.plex.tv/headless/version.json" | jq -r '.latestVersion')
    VERSION="v${LV}"
    TAG=$(echo $LV | sed -e 's/\.//g')
else
    TAG=$(echo $VERSION | sed -e 's/\.//g' -e 's/^v//')
fi

IMAGE_BASE="ghcr.io/pmdroid/plexamp-headless-docker"
BUILDS="linux/amd64:amd64 linux/arm64/v8:rpi4 linux/arm/v7:rpi3"

MANIFEST="docker manifest create ${IMAGE_BASE}:${TAG}"
for b in $BUILDS; do
    BP=$(echo $b | cut -d: -f1)
    BT=$(echo $b | cut -d: -f2)
    ARCH=$(echo $b | cut -d: -f1 | cut -d/ -f2)
    THIS_TAG="${IMAGE_BASE}:${ARCH}-${TAG}"
    DFROM="balenalib\/amd64-ubuntu-node:20-focal-run"
    case "$BT" in
        rpi3)
            DFROM="balenalib\/raspberrypi3-node:20-run"
            ;;
        rpi4)
            DFROM="balenalib\/raspberrypi4-64-node:20-run"
            ;;
    esac
    cat Dockerfile.template | sed -e "s/%FROM%/${DFROM}/" > Dockerfile

    echo "Building for $BP"
    docker build --privileged --platform $BP --build-arg=PLEXAMP_BUILD_VERSION="${VERSION}" -t ${THIS_TAG} -f Dockerfile . 
    RET=$?
    if [ $RET -eq 0 ]; then
        echo "Pushing $BP"
        docker push ${THIS_TAG}
        MANIFEST="${MANIFEST} --amend ${THIS_TAG}"
    else
        echo "************************"
        echo "Build failed"
        echo "************************"
        exit 1
    fi
done
echo "Pushing final manifest"
${MANIFEST}

