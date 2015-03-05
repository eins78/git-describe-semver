# (this is put put into shell script template on compile)

# deps and global state
argsParser= require('minimist')
semverFromGitDescribe= require('..')
isDebug= false


main= ->
  # - arguments/options
  args= argsParser(process.argv.slice(2)) # see README.md
  isDebug= args.debug || isDebug
  opts= {}

  # input string (from git-describe --long) comes from
  # first unamed arg or arg called 'describe'
  opts.describe= args._?[0] || args.describe
  opts.bump= switch
    when args.bump? then args.bump
    when args.change? then mapChangesToBumplevel(args.change)
  opts.prefix= if (typeof args.prefix is 'string') then args.prefix else 'v'
  opts.json= !!args.json || false
  opts.isDebug= isDebug

  debug('args', args)
  debug('opts', opts)

  unless opts.describe?
    fail('missing input! hint: `--describe="1.0.0-3-g1234abcd"`')

  # - run module on options
  result= semverFromGitDescribe([
    opts.describe, opts.bump, opts.prefix, opts.isDebug
  ])
  fail(result.error) if result.error?

  # - output the result as simple string or JSON as requested
  if (opts.json)
    console.log(JSON.stringify(result, 0, 2))
  else
    console.log(result.version)

# helpers

debug= (msg, obj="")->
  if isDebug
    console.error(msg, obj) if console?.error?

fail= (msg)->
  console.error('ERROR! ' + msg) if console?.error?
  process.exit(1) if process?.exit?


# run it
do main
