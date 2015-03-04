# git-describe-semver 🌿📝📦

> Always get a valid SemVer from `$(git-describe --long)`!

Proof-of-concept, requires globally installed CoffeeScript
at the moment (`/usr/bin/env coffee`).
Will be published to npm in compiled js form.


## Quickstart

```bash
# install as globally as a "git plugin"
(sudo) npm install --global https://github.com/eins78/git-describe-semver/tarball/master
# or: install dev version and link globally
git clone https://github.com/eins78/git-describe-semver/
cd git-describe-semver
(sudo) npm link

# Use it as a CLI:
# needs: input string from git + either 'bump' or 'change'
git describe-semver "$(git describe --tag --always --long)"\
  [--bump="minor" | --change="feature"] \
  [--prefix "v"] [--json]
```

## CLI Arguments

### version

*String*, the input from `$(git describe --tag --always --long)`  
  can be given as first unnamed argument or as `--version`

### change | bump

What to increment if git is ahead of a tag?

- *either:* `--bump <major|minor|path>`
- *or:*     `--change <breaking|feature|bugfix>`

(If both )

### prefix

*String* to cut from start of tag names.  
Defaults to 'v', as in `v1.0.0-alpha.1`.

### json

*Bool* `--json` switches output to JSON format.
