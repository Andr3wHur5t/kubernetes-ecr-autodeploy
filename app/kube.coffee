_ = require "lodash"
K8s = require "k8s"
async = require "async"
debug = require("debug")("autodeploy:kube")
{call, REPORT_ALL_DATA} = require "./spawnOutput"

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
  constructor: (@opts, done) ->
    @_kube = K8s.api @opts
    # Configure kubectl so we can perform rolling updates
    call(
      "kubectl",
      [
        "config"
        "set-cluster"
        "default-cluster"
        "--server=#{@opts.endpoint}"
        "--certificate-authority=#{@opts.caPath}"
      ],
      done
    )

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
    debug "Rolling update of '#{rcName}' in '#{namespace}' using '#{imageURI}'"
    call(
      "kubectl",
      [
        "rolling-update"
        rcName
        "--image=#{imageURI}"
        "--update-period=#{updatePeriod}"
        "--namespace=#{namespace}"
        "--token='#{@opts.auth.token}'"
      ],
      REPORT_ALL_DATA,
      (err) -> return done err, (err?)
    )

module.exports = kube
