#!/usr/bin/env bash
set -euo pipefail

source_repo="${1:-}"
source_ref="${2:-}"
destination="${3:-}"

if [[ -z "${source_repo}" || -z "${source_ref}" || -z "${destination}" ]]; then
  echo "Usage: $0 <local-fdaPDE-cpp-repository> <ref> <destination>" >&2
  exit 1
fi
if [[ ! -d "${source_repo}/.git" && ! -f "${source_repo}/.git" ]]; then
  echo "Error: FDAPDE_CPP_REPOSITORY must be a local git checkout: ${source_repo}" >&2
  exit 1
fi

source_repo="$(cd "${source_repo}" && pwd)"
commit="$(git -C "${source_repo}" rev-parse "${source_ref}^{commit}")"
mkdir -p "$(dirname "${destination}")"

if [[ ! -d "${destination}/.git" ]]; then
  git clone --no-checkout "${source_repo}" "${destination}"
else
  git -C "${destination}" fetch --quiet "${source_repo}" "${source_ref}"
fi

git -C "${destination}" checkout --quiet --detach "${commit}"

submodule_args=(submodule update --init --checkout fdaPDE/core)
if [[ -d "${source_repo}/fdaPDE/core/.git" || -f "${source_repo}/fdaPDE/core/.git" ]]; then
  git -C "${destination}" \
    -c protocol.file.allow=always \
    -c "submodule.fdaPDE/core.url=${source_repo}/fdaPDE/core" \
    "${submodule_args[@]}"
else
  git -C "${destination}" "${submodule_args[@]}"
fi

printf 'Prepared %s at %s (%s)\n' "${source_ref}" "${destination}" "${commit}"
