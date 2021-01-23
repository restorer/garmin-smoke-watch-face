#!/bin/bash

set -e
cd "$(dirname "$0")"

do_convert () {
    FOLDER="$1"
    SCALE="$2"

    find "$FOLDER" -name 'render_*.png' -print \
        | xargs -n 1 basename \
        | xargs -n 1 -I '{}' convert "${FOLDER}/{}" -scale "$SCALE" -ordered-dither o3x3,4 -depth 2 "${FOLDER}/${SCALE}_{}"
}

do_convert smoke 218x218
do_convert smoke 260x260
