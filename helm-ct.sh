#!/bin/bash

# shellcheck disable=SC2034

set -eu -o pipefail

CT_ARGS=("$@")

echo "+ setting a clean helm environment"
HELM_HOME="$(mktemp -d)"

HELM_CACHE_HOME="$HELM_HOME/cache"
HELM_CONFIG_HOME="$HELM_HOME/config"
HELM_DATA_HOME="$HELM_HOME/data"

KUBECONFIG="$(mktemp -d)/kubeconfig"
touch "$KUBECONFIG" && chmod 600 "$KUBECONFIG"

echo "+ building helm dependencies"
INITIAL_DIR="$(realpath .)"
find . -name Chart.yaml -exec dirname {} \; | while read -r chartdir; do
  echo "+ building dependencies for $chartdir"
  cd "$chartdir" || exit 1
  i=0; for url in $(yq '.dependencies' Chart.yaml -o=json | jq -r '.[].repository'); do
    echo "${url}" | grep -qE '^(https?|git)://' || continue
    i=$((i+1)); helm repo add repo-${i} "${url}"
    helm repo update repo-${i}
  done
  cd - || exit 1
done
cd "$INITIAL_DIR" || exit 1

echo "+ running helm chart testing (ct) linter"

find . -name ct.yaml -exec dirname {} \; | while read -r ctdir; do
  echo "+ running ct lint from $ctdir"
  cd "$ctdir" || exit 1
  set -x
  ct lint "${CT_ARGS[@]}"
done

echo "+ cleaning helm environment"
rm -rf "$HELM_HOME"

echo "+ helm chart testing (ct) linter completed"
exit 0
