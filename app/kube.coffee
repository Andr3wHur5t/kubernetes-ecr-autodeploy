_ = require "lodash"
K8s = require "k8s"
async = require "async"

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

module.exports = kube
