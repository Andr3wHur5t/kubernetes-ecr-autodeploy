_ = require "lodash"
async = require "async"
debug = require("debug") "autodeploy:deployAgent"
{
  parseDeployTarget
  getCurrentDeployedTagForTarget
  getAllRepoTags
  getBestTagForTarget
} = require "./deployTarget"

checkDeployTarget = ({kube, currentState}, target, done) ->
  deployTarget = parseDeployTarget(target)

  # Discover our best tag given our ECR tags and our Kube Replication controllers current tag
  # We don't want to downgrade the version of the
  currentKubeTag = getCurrentDeployedTagForTarget currentState, deployTarget
  allRepoTags = getAllRepoTags currentState, deployTarget
  bestTag = getBestTagForTarget deployTarget, _.flatten(allRepoTags, [currentKubeTag])
  return done null if bestTag is currentKubeTag
  debug "NEW TAG: '#{bestTag}' will be deployed for '#{target.friendlyName}'..."

  kube.rollingUpdate {
    namespace:
    rcName:
    imageURI: [getTargetRepo(currentState, deployTarget).repositoryUri, bestTag].join ":"
  }, (err, didExecute) ->
    return done err if err?
    return done null unless didExecute
    debug "Finished Deploying '#{bestTag}' to '#{target.friendlyName}'..."
    done null

deployCheck = ({kube, ecr}, currentState, done) ->
  done or= ->
  async.each(
    currentState.deploymentSpec.deployTargets,
    ((target, next) -> checkDeployTarget {kube, ecr, currentState} , target, next),
    (err) ->
      return done err if err?
      debug "Finished Checking deployments..."
      done null
  )


module.exports = { deployCheck }
