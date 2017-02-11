_ = require "lodash"
async = require "async"
aws = require "aws-sdk"
debug = require("debug") "autodeploy:main"
debugSync = require("debug") "autodeploy:sync"
config = require "./config"
ECR = require "./app/ecr"
Kube = require "./app/kube"
{ deployCheck } = require "./app/deploy"

syncRemoteState = ({ecr, kube}, done) ->
# TODO: Get remote state from S3
  deploymentSpec = require("./auto-deploy-spec.json")
  kubeNamespaces = _.map deploymentSpec.deployTargets, "toReplicationController.namespace"
  async.parallel {

    ecrRepos: (next) ->
      debugSync "Syncing ECR state..."
      ecr.getAllTags (err, data) ->
        debugSync "Synced ECR state!"
        next err, data

    kubeStatus: (next) ->
      debugSync "Syncing kube cluster state..."
      kube.getReplicationControllers kubeNamespaces, (err, data) ->
        debugSync "Synced kube cluster state!"
        next err, data

  }, (err, currentState) ->
    return done err if err?
    currentState.deploymentSpec = deploymentSpec
    done null, currentState

performUpdates = ({kube, ecr}, reportErr) ->
  syncRemoteState {kube, ecr}, (err, currentState) ->
    return reportErr if err?

    # Perform our deploy check and update
    deployCheck {kube, ecr}, currentState

    # NOTE: You can add other stuff here which uses the remote state

main = (done) ->
  debug "Authenticating with S3..."
  s3 = new aws.S3 { region: config.AWS_S3_REGION }

  debug "Authenticating with ECR..."
  ecr = new ECR { region: config.AWS_ERC_REGION }

  debug "Authenticating with Kube..."
  kube = new Kube {
    endpoint: config.KUBE_API_URI
    version: config.KUBE_API_VERSION
    strictSSL: config.KUBE_STRICT_SSL
    auth: { token: config.KUBE_AUTH_TOKEN }
  }

  debug "Starting clock..."
  setInterval ->
    debug "===== Tick: Performing updates ====="
    performUpdates {ecr, kube, s3}, console.error
  , config.PERIOD_TO_POLL_SECONDS * 1000

main (err) ->
  console.error err if err?
  process.exit if err? then -1 else 0