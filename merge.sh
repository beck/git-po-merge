#!/usr/bin/env bash
# Three-way gettext PO merge, adapted from Mikko Rantalainen (2021), MIT.
# https://stackoverflow.com/a/68799310
# Preserves the complete local PO header/preamble byte-for-byte.
set -Eeuo pipefail

if (( $# < 3 || $# > 4 )); then
    echo "Usage: $0 LOCAL BASE OTHER [PATH]" >&2
    exit 2
fi
LOCAL=$1
BASE=$2
OTHER=$3
FILENAME=${4:-$LOCAL}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TMPDIR_PO=$(mktemp -d)
trap 'rm -rf -- "$TMPDIR_PO"' EXIT

for tool in msguniq msgcat msgmerge msggrep msgattrib python3; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing required command: $tool" >&2
        exit 2
    fi
done

apply_template() { msgmerge --force-po --quiet --no-fuzzy-matching "$@"; }
only_conflicts() { msggrep --msgstr -F -e '#-#-#-#-#' -; }
without_conflicts() { msggrep -v --msgstr -F -e '#-#-#-#-#' -; }
extract_changes() {
    msgcat -o - "$1" "$2" \
        | only_conflicts \
        | apply_template -o - "$1" - \
        | msgattrib --no-obsolete
}

printf 'Merging PO: %s\n' "$FILENAME" >&2
msguniq --force-po --unique -o "$TMPDIR_PO/base" "$BASE"
msguniq --force-po --unique -o "$TMPDIR_PO/local" "$LOCAL"
msguniq --force-po --unique -o "$TMPDIR_PO/other" "$OTHER"

msgcat --force-po -o - "$TMPDIR_PO/base" "$TMPDIR_PO/local" "$TMPDIR_PO/other" \
    | without_conflicts > "$TMPDIR_PO/unchanged"
extract_changes "$TMPDIR_PO/local" "$TMPDIR_PO/base" > "$TMPDIR_PO/local-changes"
extract_changes "$TMPDIR_PO/other" "$TMPDIR_PO/base" > "$TMPDIR_PO/other-changes"

msgcat --force-po -o - "$TMPDIR_PO/other-changes" "$TMPDIR_PO/local-changes" \
    | only_conflicts > "$TMPDIR_PO/conflicts"
msgcat --force-po --unique -o "$TMPDIR_PO/local-only" "$TMPDIR_PO/local-changes" "$TMPDIR_PO/conflicts"
msgcat --force-po --unique -o "$TMPDIR_PO/other-only" "$TMPDIR_PO/other-changes" "$TMPDIR_PO/conflicts"
msgcat --force-po -o "$TMPDIR_PO/merge1" "$TMPDIR_PO/unchanged" \
    "$TMPDIR_PO/conflicts" "$TMPDIR_PO/local-only" "$TMPDIR_PO/other-only"
msgcat --force-po -o - "$TMPDIR_PO/local" "$TMPDIR_PO/other" \
    | apply_template -o "$TMPDIR_PO/merge2" "$TMPDIR_PO/merge1" -

# Do not pass the original header through msgcat; that loses some metadata.
python3 "$SCRIPT_DIR/preserve-po-header.py" "$LOCAL" "$TMPDIR_PO/merge2" "$TMPDIR_PO/merged"
# Only overwrite Git's %A after generating a complete output.
cp -- "$TMPDIR_PO/merged" "$LOCAL"

if grep -q -- '#-#-#-#-#' "$LOCAL"; then
    echo "PO translation conflicts detected in $FILENAME (search for #-#-#-#-#)." >&2
    exit 1
fi
exit 0
