# git-po-merge changelog

## 0.2.0 (2026-12-21)

* This release replaces the previous PO merge algorithm with a proper three-way merge implementation that preserves PO headers and metadata.
  Python 3 with python3-polib is now required (at least recommended) in addition to GNU gettext and Bash. Fixes ([#6](3]).

[3]: https://github.com/beck/git-po-merge/issues/6

## 0.1.0 (2015-11-20)

* Keep language and plural form headers, fixes ([#2][2])

[2]: https://github.com/beck/git-po-merge/issues/2


## 0.0.1 (2015-03-28)

* Initial Release ([#1][1])

[1]: https://github.com/beck/git-po-merge/pull/1
