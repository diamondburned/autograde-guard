#!/usr/bin/env bash

# json::get(json, key)
json::get() {
	# https://github.com/stedolan/jq/issues/354
	jq -rc "${@:3}" "$2 // empty" <<< "$1"
}

# json::getb(json, key)
#
# json::getb is like json::get, but it always returns a boolean value or null.
json::getb() {
	jq -rc "${@:3}" "$2 | if (type == \"boolean\") then . else null end" <<< "$1"
}

# json::obj([key, value]...)
#
# json::obj serializes the given argument pairs into a JSON object. If a name is
# suffixed with an exclamation mark (e.g. "key!"), then the value is assumed to
# be raw JSON. If the value is true or false, then raw JSON is implied.
json::obj() {
	local args=(--null-input)
	local objs=""
	local i

	for ((i = 1; i < $#; i++)); {
		local k="${!i}"
		i=$[i+1]
		local v="${!i}"

		local jarg=--arg
		if [[ $k == *"!" ]]; then
			k=${k::-1}
			jarg=--argjson
		fi

		# Handle ,omitempty.
		if [[ $k == *",omitempty" ]]; then
			# Trim the ,omitempty away.
			k=${k%*,omitempty}
			[[ $v == "" ]] && continue
		fi

		if [[ $v == "" && $jarg == "--argjson" ]]; then
			v=null
		fi

		args+=( $jarg "$k" "$v" )
		objs+="\$$k,"
	}

	jq --null-input "${args[@]}" "{ ${objs%*,} }"
}

# json::objvar(prefix)
# json::objvar() {
# 	# I'm unsure if this is the best way to do this. Either way, $1 is trusted,
# 	# so we should be fine.
# 	local vars=( $(eval "echo \${!${1}_@}") )
# 	local args=()

# 	for name in "${vars[@]}"; {
# 		local k="${name}"
# 		local v="${1}_${name}"
# 		args+=( "$k" "${!v}" )
# 	}
# }
