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


## Examples

[madek](https://github.com/zhdk/madek)

```bash
$ git describe-semver --change=breaking "$(git describe --tags --always --long)"
3.0.0-beta.0+g4964c59
```

[cider-ci ui](https://github.com/cider-ci/cider-ci_user-interface)

```
$ GITDESC="$(git describe --tags --always --long)"
$ echo "$GITDESC"
cider-ci_2.3.2-1-g87eac85
$ git describe-semver --prefix="cider-ci_" "$GITDESC"
2.3.3-alpha.0+g87eac85
```

## Inspiration

- This issue:  
  [mojombo/semver #100: "Separate opinions from ordering logic in semver.org spec"](https://github.com/mojombo/semver/issues/100#issuecomment-91017920)
- Also this image:  
  !["You are technically correct. The best kind of correct."](https://cdn.rawgit.com/eins78/a48a54bc4b57e19437e7/raw/71195b6b20d67e08b54fa53edb2befb85c410eca/technically_correct_futurama.jpg)
