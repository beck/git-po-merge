#!/bin/bash
# A git merge driver for repos with translations and i18n, the driver helps
# resolve .po file conflicts when merging or rebasing gettext catalogs.
# https://github.com/beck/git-po-merge
set -eu

# if additional options are ever added will need to use getopts
silent=false
if [ ${1:-loud} = '-s' ]
then
  silent=true
  shift
fi

if [ $# -ne 3 ]
then
  echo "usage: git-po-merge [-s] our.po base.po their.po"
  exit 1
fi

ours=$1
base=$2
theirs=$3


function log {
  if [ $silent = false ]
  then
    echo "$@"
  fi
}

function elog {
  log "$@" >&2
}

function verify_msgcat {
  if ! $(msgcat --version > /dev/null 2>&1)
  then
    elog
    elog "ERROR in git-po-merge: msgcat is not found."
    elog "  Installing gettext should include msgcat."
    elog "  Falling back to three way merge."
    elog
    git merge-file -L "ours" -L "base" -L "theirs" "$ours" "$base" "$theirs"
    exit 1
  fi
}

function get_langheader {
    grep -m 1 -e '^\"Language:\s.*\\n\"$' "$ours"
}

function get_pluralheader {
    grep -m 1 -e '^\"Plural-Forms:\s.*\\n\"$' "$ours"
}

function resolvepo {
  log -n "Resolving po conflict with git-merge-po... "
  local merge_opts="--sort-output --no-location --width=80"
  local headerpo=$(mktemp -t headers.XXXXXX.po)
  local temp=$(mktemp -t temp.XXXXXX.po)

  # fix gettext nonsense and noise from 3rd party tools
  local noise="-e /^#.Generated.by.grunt.*/d"
  noise="$noise -e s/charset=CHARSET/charset=UTF-8/"
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
  echo "$(get_langheader)" >> "$headerpo"
  echo "$(get_pluralheader)" >> "$headerpo"

  msgcat "$headerpo" "$temp" --use-first $merge_opts --output-file="$ours"

  # cleanup
  rm -rf "$temp" "$headerpo"
}


function rename_conflict_titles {
  # replace tempfile names with "ours", "theirs", "base"
  # msgcat shows confilcts using delimiter comments like:
  # #-#-#-#-#  .merge_file_IE83XW  #-#-#-#-#
  local temp=$(mktemp -t temp.XXXXXX.po)
  sed -e "s|$ours|ours|" -e "s|$theirs|theirs|" -e "s|$base|base|" "$ours" > "$temp"
  mv "$temp" "$ours"
}


function check_for_conflicts {
  # check if msgcat conflict comments are present
  if $(grep --silent "#-#-#-#-#" "$ours")
  then
    elog
    elog "CONFLICT, search for '#-#-#-#-#' in the po files."
    elog
    exit 1
  else
    log "done."
  fi
}

verify_msgcat
resolvepo
rename_conflict_titles
check_for_conflicts
