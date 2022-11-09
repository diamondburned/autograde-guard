#!/usr/bin/env bash

# env::keys_prefix($1: prefix) -> envs
#
# env::keys_prefix returns all environment variables with the given prefix. The
# input argument MUST BE TRUSTED!
env::keys_prefix() {
	# Terrible.
	eval "printf '%q\n' \${!${1}*}"
}

# env::clear($n...: envs)
#
# env::clear clears the given environment variables.
env::clear() {
	for env in "$@"; do
		unset "${env}"
	done
}

# env::clear_prefix($1: prefix)
#
# env::clear_prefix clears all environment variables with the given prefix. The
# input argument MUST BE TRUSTED!
env::clear_prefix() {
	env::clear $(env::keys_prefix "${1}")
}
