#!/bin/bash

function download-file {
  downloadUrl=$1
  saveFileName=$2
  fileName=`echo ${downloadUrl##*/}`
  echo "Downloading $fileName"
  rm "./$saveFileName" >/dev/null 2&>1
  wget -q -O $saveFileName $downloadUrl
  if [[ ! -f "./$saveFileName" ]]; then
    echo "Failed to download $fileName"
    exit 1
  fi
}

function download-ttyd {
  orgFileName=$1
  saveFileName=$2
  TTYD_VERSION=$3
  downloadUrl="https://github.com/tsl0922/ttyd/releases"
  if [[ -z "${TTYD_VERSION}" ]]; then
    downloadUrl="$downloadUrl/latest/download"
  else
    downloadUrl="$downloadUrl/download/$TTYD_VERSION"
  fi
  downloadUrl="$downloadUrl/$orgFileName"
  download-file $downloadUrl $saveFileName
}

function build {
  osCode=$1
  PLATFORM=${osCode#*|}
  IMAGE_NAME=${osCode%|*}
  SUFFIX=`echo ${IMAGE_NAME##*/}`
  OS=${SUFFIX%:*}
  VERSION=${SUFFIX##*:}
  DOCKERFILE="./os/$OS/Dockerfile-$VERSION"


  TAG="localhost:5000/$IMAGE_NAME"

  echo ""
  echo "##########################################################################"
  echo "##  Building $IMAGE_NAME using $DOCKERFILE"
  echo "##########################################################################"
  docker pull "$TAG" || true
  docker buildx build \
    --pull \
    --cache-from "$TAG" \
    --platform $PLATFORM \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%d')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
    -t "$TAG" \
    --push \
    -f "$DOCKERFILE" \
    . \
    || exit 1
}



echo "Downloading ttyds"
IE11_VERSION='1.4.4'
# download-ttyd ttyd_linux.i386 ttyd_linux.386 $IE11_VERSION
# download-ttyd ttyd_linux.x86_64 ttyd_linux.amd64 $IE11_VERSION
# download-ttyd ttyd_linux.arm ttyd_linux.arm $IE11_VERSION
# download-ttyd ttyd_linux.aarch64 ttyd_linux.arm64 $IE11_VERSION
# download-ttyd ttyd.s390x ttyd_linux.s390x
# download-ttyd ttyd.mips64el ttyd_linux.mips64le

if $SHOULD_PUSH; then
  docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" "$DOCKER_REGISTRY"
fi

for osCode in $(cat manifest.json | grep osCode\":\ \"instantbox | grep -o 'instantbox[^"]*'); do
  build $osCode
done
