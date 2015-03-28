#!/bin/bash
set -eu

ours=$1
base=$2
theirs=$3


}


function verify_msgcat {
  if ! $(msgcat --version > /dev/null 2>&1)
  then
    echo
    echo "ERROR in git-po-merge: msgcat is not found."
    echo "  Installing gettext should include msgcat."
    echo "  Falling back to three way merge."
    echo
    git merge-file -L "ours" -L "base" -L "theirs" "$ours" "$base" "$theirs"
    exit 1
  fi
}


function resolvepo {
  echo -n "Resolving po conflict with git-merge-po... "
  local merge_opts="--sort-output --no-location --width=80"
  local headerpo=$(mktemp -t headers.po)
  local temp=$(mktemp -t temp.po)

  # remove noise from 3rd party tools
  local noise="-e /^#.Generated.by.grunt.*/d"
  cp "$ours" "$temp" && sed $noise "$temp" > "$ours"
  cp "$base" "$temp" && sed $noise "$temp" > "$base"
  cp "$theirs" "$temp" && sed $noise "$temp" > "$theirs"

  # reduce all three to a single file
  msgcat "$base" "$ours" "$theirs" $merge_opts --output-file="$temp"

  # set a minimalist header
  echo 'msgid ""' >> "$headerpo"
  echo 'msgstr ""' >> "$headerpo"
  echo '"Content-Type: text/plain; charset=UTF-8\n"' >> "$headerpo"
  echo '"MIME-Version: 1.0\n"' >> "$headerpo"
  msgcat "$headerpo" "$temp" --use-first $merge_opts --output-file="$ours"

  # cleanup
  rm -rf "$temp" "$headerpo"
}


function rename_conflict_titles {
  # replace tempfile names with "ours", "theirs", "base"
  # msgcat shows confilcts using delimiter comments like:
  # #-#-#-#-#  .merge_file_IE83XW  #-#-#-#-#
  local temp=$(mktemp -t temp.po)
  sed -e "s|$ours|ours|" -e "s|$theirs|theirs|" -e "s|$base|base|" "$ours" > "$temp"
  mv "$temp" "$ours"
}


function check_for_conflicts {
  # check if msgcat conflict comments are present
  if $(grep --silent "#-#-#-#-#" "$ours")
  then
    echo
    echo "CONFLICT, search for '#-#-#-#-#' in the po files."
    echo
    exit 1
  else
    echo "done."
  fi
}

verify_msgcat
resolvepo
rename_conflict_titles
check_for_conflicts
