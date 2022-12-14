#!/usr/bin/env bash

# log($1: str)
log() {
	echo "$1" 1>&2
}

# f($1: f-str, $n...: args)
log::f() {
	local str
	printf -v str "$@"
	log "$str"
}

log::trace() {
	if [[ $GUARD_TRACE == 1 ]]; then
		 log "$1"
	fi
}
