# THIS WILL BE REMOVED, ADDED AS A TEMP CALL
{spawn} = require "child_process"

call = (cmd, args, done) ->
  exe = spawn cmd, args.join " "

  stdout = []
  stderr = []

  exe.stdout.on 'data',  (data) -> stdout.push data.toString()
  exe.stderr.on 'data', (data) -> stderr.push data.toString()
  kube.on 'close', (code) ->
    return done new Error stderr.join '' if stderr.length isnt 0
    return done null, stdout.join ''

module.exports = {call}