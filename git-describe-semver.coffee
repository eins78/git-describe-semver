#!/usr/bin/env coffee

# deps and global state
semver= require('semver')
argsParser= require('minimist')
debug= false # set to true with `--debug`

# ---

# function to get a currently valid semver string from git-describe
# - needs a `string` from git-describe
# - needs to know which part of the version to `bump`
# - *decides* it's a pre-release if it is "ahead" of a tag
#     - bumps exisiting pre-release field if it exists or makes a new one
# - heavy lifting (repo queries, bumping…) is done by `git` and `node-semver`
semverFromGitDescribe= (gitDescription, bump = 'patch', tagPrefix)->
  fallbackVersion = '1.0.0'
  preReleaseChannel = 'alpha' # TODO: config/args

  unless isValidBump
    fail("`bump` must be one of #{validBumps.join(', ')}")

  input = removePrefix(gitDescription, tagPrefix, (strict= tagPrefix?))
  parsed = parseGitDescription(input, fallbackVersion)

  semver = do ->
    # increment if commit is ahead of tag
    return parsed.semver unless parsed.isAhead
    bumpLevel = do ->
      # bump pre-release field if present!
      if (parsed.semver.prerelease?.length>0)
        if (typeof parsed.semver.prerelease[0] is 'string')
          preReleaseChannel = parsed.semver.prerelease[0]
        return 'prerelease'
      # otherwise make new pre-release according to 'bump'
      # TODO: make a non-"pre" bump if args.release!
      return "pre#{bump}"

    semver(parsed.semver.raw)
      .inc(bumpLevel, preReleaseChannel)

  version = "#{semver.version}+#{parsed.gitmeta}"

  return {
    raw: gitDescription
    parsed: parsed
    SemVer: semver
    version: version
  }

# helpers:

parseGitDescription= (string, fallbackVersion)->
  # string must be of format 'versionFromTag-ahead-gitmeta',
  # without any prefixes (like 'v')!
  regex = ///
    ^                       # - start of string
    \s?                     # - allow whitespace
    (                       # - tag
      \d+.\d+.\d+           #     - major.minor.patch
      (?:                   #     - prerelease/meta (optional)
        [A-Za-z\d\.\-]+)?   #         - alphanumerics, hyphens and dots
    )                       #
    -(\d+)                  # - number of commits 'ahead'
    -(g[0-9a-f]+)           # - short hash with leading 'g'
    \s?                     # - allow whitespace
    $                       # - end of string
  ///


  [res, version, ahead, gitmeta] =
    if (splitted = regex.exec(string))?
      splitted
    else # fallback: start a new version if we only get a hash (no tag exists)
      hash = string if /[0-9a-f]+/.test(string)
      [true, fallbackVersion, 1, "g#{hash}"]


  unless res? and version? and ahead? and gitmeta?
    fail('git-description invalid! Is it `--long` and prefix-free?')

  parsed = {
    semver: semver.parse(version)
    isAhead: (ahead > 0)
    gitmeta: if gitmeta? then gitmeta
  }
  return parsed

isValidBump= (bump)->
  ['major', 'minor', 'patch']
    .map (validBump)-> bump is validBump
    .reduce (bool, res)-> res || bool

mapChangesToBumplevel= (string)->
  map = { breaking: 'major', feature: 'minor', bugfix: 'patch' }
  map[string] if map[string]?


removePrefix= (string, prefix = 'v', strict = false)->
  unless typeof string is 'string' and typeof prefix is 'string'
    fail('args! `string` and `prefix` must be strings!')
  return if string.indexOf(prefix) is 0
    string.slice prefix.length
  else
    fail('prefix not present at start of string!') if strict
    string

fail= (msg)->
  console.error('ERROR! ' + msg)
  process.exit(1)

debug= (msg)->
  console.error(msg) if debug

# --- CLI ---

do main= ->
  args = argsParser(process.argv.slice(2)) # see README.md

  # input string (from git-describe --long) comes from
  # first unamed arg or arg called 'describe'
  describe = args._?[0] || args.describe
  bump = switch
    when args.bump? then args.bump
    when args.change? then mapChangesToBumplevel(args.change)

  console.log 'args', args
  console.log 'describe', describe

  unless describe?
    fail('missing input! hint: `--describe="1.0.0-0-g1234abcd"`')

  # run function on the args
  result= semverFromGitDescribe(describe, bump, args.prefix)

  # output the result as simple string or JSON as requested
  if (args.json)
    console.log(JSON.stringify(result, 0, 2))
  else
    console.log(result.version)
