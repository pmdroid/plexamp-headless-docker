#!/usr/bin/env bash

VERSION="v4.5.0-beta.32"
TAG=450b32

IMAGE_BASE="registry.gitlab.com/zonywhoop/plexamp-headless-x64"
BUILDS="linux/amd64:snapjack linux/arm64/v8:rpi4 linux/arm/v7:rpi3"
MANIFEST="docker manifest create ${IMAGE_BASE}:${TAG}"
for b in $BUILDS; do
    BP=$(echo $b | cut -d: -f1)
    BT=$(echo $b | cut -d: -f2)
    ARCH=$(echo $b | cut -d: -f1 | cut -d/ -f2)
    THIS_TAG="${IMAGE_BASE}:${ARCH}-${TAG}"

    echo "Building for $BP"
    docker build --platform $BP --build-arg=PLEXAMP_VERSION="${VERSION}" -t ${THIS_TAG} -f Dockerfile.${BT} . 
    RET=$?
    if [ $RET -eq 0 ]; then
        echo "Pushing $BP"
        docker push ${THIS_TAG}
        MANIFEST="${MANIFEST} --amend ${THIS_TAG}"
    else
        echo "Build failed"
    fi
done
echo "Pushing final manifest"
${MANIFEST}

