# po-merge
A git merge driver for .PO files


## Install

### Install merge driver:
```
npm install --global git-po-merge
```

### Update git config.

This can be done one of two ways, per-project or globally.

#### Globally

Add to `~/.gitconfig`:
```
[core]
    attributesfile = ~/.gitattributes
[merge "pofile"]
    name = custom merge driver for gettext po files
    driver = git-po-merge %A %O %B
```

Create `~/.gitattributes`:
```
*.po merge=pofile
*.pot merge=pofile
```

#### Locally

Add a `.gitattributes` and add merge to config.

Note, `.gitattributes` is only used after committed.

### Verify git config

```
 $ git check-attr -a messages.po
messages.po: merge: pofile
```


## Notes and caveats

Git only calls the driver in the event of a conflict and will always
attempt a traditional 3-way merge first.

The git-merge-po driver will restore messages marked obsolete if the message
is active in any po being merged. Good practice is to remake messages after
any merge or rebase.


## Dev

```
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
