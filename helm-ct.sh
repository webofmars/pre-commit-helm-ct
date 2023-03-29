#!/bin/bash

set -eu -o pipefail

CT_ARGS=("$@")

echo "+ running helm chart testing (ct) linter"

find . -name ct.yaml -exec dirname {} \; | while read -r ctdir; do
  echo "+ running ct lint from $ctdir"
  cd "$ctdir" || exit 1
  ct lint "${CT_ARGS}"
done

echo "+ helm chart testing (ct) linter completed"
exit 0
