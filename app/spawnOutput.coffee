# THIS WILL BE REMOVED, ADDED AS A TEMP CALL
{spawn} = require "child_process"

DEFAULT_DATA_REPORTER = (data) -> console.log data.toString()
DEFAULT_ON_DATA =
  stdout: ->
  stderr: ->

REPORT_ALL_DATA =
  stdout: DEFAULT_DATA_REPORTER
  stderr: DEFAULT_DATA_REPORTER

call = (cmd, args, onData, done) ->
  [onData, done] = [DEFAULT_ON_DATA, onData] if typeof onData is "function"
  exe = spawn cmd, args
  stdout = []
  stderr = []
  exe.stdout.on 'data',  (data) ->
    onData.stdout data
    stdout.push data.toString()
  exe.stderr.on 'data', (data) ->
    onData.stderr data
    stderr.push data.toString()
  exe.on 'close', (code) ->
    return done new Error stderr.join '' if stderr.length isnt 0
    return done null, stdout.join ''

module.exports = {
  call
  REPORT_ALL_DATA
}