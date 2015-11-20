# git-po-merge
[![Build Status](https://travis-ci.org/beck/git-po-merge.svg?branch=master)](https://travis-ci.org/beck/git-po-merge)
[![npm version](https://badge.fury.io/js/git-po-merge.svg)](http://badge.fury.io/js/git-po-merge)

A git merge driver for repos with translations and i18n, the driver helps
resolve .po file conflicts when merging or rebasing gettext catalogs.


## Install

Git-po-merge requires `msgcat`, a tool included when installing `gettext`.

Try:
```
msgcat --version
```

If missing and using OSX, gettext is available via homebrew:
```
brew install gettext
brew link gettext --force
```

### Install and update git config

This can be done one of two ways, globally or per-project/directory:

#### Globally

Install:
```sh
npm install --global git-po-merge
```

Add to `~/.gitconfig`:
```ini
[core]
    attributesfile = ~/.gitattributes
[merge "pofile"]
    name = custom merge driver for gettext po files
    driver = git-po-merge %A %O %B
```

Create `~/.gitattributes`:
```ini
*.po merge=pofile
*.pot merge=pofile
```

#### Single project / directory

Install:
```sh
npm install git-po-merge --save-dev
```

Update git config:
```sh
git config merge.pofile.driver "$(npm bin)/git-po-merge %A %O %B"
git config merge.pofile.name "custom merge driver for gettext po files"
```

Add the same `.gitattributes` where desired and commit.  
Note `.gitattributes` is only used after committed.


### Verify install

```
git-po-merge  # or $(npm bin)/git-po-merge
> usage: git-po-merge [-s] our.po base.po their.po

touch messages.po
git check-attr -a messages.po
> messages.po: merge: pofile

git-po-merge messages.po messages.po messages.po
> Resolving po conflict with git-merge-po... done.

git merge [some branch with translation changes that conflict]
> Resolving po conflict with git-merge-po... done.
> Resolving po conflict with git-merge-po... done.
> Auto-merging project/locale/fr/LC_MESSAGES/messages.po
> Auto-merging project/locale/es/LC_MESSAGES/messages.po
```


## Notes and caveats

Git only calls the driver in the event of a conflict and will always
attempt a traditional 3-way merge first.

The git-merge-po driver will restore messages marked obsolete if the message
is active in any po being merged. Good practice is to remake messages after
any merge or rebase.


## Dev

```
node --version # using v0.12
npm install --global .
npm link
npm test
```

Helpful docs:
* http://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver
* http://stackoverflow.com/questions/28026767/where-should-i-place-my-global-gitattributes-file

Thanks:
* https://gist.github.com/mezis/1605647
* http://stackoverflow.com/questions/16214067/wheres-the-3-way-git-merge-driver-for-po-gettext-files
