#!/usr/bin/env bash
set -e
gomplate -f validate.tmpl.html -o output/validate/tampered.html
echo "Wrote to output/validate/tampered.html."
