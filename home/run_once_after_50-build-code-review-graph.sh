#!/usr/bin/env bash

set -euo pipefail

git_root() {
	git -C "$1" rev-parse --show-toplevel 2>/dev/null
}

resolve_repository_location() {
	local path root

	if [ -n "${REPOSITORY_LOCATION:-}" ]; then
		git_root "$REPOSITORY_LOCATION"
		return
	fi

	for path in "${GITHUB_WORKSPACE:-}" "${CODESPACE_VSCODE_FOLDER:-}"; do
		if [ -n "$path" ] && root="$(git_root "$path")"; then
			printf '%s\n' "$root"
			return
		fi
	done

	declare -A roots=()
	while IFS= read -r -d '' path; do
		if root="$(git_root "$path")"; then
			roots["$(realpath -m "$root")"]=1
		fi
	done < <(find /workspaces -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

	if [ "${#roots[@]}" -eq 1 ]; then
		printf '%s\n' "${!roots[@]}"
		return
	fi

	if [ "${#roots[@]}" -eq 0 ]; then
		printf '%s\n' 'Could not find a Git worktree in /workspaces; set REPOSITORY_LOCATION.' >&2
	else
		printf '%s\n' 'Found multiple Git worktrees in /workspaces; set REPOSITORY_LOCATION to choose one:' >&2
		printf '  %s\n' "${!roots[@]}" >&2
	fi
	return 1
}

repository_location="$(resolve_repository_location)"
code-review-graph build --repo "$repository_location"
