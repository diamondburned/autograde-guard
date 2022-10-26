## Conventions

### Cases

```sh
CONSTANTS_ARE=UPPER_SNAKE_CASED

FunctionsArePascalCased() {
	local variables_are_snake_cased=""
}
```

### Commenting/Documentation

```sh
$ cat libraryname.sh
#!/usr/bin/env bash

. config.sh
. lib/import1.sh
. lib/import2.sh

# libraryname()
#
# libraryname is the only non-namespaced function allowed in the file. It must
# have the same name as the file (without the extension).
libraryname() {}

# libraryname::functionName($1: var1, $2: var2, ...) -> bool
#
# libraryname::functionName is ABC...
libraryname::functionName() {}

# libraryname::functionName2($1: var1, $2: var2, ...)
#
# libraryname::functionName2 is ABC...
libraryname::functionName2() {}
```

### Variables

- All function variables **must** be `local`. Function `main` is exempt from
  this rule.
- Non-local functions must have an appropriate prefix, preferably the filename
  (without the extension).
