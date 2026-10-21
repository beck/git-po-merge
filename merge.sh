#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Mikko Rantalainen
#
# A git merge driver for repos with translations and i18n, the driver helps
# resolve .po file conflicts when merging or rebasing gettext catalogs.
# https://github.com/beck/git-po-merge
#
# Three-way gettext PO merge, adapted from <https://stackoverflow.com/a/68799310>,
# to preserve the complete local PO header/preamble.
set -Eeuo pipefail

SILENT=false
if [[ ${1:-} == "-s" ]]; then
    SILENT=true
    shift
fi

if (( $# < 3 || $# > 4 )); then
    echo "Usage: $0 [-s] LOCAL BASE OTHER [PATH]" >&2
    exit 2
fi

LOCAL=$1
BASE=$2
OTHER=$3
FILENAME=${4:-$LOCAL}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TMPDIR_PO=$(mktemp -d)
trap 'rm -rf -- "$TMPDIR_PO"' EXIT

for tool in msguniq msgcat msgmerge msggrep msgattrib; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing required command: $tool" >&2
        exit 2
    fi
done

read -r -a merge_opts <<< "${GIT_PO_MERGE_OPTS:---sort-output --no-location --width=80}"

apply_template() { msgmerge --force-po --quiet --no-fuzzy-matching "$@"; }
only_conflicts() { msggrep --msgstr -F -e '#-#-#-#-#' -; }
without_conflicts() { msggrep -v --msgstr -F -e '#-#-#-#-#' -; }
extract_changes() {
    msgcat -o - "$1" "$2" \
        | only_conflicts \
        | apply_template -o - "$1" - \
        | msgattrib --no-obsolete
}
normalize_charset() {
    # FIXME: this replaces charset=CHARSET also in translation strings
    sed -e "/^#.Generated.by.grunt.*/d" -e 's/charset=CHARSET/charset=UTF-8/' "$1" > "$2"
    # python3 "$SCRIPT_DIR/normalize-po-charset.py" "$1" "$2"
}

if [[ $SILENT == false ]]; then
    printf 'Merging PO: %s\n' "$FILENAME" >&2
fi

if [[ ${DEBUG_PO_MERGE:-0} == 1 ]]; then
    set -x
fi

# Normalize gettext charset placeholders in temporary copies only.
normalize_charset "$BASE" "$TMPDIR_PO/base-input.po"
normalize_charset "$LOCAL" "$TMPDIR_PO/local-input.po"
normalize_charset "$OTHER" "$TMPDIR_PO/other-input.po"

msguniq --force-po --unique -o "$TMPDIR_PO/base" "$TMPDIR_PO/base-input.po"
msguniq --force-po --unique -o "$TMPDIR_PO/ours.po" "$TMPDIR_PO/local-input.po"
msguniq --force-po --unique -o "$TMPDIR_PO/theirs.po" "$TMPDIR_PO/other-input.po"

msgcat --force-po -o - "$TMPDIR_PO/base" "$TMPDIR_PO/ours.po" "$TMPDIR_PO/theirs.po" \
    | without_conflicts > "$TMPDIR_PO/unchanged"
extract_changes "$TMPDIR_PO/ours.po" "$TMPDIR_PO/base" > "$TMPDIR_PO/local-changes"
extract_changes "$TMPDIR_PO/theirs.po" "$TMPDIR_PO/base" > "$TMPDIR_PO/other-changes"

msgcat --force-po -o - "$TMPDIR_PO/other-changes" "$TMPDIR_PO/local-changes" \
    | only_conflicts > "$TMPDIR_PO/conflicts"
msgcat --force-po --unique -o "$TMPDIR_PO/local-only" "$TMPDIR_PO/local-changes" "$TMPDIR_PO/conflicts"
msgcat --force-po --unique -o "$TMPDIR_PO/other-only" "$TMPDIR_PO/other-changes" "$TMPDIR_PO/conflicts"
msgcat --force-po -o "$TMPDIR_PO/merge1" "$TMPDIR_PO/unchanged" \
    "$TMPDIR_PO/conflicts" "$TMPDIR_PO/local-only" "$TMPDIR_PO/other-only"
msgcat --force-po -o - "$TMPDIR_PO/ours.po" "$TMPDIR_PO/theirs.po" \
    | apply_template -o "$TMPDIR_PO/merge2" "$TMPDIR_PO/merge1" -

if command -v python3 >/dev/null 2>&1 && python3 -c 'import polib' 2> /dev/null; then
    # preserve the original PO header, including SPDX and metadata.
    python3 "$SCRIPT_DIR/preserve-po-header.py" "$BASE" "$LOCAL" "$OTHER" "$TMPDIR_PO/merge2" "$TMPDIR_PO/merged"

    # only overwrite Git's %A after generating the complete output

    # cp -- "$TMPDIR_PO/merged" "$LOCAL"
    msgcat --force-po --width=80 --use-first "${merge_opts[@]}" -o "$TMPDIR_PO/formatted" "$TMPDIR_PO/merged"

    cp -- "$TMPDIR_PO/formatted" "$LOCAL"
else
    echo "git-po-merge: warning: Python 3 not found; PO header metadata may be lost" >&2
    cp -- "$TMPDIR_PO/merge2" "$LOCAL"
fi

if grep -q -- '#-#-#-#-#' "$LOCAL"; then
    echo "PO translation conflicts detected in $FILENAME (search for #-#-#-#-#)." >&2
    exit 1
fi
exit 0
