_ = require "lodash"
async = require "async"
debugSync = require("debug") "autodeploy:deployAgent"
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
  console.log "BEST === ", bestTag
  return done null if bestTag is currentKubeTag

  debugSync "NEW TAG: '#{bestTag}' will be deployed for '#{target.friendlyName}'..."
  # Our best Tag is not deployed do it.
  done()

  # TODO: Rollout New Image

deployCheck = ({kube, ecr}, currentState, done) ->
  done or= ->
  async.each(
    currentState.deploymentSpec.deployTargets,
    ((target, next) -> checkDeployTarget {kube, ecr, currentState} , target, next),
    (err) ->
      return done err if err?
      debugSync "Finished Checking deployments..."
      done null
  )


module.exports = { deployCheck }
