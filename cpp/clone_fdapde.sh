#!/usr/bin/env bash
set -euo pipefail

source_repo="${1:-}"
outer_branch="${2:-}"
destination="${3:-}"

if [[ -z "${source_repo}" || -z "${outer_branch}" || -z "${destination}" ]]; then
  echo "Usage: $0 <local-fdaPDE-cpp-repository> <outer-branch> <destination>" >&2
  exit 1
fi
if [[ ! -d "${source_repo}/.git" && ! -f "${source_repo}/.git" ]]; then
  echo "Error: FDAPDE_CPP_REPOSITORY must be a local git checkout: ${source_repo}" >&2
  exit 1
fi

source_repo="$(cd "${source_repo}" && pwd)"
source_core="${source_repo}/fdaPDE/core"

# Validate the approved outer/core branch pairing before using the outer gitlink.
case "${outer_branch}" in
  develop-Splines|develop_splines)
    core_branch="develop-splines"
    ;;
  develop_RGCCA)
    core_branch="develop-RGCCA"
    ;;
  develop_fPLS)
    core_branch="develop-fPLS"
    ;;
  *)
    echo "Error: no core branch mapping for outer branch ${outer_branch}" >&2
    exit 1
    ;;
esac

outer_commit="$(git -C "${source_repo}" rev-parse "${outer_branch}^{commit}")"
core_commit="$(git -C "${source_repo}" ls-tree "${outer_commit}" fdaPDE/core | awk '{print $3}')"
mapped_core_commit="$(git -C "${source_core}" rev-parse "${core_branch}^{commit}")"

if [[ -z "${core_commit}" ]]; then
  echo "Error: ${outer_branch} does not record the fdaPDE/core submodule" >&2
  exit 1
fi
if [[ "${mapped_core_commit}" != "${core_commit}" ]]; then
  echo "Error: ${outer_branch} records core ${core_commit}, but ${core_branch} is ${mapped_core_commit}" >&2
  exit 1
fi
if ! git -C "${source_core}" cat-file -e "${core_commit}^{commit}"; then
  echo "Error: core commit ${core_commit} is missing from ${source_core}" >&2
  exit 1
fi

mkdir -p "$(dirname "${destination}")"

if [[ ! -d "${destination}/.git" ]]; then
  git clone --no-checkout "${source_repo}" "${destination}"
else
  git -C "${destination}" fetch --quiet "${source_repo}" "${outer_branch}"
fi

git -C "${destination}" checkout --quiet --detach "${outer_commit}"

# Use only the local source submodule and checkout the commit recorded by outer.
git -C "${destination}" config submodule.fdaPDE/core.url "${source_core}"
git -C "${destination}" -c protocol.file.allow=always \
  submodule update --init --checkout fdaPDE/core

checked_out_core="$(git -C "${destination}/fdaPDE/core" rev-parse HEAD)"
if [[ "${checked_out_core}" != "${core_commit}" ]]; then
  echo "Error: expected core ${core_commit}, checked out ${checked_out_core}" >&2
  exit 1
fi

printf 'Prepared %s at %s (%s); core %s (%s)\n' \
  "${outer_branch}" "${destination}" "${outer_commit}" "${core_branch}" "${core_commit}"
