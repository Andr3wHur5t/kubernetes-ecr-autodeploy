_ = require "lodash"
async = require "async"
debug = require("debug") "autodeploy:deployAgent"
{
  parseDeployTarget
  getCurrentDeployedTagForTarget
  getAllRepoTags
  getBestTagForTarget
  getTargetRepo
} = require "./deployTarget"


DEPLOYMENT_STATE =
  inProgress: "inProgress"
  finished: "finished"

# Global State Of Updates, We will move this to A central system to enable HA
deploymentState = {}

checkDeployTarget = ({kube, currentState}, target, done) ->
  deployTarget = parseDeployTarget(target)
  {toReplicationController} = deployTarget
  # Abort if already in progress
  return done null if deploymentState[toReplicationController.rcName] is DEPLOYMENT_STATE.inProgress

  # Discover our best tag given our ECR tags and our Kube Replication controllers current tag
  # We don't want to downgrade the version of the
  currentKubeTag = getCurrentDeployedTagForTarget currentState, deployTarget
  allRepoTags = getAllRepoTags currentState, deployTarget
  bestTag = getBestTagForTarget deployTarget, _.flatten(allRepoTags, [currentKubeTag])

  # Abort if we already have the best tag
  return done null if bestTag is currentKubeTag

  # Mark as deployment in progress
  debug "NEW TAG: '#{bestTag}' will be deployed for '#{target.friendlyName}'..."
  deploymentState[toReplicationController.rcName] = DEPLOYMENT_STATE.inProgress

  kube.rollingUpdate {
    namespace: toReplicationController.namespace
    rcName: toReplicationController.rcName
    imageURI: [getTargetRepo(currentState, deployTarget).repositoryUri, bestTag].join ":"
  }, (err, didExecute) ->
    # If we exited dirty reset the state so we can try again
    deploymentState[toReplicationController.rcName] = DEPLOYMENT_STATE.finished
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
