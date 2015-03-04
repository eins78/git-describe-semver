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
