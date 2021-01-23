#!/usr/bin/env bash
set -uo pipefail

# TODO: remove BM_SRC

# shellcheck source=/dev/null
source "$BM_SRC/util.sh"

[[ -z ${BM_DATA:-''} ]] && BM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/bm"
[[ -z ${BM_SRC:-''} ]] && {
	echo "Error: Must set '\$BM_SRC'"
	exit 1
}

[[ -d $BM_SRC ]] || {
	echo "Error: '\$BM_SRC' must be a directory"
	exit 1
}

mkdir -p "$BM_DATA"
mkdir -p "$BM_DATA/bin"
mkdir -p "$BM_DATA/man"

main() {
	[[ $* =~ --help ]] && {
		show_help
		exit
	}

	: "${1:?"Error: First arg (subcommand) not found"}"
	local -r subcommand=$1

	case "$subcommand" in
	install)
		: "${2:?"Error: Second arg (package) not found"}"
		local -r package="$2"

		# shellcheck source=/dev/null
		source "$BM_SRC/packages/common.sh"
		do_install "$package"
		;;
	uninstall)
		: "${2:?"Error: main: uninstall: Second arg (package) not found"}"
		local -r package="$2"

		rm "$BM_DATA/bin/$package"
		;;
	list)
		# TODO: fix shouldn't show files
		for folder in "$BM_SRC"/packages/*; do
			echo "${folder##*/}"
		done
		;;
	*)
		log_error "No matching subcommand found. Exiting"
		show_help
		exit 1
		;;
	esac
}

do_install() {
	: "${1:?"Internal Error: do_install: First arg (package) not found"}"
	local -r package="$1"

	# test if already installed
	# improve heuristic (maybe have list of text file)
	[[ -e $BM_DATA/bin/$package ]] && {
		log_info "Info: do_install: Package '$package' already installed"
		exit
	}

	# install
	pushd "$(mktemp -d)" &>/dev/null

	debug "doInstall: tempFolder: $PWD"
	debug "doInstall: \$1: $package"

	source "$BM_SRC/packages/$package/package.sh"

	pkg_install
	code="$?"

	unset -f pkg_install
	popd &>/dev/null
}

main "$@"
