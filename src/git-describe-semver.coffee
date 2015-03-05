semver= require('semver')
contains= require('lodash').contains
validBumps= ['major', 'minor', 'patch']

# function to get a currently valid semver string from git-describe
# - needs a `string` from git-describe
# - needs to know which part of the version to `bump`
# - *decides* it's a pre-release if it is "ahead" of a tag
#     - bumps exisiting pre-release field if it exists or makes a new one
# - heavy lifting (repo queries, bumping…) is done by `git` and `node-semver`
semverFromGitDescribe= (conf = {})->
  gitDescription = conf.describe
  tagPrefix = conf.prefix || 'v'
  bump = conf.bump || 'patch'
  isDebug = isDebug || false
  fallbackVersion = '1.0.0'
  preReleaseChannel = 'alpha' # TODO: config/args

  unless contains(validBumps, bump)
    fail("`bump` must be one of: #{validBumps.join(', ')}")

  # when removing the input, only fail if a prefix was given
  input = removePrefix(gitDescription, tagPrefix, (strict= tagPrefix?))

  # parse the git description *or*
  # fallback: start a new version if we only get a hash (no tag exists)
  parsed = parseGitDescription(input) or {
    semver: semver('1.0.0-beta.0')
    isAhead: false
    gitmeta: "+g#{gitDescription}" if /^[0-9a-f]+$/.test(gitDescription)
  }

  semver =
    # increment only if commit is ahead of tag
    unless parsed?.isAhead
      parsed.semver
    else
      bumpLevel = switch
        # set pre-release field name if present!
        when (parsed.semver.prerelease?.length>0)
          if (typeof parsed.semver.prerelease[0] is 'string')
            preReleaseChannel = parsed.semver.prerelease[0]
          'prerelease'
        # otherwise make new pre-release according to 'bump'
        else
          # TODO: make a non-"pre" bump if args.release!
          "pre#{bump}"

      semver(parsed.semver.raw)
        .inc(bumpLevel, preReleaseChannel)

  meta = if parsed?.gitmeta? then parsed.gitmeta else gitDescription or null
  version = semver.version + if meta? then "+#{meta}" else ''

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
  splitted = regex.exec(string)

  # fallback if no match (likely hash-only)
  return null unless splitted?

  [res, version, ahead, gitmeta] = splitted

  unless res? and version? and ahead? and gitmeta?
    fail('git-description invalid! Is it `--long` and prefix-free?')

  return {
    semver: semver(version)
    isAhead: (ahead > 0)
    gitmeta: if gitmeta? then gitmeta
  }

isOneOf= (validThings, thing)->
  validThings.map (validThing)-> thing is validThing
    .reduce (bool, res)-> res || bool

mapChangesToBumplevel= (string)->
  map = { breaking: 'major', feature: 'minor', bugfix: 'patch' }
  map[string] if map[string]?


removePrefix= (string = '', prefix = '', strict = false)->
  unless (typeof string is 'string' and typeof prefix is 'string')
    fail('args! `string` and `prefix` must be strings!')

  unless (string.indexOf(prefix) is 0 and prefix.length > 0)
    string.slice(prefix.length)
  else
    fail('prefix not present at start of string!') if strict
    string

fail= (msg)->
  return { error: msg }

# ---

module.exports = semverFromGitDescribe
