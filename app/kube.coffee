_ = require "lodash"
K8s = require "k8s"
async = require "async"
debug = require("debug")("autodeploy:kube")
{call} = require "./spawnOutput"
{
  KUBE_SERVICE_ACCOUNT_TOKEN_PATH
  KUBE_API_URI
} = require "../config"

parseImage = (imageURI) ->
  [repoURL, tag] = imageURI.split ":"
  {repoURL, tag, imageURI}

parseContainer = ({image, name}) -> {name, image: parseImage image}

parseReplicationController = ({metadata, spec} = {}) ->
  {
    name: metadata.name
    namespace: metadata.namespace
    containers: _.map spec.template.spec.containers, parseContainer
  }

class kube
  constructor: (opts) ->
    @_kube = K8s.api opts

  getRC: (namespace, done) ->
    @_kube.get "namespaces/#{namespace}/replicationcontrollers", (err, data) ->
      return done err if err?
      done null, _.map data.items, parseReplicationController

  getReplicationControllers: (namespaces, done) ->
    namespaces = [namespaces] if typeof namespaces is "string"
    async.map namespaces, @getRC.bind(@), (err, replicationControllers) ->
      return done err if err?
      return done null, _.flatten replicationControllers

  rollingUpdate: ({namespace, rcName, imageURI, updatePeriod= "5s"}, done) ->
    # TODO: Add mutex to prevent double deploy
    # TODO: Make this work using out kube lib
    call(
      "kubectl",
      [
        "rolling-update"
        rcName
        "--image='#{imageURI}'"
        "--update-period='#{updatePeriod}'"
        "--namespace='#{namespace}'"
        "--service-account-private-key-file='#{KUBE_SERVICE_ACCOUNT_TOKEN_PATH}'"
        "-s='#{KUBE_API_URI}'"
      ],
      (err, output) ->
        return done err, false if err?
        _.each output.split("/n"), debug
        return done null, true if err?
    )

module.exports = kube
