#!/usr/bin/env bash

ConfigFile="./config.toml"

# config::get(key, opts...)
config::get() {
	taplo get -f "$ConfigFile" "${@:2}" "$1"
}

# config::array_into(array_name, key, opts...)
config::array_into() {
	IFS=$'\n' readarray -t "$1" < <(config::get "$2" "${@:3}")
}
