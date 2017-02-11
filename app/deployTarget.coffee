_ = require "lodash"

### Kube Target Helpers ###

parseDeployTarget = (target) ->
  localTarget = _.cloneDeep target
  localTarget.fromEcr.whereMatches = new RegExp target.fromEcr.whereMatches
  return localTarget

getTargetReplicationController = ({kubeStatus}, {toReplicationController}) ->
  _.find kubeStatus, { name: toReplicationController.rcName }

getTargetContainer = ({containers}, {toReplicationController}) ->
  _.find containers, { name: toReplicationController.targetContainer }

### ECR Target Helpers ###

getRepoTags = (repo) ->
  _.flatten _.map repo.tags, "imageTags"

getTargetRepo = ({ecrRepos}, {fromEcr}) ->
  _.find ecrRepos, { repositoryName: fromEcr.repositoryName }

getTagNumForTarget = ({fromEcr}, tag) ->
  parseInt tag.match(fromEcr.whereMatches)[1]

getAllRepoTags = ({ecrRepos}, target) ->
  return  getRepoTags getTargetRepo {ecrRepos}, target

### TAG DISCOVERY ###

getBestTagForTarget = ({fromEcr}, tags) ->
  allowedTags = _.uniq _.filter tags, (pt) -> fromEcr.whereMatches.test pt
  _.maxBy allowedTags, getTagNumForTarget.bind(null, {fromEcr})

getCurrentDeployedTagForTarget = ({kubeStatus}, target) ->
  targetRC = getTargetReplicationController({kubeStatus}, target)
  targetContainer = getTargetContainer targetRC, target
  return targetContainer.image.tag

module.exports = {
  parseDeployTarget
  getBestTagForTarget
  getCurrentDeployedTagForTarget

  getTargetReplicationController
  getTargetContainer
  getTargetRepo
  getRepoTags
  getAllRepoTags
}
