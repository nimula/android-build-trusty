#!/usr/bin/env bash
# Author : nimula+github@gmail.com

usage="Usage: $0 [-h] [-s <source directory>] [build|run|create]"
image=${PWD##*/}

if [ "$(command -v podman)" ]; then
  docker="podman"
elif [ "$(command -v docker)" ]; then
  docker="docker"
else
  echo "Either Podman or Docker isn't installed"
  exit 2
fi

answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}

ask_for_confirmation() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1 (y/n) \e[0m"
  read -n 1
  printf "\n"
}

is_src_specified() {
  if [[ ! -d ${src} ]]; then
    echo "Missing argument for -s <source directory>" >&2
    echo "Container need specify source directory"
    exit 1
  fi
}

create_image() {
  dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  if [ ! -f ${dir}/gitconfig ]; then
    echo "# Copy your host gitconfig, or create a stripped down version"
    echo "$ cp ~/.gitconfig ${dir}/gitconfig"
    ask_for_confirmation "Do you want to copy gitconfig from ${HOME}/.gitconfig?"
    if answer_is_yes; then
      cp "${HOME}/.gitconfig" "${dir}/gitconfig"
    else
      exit 3
    fi
  fi

  build_args="--build-arg userid=$(id -u) --build-arg groupid=$(id -g) \
  --build-arg username=$(id -un) -t ${image} ${dir}"

  if [ "$(command -v buildah)" ]; then
    echo "$ buildah bud ${build_args}"
    buildah bud ${build_args}
  else
    echo "$ ${docker} build ${build_args}"
    ${docker} build ${build_args}
  fi
}

docker_run() {
  # Prefixing docker with 'winpty', when running in MinGW and Cygwin
  uname_out="$(uname -s)"
  case "${uname_out}" in
      Linux*)   prefix="";;
      Darwin*)  prefix="";;
      CYGWIN*)  prefix="winpty";;
      MINGW*)   prefix="winpty";;
      *)        prefix=""; echo "UNKNOWN:${uname_out}";;
  esac

  # Podman need --userns=keep-id to keep volume's uid/gid
  if [ "$(command -v podman)" ]; then
    userns="--userns=keep-id"
  else
    userns=""
  fi
  echo "$ ${docker} run ${userns} $@"
  ${prefix} ${docker} run ${userns} $@
}

execute_container() {
  run_args="-it --rm -v ${src}:/src -w=/src ${image}"
  docker_run ${run_args} $@
}

build_script() {
  entrypoint="--entrypoint /script/mk.sh"
  run_args="-it --rm -v ${src}:/src -w=/src"
  args="-d /src $@"
  docker_run ${run_args} ${entrypoint} ${image} ${args}
}

while getopts :hs:t: option; do
  case $option in
    h)
      echo "$usage"
      echo
      echo "Available Commands:"
      echo "  build                   Execute build script mk.sh"
      echo "  run                     Run container"
      echo "  create                  Create container image by Dockerfile"
      echo "Options"
      echo "  -h                      Print this usage and exit"
      echo "  -s <source directory>   Source directory"
      echo "  -t <image name>         Tagged name to apply to the built image or run"
      exit
      ;;
    t)
      image=${OPTARG}
      ;;
    s)
      src=${OPTARG}
      ;;
    \?)
      echo "Unknown option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Missing argument for -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [[ ${#} == 0 ]]; then
  # If source directory is given without other argument,
  # assume option is run container
  if [[ -d ${src} ]]; then
    option="run"
  else
    echo "$usage" >&2
    exit 0
  fi
else
  option=${1,,}
  shift
fi

case ${option} in
  "build")
    is_src_specified
    build_script $@
  ;;
  "create")
    create_image
  ;;
  "run")
    is_src_specified
    execute_container $@
  ;;
  *)
  echo "$usage" >&2
  exit 4
  ;;
esac
