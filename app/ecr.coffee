_ = require "lodash"
async = require "async"
aws = require "aws-sdk"
eventEmitter = require "event-emitter"

MAX_AWS_PARALLEL = 15

# Will watch and report changes to ECR
class ECRWatcher extends eventEmitter
  constructor: (opts) ->
    @ecr = new aws.ECR opts

  getAllTags: (repoNames, done) ->
    [repoNames, done] = [undefined , repoNames] if typeof repoNames is "function"
    finish = @errorReporter done
    @ecr.describeRepositories {}, (err, { repositories } = {}) =>
      return finish err if err?
      async.mapLimit(
        repositories,
        MAX_AWS_PARALLEL,
        @getFullRepoInfo.bind(@),
        finish
      )

  getFullRepoInfo: ({ repositoryName, repositoryUri } = {}, done) ->
    return done new Error "Must provide repositoryName" unless typeof repositoryName is "string"
    @ecr.describeImages { repositoryName }, (err, { imageDetails } = {}) ->
      return done err if err
      done null, {
        repositoryName,
        repositoryUri,
        tags: _.map imageDetails, ({ imageTags, imagePushedAt } = {}) -> { imageTags, imagePushedAt }
      }

  errorReporter: (done) ->
    done or= ->
    return (err, data) ->
      console.error err if err?
      done err, data

module.exports = ECRWatcher
