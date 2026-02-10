#!/bin/bash


# Function to check if a given directory is clean in git
git_check_clean() {
    local dir_rel="$1"
    if ! test -z "$(git status --porcelain "./${dir_rel}")"; then
        echo "Validation failed: Workspace is inconsistent in directory: ${dir_rel}."
        git status "./${dir_rel}"
        exit 1
    fi
}


# Command dispatch using case statement
case "$1" in
    git_check_clean)
        shift
        git_check_clean "$@"
        ;;
    *)
        echo "Usage: $0 {git_check_clean} [args...]"
        exit 1
        ;;
esac
