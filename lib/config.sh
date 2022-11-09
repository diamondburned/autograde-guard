#!/usr/bin/env bash

ConfigFile="./config.toml"

config::_get() {
	taplo get -f "$ConfigFile" "${@:2}" "$1"
}

# config::get(key, opts...)
config::get() {
	if config::_get "$@" 2> /dev/null; then
		# Bail if taplo didn't complain. If it did, then we'll have to do
		# something fun...
		return 0
	fi

	# We want to return an empty value if the key does not exist, but we don't
	# really want to exit 0 on any error. Our best way to do this is to just...
	# compare stderr.
	local out=$(config::_get "$@" 2>&1)
	if [[ "$out" == *"error=no values matched the pattern"* ]]; then
		return 0
	fi

	return 1
}

# config::array_into(array_name, key, opts...)
config::array_into() {
	IFS=$'\n' readarray -t "$1" < <(config::get "$2" "${@:3}")
}
