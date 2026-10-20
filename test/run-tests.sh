#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MERGE="$ROOT/merge.sh"
UPDATE=false
FAILED=0
PASSED=0

case "${1:-}" in
    "") ;;
    --update) UPDATE=true ;;
    *)
        echo "Usage: $0 [--update]" >&2
        exit 2
        ;;
esac

while IFS= read -r -d '' expected; do
    dir="${expected%/*}"
    actual="$(mktemp --suffix=.po)"

    cp -- "$dir/ours.po" "$actual"


    # Test directories containing "fail" expect a non-zero exit code.
    should_fail=false
    if [[ "${dir##*/}" == *fail* ]]; then
        should_fail=true
    fi

    # Merge drivers modify the first argument in place.
    merge_status=0
    "$MERGE" "$actual" "$dir/base.po" "$dir/theirs.po" || merge_status=$?

    status_ok=false
    if [[ "$should_fail" == true && "$merge_status" -ne 0 ]] ||
       [[ "$should_fail" == false && "$merge_status" -eq 0 ]]; then
        status_ok=true
    fi

    if [[ "$UPDATE" == true ]]; then
        cp -- "$actual" "$expected"
        echo "UPDATED $dir (merge exit: $merge_status)"
        ((PASSED+=1))
    elif diff -u -- "$expected" "$actual" && [[ "$status_ok" == true ]]; then
        echo "PASS    $dir (merge exit: $merge_status)"
        echo
        ((PASSED+=1))
    else
        echo "FAIL    $dir (merge exit: $merge_status, expected failure: $should_fail)"
        echo
        ((FAILED+=1))
    fi

    rm -f -- "$actual"
done < <(find "$ROOT/test" -name expected.po -type f -print0)

echo
echo "Results: $PASSED passed, $FAILED failed"

if (( FAILED > 0 )); then
    exit 1
fi
